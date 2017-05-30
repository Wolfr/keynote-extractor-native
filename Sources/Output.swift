//
//  Output.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-28.
//

import Foundation

enum OutputError: Error {
    case missingTemplate
    case invalidTemplate
    case insufficientImages
    case missingResource
    case missingTheme
}

struct Output {
    
    let imagesURL: URL
    let notes: [String]
    var html: String?
    var json: String?
    
    /// Initializer.
    ///
    /// - Parameter imagesURL: URL of the temporary images folder.
    /// - Parameter notes: Array of notes as HTML.
    init(images imagesURL: URL, notes: [String]) {
        self.imagesURL = imagesURL
        self.notes = notes
    }
    
    /// Prepares the HTML and/or JSON to output from the images and notes.
    ///
    /// - Parameter title: The title of the presentation.
    /// - Throws: `OutputError.missingTemplate` if the style template couldn't be located, `OutputError.invalidTemplate` if the style template isn't valid, or a Cocoa error if the images folder can't be read, or JSON serialization fails.
    mutating func generate(title: String) throws {
        let allImageNames = try FileManager.default.contentsOfDirectory(atPath: imagesURL.path)
        
        let imageNames = allImageNames.filter { return !$0.contains("-sm") && !$0.contains("-md") && !$0.contains("-lg") }
        
        if Preferences.shared.formatHTML {
            guard let templateURL = Bundle.main.url(forResource: Preferences.shared.styleFilename, withExtension: "html", subdirectory: Preferences.Style.folderName)
                else {
                    throw OutputError.missingTemplate
            }
            
            var template = try NSString(contentsOf: templateURL, encoding: String.Encoding.utf8.rawValue) as String
            
            template = template.replacingOccurrences(of: "{{title}}", with: title)
            template = template.replacingOccurrences(of: "{{theme}}", with: Preferences.shared.themeOutputName)
            
            guard let start = template.range(of: "{{slide}}"), let end = template.range(of: "{{/slide}}") else {
                throw OutputError.invalidTemplate
            }
            
            let templatePrefix = template.substring(to: start.lowerBound)
            let templateSlide = template.substring(with: Range(uncheckedBounds: (lower: start.upperBound, upper: end.lowerBound)))
            let templateSuffix = template.substring(from: end.upperBound)
            
            var html = templatePrefix
            
            for (index, note) in notes.enumerated() {
                guard index < imageNames.count else {
                    throw OutputError.insufficientImages
                }
                
                var image = "images/\(imageNames[index])"
                
                if Preferences.shared.responsiveImages {
                    let names = responsive(baseName: image)
                    
                    image = "\(image)\" srcset=\"\(names.large) 984w, \(names.medium) 728w, \(names.small) 375w\" sizes=\"100vw"
                }
                
                image += "\" alt=\"Image of slide number \(index + 1)"
                
                var slide = templateSlide.replacingOccurrences(of: "{{image}}", with: image)
                slide = slide.replacingOccurrences(of: "{{notes}}", with: note)
                
                html += slide
            }
            
            html += templateSuffix
            
            self.html = html
        }
        
        if Preferences.shared.formatJSON {
            typealias JSONDictionary = [String:Any]
            var array = [JSONDictionary]()
            
            for (index, note) in notes.enumerated() {
                let image = "images/\(imageNames[index])"
                
                if Preferences.shared.responsiveImages {
                    let names = responsive(baseName: image)
                    let subdict: JSONDictionary = ["lg" : names.large, "md" : names.medium, "sm" : names.small]
                    let dict: JSONDictionary = ["image" : image, "images" : subdict, "notes" : note]
                    
                    array.append(dict)
                } else {
                    let dict = ["image" : image, "notes" : note]
                    
                    array.append(dict)
                }
            }
            
            let data = try JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
            
            self.json = String(data: data, encoding: String.Encoding.utf8)
        }
    }
    
    private func responsive(baseName: String) -> (small: String, medium: String, large: String) {
        let temp = NSString(string: baseName)
        let filename = temp.deletingPathExtension
        let fileExtension = temp.pathExtension
        
        return (small: "\(filename)-sm.\(fileExtension)", medium: "\(filename)-md.\(fileExtension)", large: "\(filename)-lg.\(fileExtension)")
    }
    
    /// Copies the source file to the destination.
    ///
    /// - Parameter sourceURL: A URL of a file to copy.
    /// - Parameter destinationURL: A URL of where to save the output.
    /// - Throws: `OutputError.missingResource` if the source couldn't be located, or a Cocoa error if it couldn't be written out.
    func copy(url sourceURL: URL?, to destinationURL: URL, named destinationName: String? = nil) throws {
        guard let sourceURL = sourceURL
            else {
                throw OutputError.missingResource
        }
        
        let finalDestinationURL = destinationURL.appendingPathComponent(destinationName ?? sourceURL.lastPathComponent)
        
        try FileManager.default.copyItem(at: sourceURL, to: finalDestinationURL)
    }
    
    /// Saves the HTML, CSS and images to the destination URL.
    ///
    /// - Parameter destinationURL: A URL of where to save the output.
    /// - Throws: `OutputError.missingResource` if the CSS couldn't be located, `OutputError.missingTheme` if a theme CSS couldn't be located, or a Cocoa error if anything couldn't be written out.
    func write(to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        // Remove any existing folder
        try? fileManager.removeItem(at: destinationURL)
        
        // Create the output folder
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        
        // Move the images folder into the output folder
        let imagesDestinationURL = destinationURL.appendingPathComponent("images")
        try fileManager.moveItem(at: imagesURL, to: imagesDestinationURL)
        
        // Write out the HTML, if required
        if let html = html {
            // Copy the base CSS into the output folder
            try copy(url: Bundle.main.url(forResource: "base", withExtension: "css", subdirectory: Preferences.Style.folderName), to: destinationURL)
            
            // Copy the style CSS into the output folder
            try copy(url: Bundle.main.url(forResource: Preferences.shared.styleFilename, withExtension: "css", subdirectory: Preferences.Style.folderName), to: destinationURL)
            
            // Copy the theme CSS into the output folder
            try copy(url: Bundle.main.url(forResource: Preferences.shared.theme, withExtension: "css", subdirectory: Preferences.Theme.folderName), to: destinationURL, named: Preferences.shared.themeOutputName)
            
            if Preferences.shared.style == .slideshow {
                // Copy the slideshow Javascript into the output folder
                try copy(url: Bundle.main.url(forResource: Preferences.shared.styleFilename, withExtension: "js", subdirectory: Preferences.Style.folderName), to: destinationURL)
            }
            
            let htmlURL = destinationURL.appendingPathComponent("index").appendingPathExtension("html")
            try html.write(to: htmlURL, atomically: false, encoding: .utf8)
        }
        
        // Write out the JSON, if required
        if let json = json {
            let jsonURL = destinationURL.appendingPathComponent("index").appendingPathExtension("json")
            try json.write(to: jsonURL, atomically: false, encoding: .utf8)
        }
    }
}

