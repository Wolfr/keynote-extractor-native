//
//  Preferences.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2017-05-12.
//  Copyright © 2017 Mono Company BVBA. All rights reserved.
//

import Cocoa

/// A wrapper for the user defaults.
class Preferences {
    /// Singleton shared instance.
    static let shared = Preferences()
    
    /// Private init to prevent others constructing a new instance.
    private init() {
        UserDefaults.standard.register(defaults: [Key.html : true])
    }
    
    /// Keys for the user defaults.
    private struct Key {
        static let theme = "theme"
        static let style = "style"
        static let html = "html"
        static let json = "json"
        static let responsive = "responsive"
        static let exists = "exists"
    }
    
    struct Theme {
        static let folderName = "Themes"
    }
    
    struct Defaults {
        static let theme = "White"
    }
    
    /// The output style.
    enum Style: String {
        static let folderName = "Styles"
        
        case web = "web"
        case slideshow = "slideshow"
    }
    
    /// The theme name (corresponds to CSS files in the app bundle).
    var theme: String {
        get {
            return UserDefaults.standard.object(forKey: Key.theme) as? String ?? Defaults.theme
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.theme)
        }
    }
    
    /// Returns the theme name reformatted for output, with lowercased characters, spaces replaced with dashes, and the file extension.
    var themeOutputName: String {
        return theme.lowercased().replacingOccurrences(of: " ", with: "-") + ".css"
    }
    
    /// The output style.
    var style: Style {
        get {
            return Style(rawValue: UserDefaults.standard.object(forKey: Key.style) as? String ?? Style.web.rawValue) ?? .web
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Key.style)
        }
    }
    
    /// Filename of the style HTML template.
    var styleFilename: String {
        return style.rawValue
    }
    
    /// Whether or not to output HTML.
    var formatHTML: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.html)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.html)
        }
    }
    
    /// Whether or not to output JSON.
    var formatJSON: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.json)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.json)
        }
    }
    
    /// Whether or not to output responsive images.
    var responsiveImages: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key.responsive)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key.responsive)
        }
    }
    
    /// How to handle an existing output folder.
    enum Exists: Int {
        case ask = 0
        case keepBoth = 1
        case replace = 2
    }
    
    /// How to handle an existing output folder.
    var exists: Exists {
        get {
            return Exists(rawValue: UserDefaults.standard.object(forKey: Key.exists) as? Int ?? Exists.ask.rawValue) ?? .ask
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Key.exists)
        }
    }
}
