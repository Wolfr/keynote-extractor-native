//
//  Unzip.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-26.
//  Copyright © 2016 Mono Company BVBA. All rights reserved.
//

import Foundation

enum UnzipError: Error {
    case failed
}

/// Decompresses a zip archive.
///
/// - Parameter sourceURL: URL of the zip file.
/// - Parameter destinationURL: URL of the decompressed folder.
/// - Throws: `UnzipError.failed` if the archive couldn't be decompressed.
func unzip(at sourceURL: URL, to destinationURL: URL) throws {
    let process = Process.launchedProcess(launchPath: "/usr/bin/unzip", arguments: ["-o", sourceURL.path, "-d", destinationURL.path])
    
    process.waitUntilExit()
    
    guard process.terminationReason == .exit else {
        throw UnzipError.failed
    }
}

