//
//  Output.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-28.
//  Copyright © 2016 Mono Company BVBA. All rights reserved.
//

import Foundation

enum OutputError: Error {
    case missingCSS
}

struct Output {
    
    let imagesURL: URL
    let notes: [String]
    let html: String
    
    /// Initializer.  Prepares the HTML to output from the images and notes.
    ///
    /// - Parameter imagesURL: URL of the temporary images folder.
    /// - Parameter notes: Array of notes as HTML.
    /// - Throws: A Cocoa error if the images folder can't be read.
    init(images imagesURL: URL, notes: [String]) throws {
        self.imagesURL = imagesURL
        self.notes = notes
        
        let imageNames = try FileManager.default.contentsOfDirectory(atPath: imagesURL.path)
        
        var html = "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"UTF-8\">\n"
        html += "  <link rel=\"stylesheet\" href=\"slides.css\">\n"
        html += "  <meta name=\"viewport\" content=\"width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0\">\n"
        html += "</head>\n\n<body>\n"
        
        for (index, note) in notes.enumerated() {
            html += "  <article class=\"slide\">\n"
            html += "    <img class=\"slide-image\" src=\"images/\(imageNames[index])\" />\n"
            html += "    <div class=\"slide-annotations\">\n\n\(note)    </div>\n"
            html += "  </article>\n"
        }
        
        html += "</body>\n</html>\n\n"
        
        self.html = html
    }
    
    /// Saves the HTML, CSS and images to the destination URL.
    ///
    /// - Parameter destinationURL: A URL of where to save the output.
    /// - Throws: `OutputError.missingCSS` if the CSS couldn't be located, or a Cocoa error if anything couldn't be written out.
    func write(to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        // Remove any existing folder
        try? fileManager.removeItem(at: destinationURL)
        
        // Create the output folder
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        
        // Move the images folder into the output folder
        let imagesDestinationURL = destinationURL.appendingPathComponent("images")
        try fileManager.moveItem(at: imagesURL, to: imagesDestinationURL)
        
        // Copy the CSS into the output folder
        guard let cssSourceURL = Bundle.main.url(forResource: "slides", withExtension: "css")
            else {
                throw OutputError.missingCSS
        }
        let cssDestinationURL = destinationURL.appendingPathComponent("slides.css")
        try fileManager.copyItem(at: cssSourceURL, to: cssDestinationURL)
        
        // Write out the HTML
        let htmlURL = destinationURL.appendingPathComponent("index").appendingPathExtension("html")
        try html.write(to: htmlURL, atomically: false, encoding: .utf8)
    }
}

