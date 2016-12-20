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
    weak var mainViewController: MainViewController!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        //poke the session
        mainViewController = self.contentViewController! as! MainViewController
        mainViewController.session = session
        
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "SettingsSegue":
            if let settingsViewController = segue.destinationController as? SettingsViewController {
                settingsViewController.session = self.session
            }
        case "DeleteSegue":
            
            if let confirmationViewController = segue.destinationController as? ConfirmationViewController{
                confirmationViewController.message = "Do you really want to DELETE this torrent and any downloaded files?"
                confirmationViewController.action = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.session.removeTorrents(torrents: strongSelf.mainViewController.selectedTorrents, delete: true)
                    }
                }
            }
        case "RemoveSegue":
            if let confirmationViewController = segue.destinationController as? ConfirmationViewController{
                confirmationViewController.message = "This will remove the torrent from the list, leaving files intact."
                confirmationViewController.action = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.session.removeTorrents(torrents: strongSelf.mainViewController.selectedTorrents, delete: false)
                    }
                }
            }
        default:
            break
        }
    }
}
