//
//  TRNAppDelegate.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

import Cocoa
@UIApplicationMain
class TRNAppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: TRNWindowController!
    var deferredMagnetURL: URL!
    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.setupDefaults()
        self.mainWindowController = TRNWindowController(windowNibName: "TRNWindowController")
        self.window! = self.mainWindowController.window!
    }

    func applicationWillFinishLaunching(_ aNotification: Notification) {
        var appleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(self, andSelector: Selector("handleGetURLEvent:withReplyEvent:"), for: kInternetEventClass, andEventID: kAEGetURL)
    }

    func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        var url = URL(string: event.paramDescriptor(forKeyword: keyDirectObject).stringValue)!
        if self.mainWindowController.server {
            self.mainWindowController.server.addMagnetLink(url)
        }
        else {
            self.deferredMagnetURL = url
        }
    }

    func setupDefaults() {
        // Load default defaults
        UserDefaults.standard.register(defaults: [AnyHashable: Any](contentsOfFile: Bundle.main.path(forResource: "Defaults", ofType: "plist")!))
    }

}
