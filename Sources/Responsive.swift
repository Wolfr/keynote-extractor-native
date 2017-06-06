//
//  Responsive.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2017-05-13.
//

import Foundation

enum ResponsiveError: Error {
    case failed
}

struct Responsive {
    
    let url: URL
    
    /// Initializer.
    ///
    /// - Parameter url: The URL of the images folder.
    init(url: URL) {
        self.url = url
    }
    
    /// Executes the shell script to resize the images.
    ///
    /// - Throws: `ResponsiveError.failed` if something didn't work.
    func execute() throws {
        guard let scriptURL = Bundle.main.url(forResource: "responsive-images", withExtension: "sh") else {
            throw ResponsiveError.failed
        }
        
        let process = Process.launchedProcess(launchPath: "/bin/bash", arguments: [scriptURL.path, url.path, Preferences.shared.responsiveImages ? "responsive" : "single"])
        
        process.waitUntilExit()
        
        guard process.terminationReason == .exit else {
            throw ResponsiveError.failed
        }
    }
}
