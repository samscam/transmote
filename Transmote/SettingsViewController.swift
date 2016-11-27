//
//  SettingsViewController.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 22/11/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Foundation
import Cocoa

class SettingsViewController: NSViewController {
    
    var server: TransmissionServer?
    
    @IBOutlet weak var statusBlobImageView: NSImageView!
    
    @IBOutlet weak var serverAddressField: NSTextField!
    @IBOutlet weak var portField: NSTextField!
    @IBOutlet weak var rpcPathField: NSTextField!
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }

    //    override func observeValue(forKeyPath keyPath: String, ofObject object: Any, change: [AnyHashable: Any], context: UnsafeMutableRawPointer) {
    //        if context == serverContext {
    //            if (keyPath == "connected") {
    //                if self.server.connected {
    //                    self.statusBlip.image = UIImage(named: "NSStatusAvailable")!
    //                    self.collectionView!.isHidden = false
    //                }
    //                else {
    //                    self.statusBlip.image = UIImage(named: "NSStatusUnavailable")!
    //                    self.collectionView!.isHidden = true
    //                }
    //                self.sortOutPassiveAlert()
    //            }
    //            return
    //        }
    //        if context == arrayControllerContext {
    //            self.sortOutPassiveAlert()
    //            return
    //        }
    //        super.observeValue(forKeyPath: keyPath, ofObject: object, change: change, context: context)
    //    }
}
