//
//  AppDelegate.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 19/11/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var deferredMagnetURL: URL!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let appleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(self, andSelector: #selector(AppDelegate.handleGetURLEvent(_:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass) , andEventID: AEEventID(kAEGetURL))
        
        self.setupDefaults()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
//        var url = URL(string: event.paramDescriptor(forKeyword: keyDirectObject).stringValue)!
//        if self.mainWindowController.server {
//            self.mainWindowController.server.addMagnetLink(url)
//        }
//        else {
//            self.deferredMagnetURL = url
//        }
    }
    
    func setupDefaults() {
        // Load default defaults
//        UserDefaults.standard.register(defaults: [AnyHashable: Any](contentsOfFile: Bundle.main.path(forResource: "Defaults", ofType: "plist")!))
    }
}

