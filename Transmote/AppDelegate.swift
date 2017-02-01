//
//  AppDelegate.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 19/11/2016.
//

import Cocoa
import Fabric
import Crashlytics

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var deferredMagnetURL: URL!

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        Fabric.with([Crashlytics.self])

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
