//
//  Notes.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-27.
//  Copyright © 2016 Mono Company BVBA. All rights reserved.
//

import Foundation

enum SpanStyle: String {
    case bold = "15"
    case italic = "17"
}

class Notes: NSObject {
    
    var notes = [String]()
    
    fileprivate var parser: XMLParser
    fileprivate let paragraphStart = "      <p>"
    fileprivate let paragraphEnd = "</p>\n\n"
    fileprivate var currentNote: String
    fileprivate var isHidden = false
    fileprivate var inNotes = false
    fileprivate var inParagraph = false
    fileprivate var spanAttributes: [String : String]?
    fileprivate var linkAttributes: [String : String]?
    
    /// Initializer for the notes parser
    ///
    /// - Parameter url: The URL of the Keynote index.apxl file
    /// - Throws: A Cocoa error if the data couldn't be loaded.
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        parser = XMLParser(data: data)
        currentNote = paragraphStart
        
        super.init()
        
        parser.delegate = self
    }
    
    /// Parses the index.apxl file.
    ///
    /// - Throws: A Cocoa error if the XML couldn't be parsed.
    /// - Returns: An array of notes as HTML.
    func parse() throws -> [String] {
        if !parser.parse() {
            throw parser.parserError!
        }
        
        return notes
    }
}

extension Notes: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        switch elementName {
        case "key:slide":
            isHidden = attributeDict["key:hidden"] != nil
        case "key:notes":
            inNotes = !isHidden
            inParagraph = false
            spanAttributes = nil
            linkAttributes = nil
        case "sf:p":
            inParagraph = inNotes
        case "sf:span":
            spanAttributes = attributeDict
        case "sf:link":
            linkAttributes = attributeDict
        case "sf:br":
            if !currentNote.hasSuffix(paragraphStart) {
                currentNote += "\(paragraphEnd)\(paragraphStart)"
            }
        default:
            break
        }
        
        if inNotes && inParagraph {
            print("\(elementName) \(attributeDict)")
        }
   }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if (inNotes) {
            switch elementName {
            case "key:notes":
                inNotes = false
                
                if currentNote.hasSuffix(paragraphStart) {
                    let paraIndex = currentNote.index(currentNote.endIndex, offsetBy: -9)
                    currentNote.removeSubrange(paraIndex..<currentNote.endIndex)
                } else {
                    currentNote += paragraphEnd
                }
                
                print(currentNote)
                
                notes.append(currentNote)
                currentNote = paragraphStart
            case "sf:p":
                inParagraph = false
            case "sf:span":
                spanAttributes = nil
            case "sf:link":
                linkAttributes = nil
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if (inNotes && inParagraph) {
            if let linkAttributes = linkAttributes, let url = linkAttributes["href"] {
                currentNote += "<a href=\"\(url)\" target=\"_blank\">\(string)</a>"
            } else if let spanAttributes = spanAttributes, let styleString = spanAttributes["sf:style"] {
                if let style = SpanStyle(rawValue: styleString.replacingOccurrences(of: "sf:characterstyle-", with: "")) {
                    switch style {
                    case .bold:
                        currentNote += "<strong>\(string)</strong>"
                    case .italic:
                        currentNote += "<em>\(string)</em>"
                    }
                } else {
                    currentNote += string
                }
            } else {
                currentNote += string
            }
            
            print(string)
        }
    }
}

