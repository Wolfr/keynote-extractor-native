//
//  Extractor.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-23.
//  Copyright © 2016 Mono Company BVBA. All rights reserved.
//

import Cocoa

struct Extractor {
    
    let sourceURL: URL
    let destinationURL: URL
    let progressHandler: (Double) -> Void
    let completionHandler: (Result<URL>) -> Void
    
    /// Extraction initializer.
    ///
    /// - Parameter sourceURL: The URL of the Keynote document.
    /// - Parameter destinationURL: The URL of the output folder.
    /// - Parameter progressHandler: A closure to invoke with the progress percentage.
    /// - Parameter completionHandler: A closure to invoke when successfully finished or an error occurs.
    init(sourceURL: URL, destinationURL: URL, progressHandler: @escaping (Double) -> Void, completionHandler: @escaping (Result<URL>) -> Void) {
        self.sourceURL = sourceURL
        self.destinationURL = destinationURL
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
    }
    
    /// Processes the extraction of the document, with closures for progress percentage and completion.
    func extract() {
        DispatchQueue.init(label: "com.com.mono.keynote-extractor.extractor").async {
            do {
                let fileManager = FileManager.default
                let numberOfSteps: Double = 11
                var currentStep: Double = 0
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                
                let temporaryItemsURL = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: self.sourceURL, create: true)
                let temporaryURL = temporaryItemsURL.appendingPathComponent(UUID().uuidString)
                let imagesURL = temporaryURL.appendingPathComponent("images", isDirectory: true)
                let keynote09URL = temporaryURL.appendingPathComponent("keynote09.key", isDirectory: true)
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                try fileManager.createDirectory(at: imagesURL, withIntermediateDirectories: true, attributes: nil)
                try fileManager.createDirectory(at: keynote09URL, withIntermediateDirectories: true, attributes: nil)
                
                defer {
                    try? fileManager.removeItem(at: temporaryURL)
                }
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                try AppleScript(filename: "OpenDocument", handler: "OpenDocument", parameters: [self.sourceURL.path]).execute()
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                try AppleScript(filename: "ExportImages", handler: "ExportImages", parameters: [imagesURL.path]).execute()
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                try AppleScript(filename: "ExportKeynote09", handler: "ExportKeynote09", parameters: [keynote09URL.path]).execute()
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                try AppleScript(filename: "CloseDocument", handler: "CloseDocument", parameters: []).execute()
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                let zipURL = temporaryURL.appendingPathComponent("keynote09.zip", isDirectory: false)
                let unzipURL = temporaryURL.appendingPathComponent("keynote09", isDirectory: true)
                
                try fileManager.moveItem(at: keynote09URL, to: zipURL)
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                try unzip(at: zipURL, to: unzipURL)
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                let apxlURL = unzipURL.appendingPathComponent("index.apxl", isDirectory: false)
                
                let notes = try Notes(url: apxlURL).parse()
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                let output = try Output(images: imagesURL, notes: notes)
                try output.write(to: self.destinationURL)
                
                currentStep = self.report(step: currentStep, of: numberOfSteps)
                self.report(result: .success(self.destinationURL))
            }
            
            catch {
                try? FileManager.default.removeItem(at: self.destinationURL)
                self.report(result: .failure(error))
            }
        }
    }
    
    /// Invokes the progress handler on the main queue.
    ///
    /// - Parameter previousStep: The existing progress step value.
    /// - Parameter numberOfSteps: The total number of steps being performed.
    /// - Returns: The new step value.
    private func report(step previousStep: Double, of numberOfSteps: Double) -> Double {
        let nextStep = previousStep + 1
        let percentage = nextStep / numberOfSteps
        
        DispatchQueue.main.async {
            self.progressHandler(percentage)
        }
        
        return nextStep
    }
    
    /// Invokes the completion handler on the main queue.
    ///
    /// - Parameter result: The success or failure result.
    private func report(result: Result<URL>) {
        DispatchQueue.main.async {
            self.completionHandler(result)
        }
    }
}

