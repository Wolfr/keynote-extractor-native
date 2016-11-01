//
//  AppleScript.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-24.
//  Copyright © 2016 Mono Company BVBA. All rights reserved.
//

import Cocoa
import Carbon

enum AppleScriptError: Error {
    case missingScript
    case invalidScript
    case executionFailed(String)
}

struct AppleScript {
    
    let filename: String
    let handler: String
    let parameters: [String]
    
    /// Initializer.
    ///
    /// - Parameter filename: Name of the script to run.
    /// - Parameter handler: Name of the handler within the script.
    /// - Parameter parameters: An array of parameters to pass to the handler.
    init(filename: String, handler: String, parameters: [String] = []) {
        self.filename = filename
        self.handler = handler
        self.parameters = parameters
    }
    
    /// Executes an AppleScript with a handler and parameters.
    ///
    /// - Throws: `AppleScriptError.missingScript` if there is no script, `.invalidScript` if it couldn't be loaded, or `executionFailed` if the script had an error while running.
    func execute() throws {
        var errors: NSDictionary?
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: "scpt")
            else {
                throw AppleScriptError.missingScript
        }
        
        guard let script = NSAppleScript(contentsOf: url, error: &errors)
            else {
                throw AppleScriptError.invalidScript
        }
        
        let routine = NSAppleEventDescriptor(string: handler)
        let params = NSAppleEventDescriptor.list()
        
        for (index, parameter) in parameters.enumerated() {
            let param = NSAppleEventDescriptor(string: parameter)
            params.insert(param, at: index + 1)
        }
        
        var psn = ProcessSerialNumber(highLongOfPSN: UInt32(0), lowLongOfPSN: UInt32(kCurrentProcess))
        let target = NSAppleEventDescriptor(descriptorType: DescType(typeProcessSerialNumber), bytes:&psn, length:MemoryLayout<ProcessSerialNumber>.size)
        let event = NSAppleEventDescriptor.appleEvent(withEventClass: AEEventClass(kASAppleScriptSuite), eventID: AEEventID(kASSubroutineEvent), targetDescriptor: target, returnID: AEReturnID(kAutoGenerateReturnID), transactionID: AETransactionID(kAnyTransactionID))
        event.setParam(routine, forKeyword: AEKeyword(keyASSubroutineName))
        event.setParam(params, forKeyword: AEKeyword(keyDirectObject))
        
        script.executeAppleEvent(event, error: &errors)
        
        if errors != nil {
            throw AppleScriptError.executionFailed(errors?[NSAppleScript.errorMessage] as! String)
        }
    }
}

