//
//  AppDelegate.swift
//  KeynoteExtractor
//
//  Created by David Sinclair on 2016-10-20.
//  Copyright © 2016 Mono Company BVBA. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        if let viewController: DropViewController = sender.mainWindow?.contentViewController as! DropViewController? {
            viewController.dropped(url: URL(fileURLWithPath: filename, isDirectory: false))
            
            return true
        }
        
        return false
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

