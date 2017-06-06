//
//  PreferencesViewController.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2017-05-12.
//

import Cocoa

class PreferencesViewController: NSViewController {
    @IBOutlet weak var themePopup: NSPopUpButton! {
        didSet {
            let theme = Preferences.shared.theme
            
            themePopup.menu?.removeAllItems()
            
            guard let themesFolderURL = Bundle.main.url(forResource: Preferences.Theme.folderName, withExtension: nil) else {
                return
            }
            
            guard let themeURLs = try? FileManager.default.contentsOfDirectory(at: themesFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
                return
            }
            
            for themeURL in themeURLs {
                themePopup.addItem(withTitle: themeURL.deletingPathExtension().lastPathComponent)
            }
            
            themePopup.selectItem(withTitle: theme)
        }
    }
    
    @IBOutlet weak var styleWebPageRadio: NSButton! {
        didSet {
            styleWebPageRadio.state = Preferences.shared.style == .web ? NSOnState : NSOffState
        }
    }
    
    @IBOutlet weak var styleSlideshowRadio: NSButton! {
        didSet {
            styleSlideshowRadio.state = Preferences.shared.style == .slideshow ? NSOnState : NSOffState
        }
    }
    @IBOutlet weak var formatHTMLCheck: NSButton! {
        didSet {
            formatHTMLCheck.state = Preferences.shared.formatHTML ? NSOnState : NSOffState
        }
    }
    
    @IBOutlet weak var formatJSONCheck: NSButton! {
        didSet {
            formatJSONCheck.state = Preferences.shared.formatJSON ? NSOnState : NSOffState
        }
    }
    
    @IBOutlet weak var responsiveImagesCheck: NSButton! {
        didSet {
            responsiveImagesCheck.state = Preferences.shared.responsiveImages ? NSOnState : NSOffState
        }
    }
    
    @IBOutlet weak var existsPopup: NSPopUpButton! {
        didSet {
            let exists = Preferences.shared.exists
            
            existsPopup.selectItem(withTag: exists.rawValue)
        }
    }
    
    @IBAction func themeChosen(_ sender: NSPopUpButton) {
        Preferences.shared.theme = sender.titleOfSelectedItem ?? Preferences.Defaults.theme
    }
    
    @IBAction func styleChosen(_ sender: NSButton) {
        Preferences.shared.style = sender == styleWebPageRadio ? .web : .slideshow
    }
    
    @IBAction func formatHTMLChosen(_ sender: NSButton) {
        Preferences.shared.formatHTML = sender.state == NSOnState
    }
    
    @IBAction func formatJSONChosen(_ sender: NSButton) {
        Preferences.shared.formatJSON = sender.state == NSOnState
    }
    
    @IBAction func responsiveImagesChosen(_ sender: NSButton) {
        Preferences.shared.responsiveImages = sender.state == NSOnState
    }
    
    @IBAction func existsChosen(_ sender: NSButton) {
        Preferences.shared.exists = Preferences.Exists(rawValue: sender.selectedTag()) ?? .ask
    }
}
