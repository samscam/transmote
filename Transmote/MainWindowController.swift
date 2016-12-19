//
//  MainWindowController.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

import Cocoa
import Sparkle

class MainWindowController: NSWindowController {
    
    var session: TransmissionSession = TransmissionSession()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        //poke the session
        
        (self.contentViewController as! MainViewController).session = session
        
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "SettingsSegue":
            if let settingsViewController = segue.destinationController as? SettingsViewController {
                settingsViewController.session = self.session
            }
        case "DeleteSegue":
            if let confirmationViewController = segue.destinationController as? ConfirmationViewController{
                confirmationViewController.session = self.session
            }
        case "RemoveSegue":
            if let confirmationViewController = segue.destinationController as? ConfirmationViewController{
                confirmationViewController.session = self.session
            }
        default:
            break
        }
    }
}
