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
        default:
            break
        }
    }
}

//    var server: TRNServer!
//    @IBOutlet weak var arrayController: NSArrayController!
//    @IBOutlet weak var serverToolbarButton: NSButton!
//    @IBOutlet weak var statusBlip: NSImageView!
//    @IBOutlet weak var settingsPopover: NSPopover!
//    @IBOutlet weak var popoverViewController: NSViewController!
//    @IBOutlet weak var deleteConfirmPopover: NSPopover!
//    @IBOutlet weak var deleteConfirmPopoverViewController: NSViewController!
//    @IBOutlet weak var collectionView: NSCollectionView!
//    @IBOutlet weak var removeTorrentButton: NSButton!
//    @IBOutlet weak var deleteMessageField: NSTextField!
//    @IBOutlet weak var versionButton: NSButton!
//    @IBOutlet weak var passiveAlertBox: NSBox!
//    @IBOutlet weak var passiveAlertMessageField: NSTextField!
//    @IBOutlet weak var passiveAlertImageView: NSImageView!
//

//
//    @IBAction func confirmDeleteSelectedTorrents(_ sender: Any) {
//        delete = true
//        var selectedTorrents = self.arrayController.selectedObjects()
//        if selectedTorrents.count == 0 {
//            return
//        }
//        if selectedTorrents.count == 1 {
//            var theTorrent = selectedTorrents[0]
//            self.deleteMessageField.stringValue = "Are you sure you want to permanently delete \"\(theTorrent.bestName)\" from the server?"
//        }
//        else {
//            self.deleteMessageField.stringValue = "Are you sure you want to permanently delete the selected torrents from the server?"
//        }
//        var toolbarItemView = (sender as! NSButton)
//        self.deleteConfirmPopover.show(relativeTo: toolbarItemView.bounds, of: toolbarItemView, preferredEdge: NSMaxYEdge)
//    }
//
//    @IBAction func confirmRemoveSelectedTorrents(_ sender: Any) {
//        delete = false
//        var selectedTorrents = self.arrayController.selectedObjects()
//        if selectedTorrents.count == 0 {
//            return
//        }
//        if selectedTorrents.count == 1 {
//            var theTorrent = selectedTorrents[0]
//            self.deleteMessageField.stringValue = "Are you sure you want to remove \"\(theTorrent.bestName)\" from the server? The file will not be deleted but it will stop downloading or seeding."
//        }
//        else {
//            self.deleteMessageField.stringValue = "Are you sure you want to remove the selected torrents from the server? The files will not be deleted but they will stop downloading or seeding."
//        }
//        delete = false
//        var toolbarItemView = (sender as! NSButton)
//        self.deleteConfirmPopover.show(relativeTo: toolbarItemView.bounds, of: toolbarItemView, preferredEdge: NSMaxYEdge)
//    }
//
//    @IBAction func confirmedRemoveOrDelete(_ sender: Any) {
//        var selectedTorrents = self.arrayController.selectedObjects()
//        self.server.removeTorrents(selectedTorrents, deleteData: delete)
//        delete = false
//        self.deleteConfirmPopover.close()
//    }
//
//    @IBAction func check(forUpdatesButtonPressed sender: Any) {
//        // trigger the updater
//        SUUpdater.shared().check(forUpdates: nil)
//    }
//
//    static let serverContext = "serverContext"
//    static let arrayControllerContext = "arrayControllerContext"
//
//    override init(window: NSWindow?) {
//        super.init(window: window)
//        
//        self.server = TRNServer.init()
//    
//    }
//
//    override func awakeFromNib() {
//        SORelativeDateTransformer.registered()
//        var sortDescriptor = NSSortDescriptor(key: "percentDone", ascending: true)
//        arrayController.sortDescriptors = [sortDescriptor]
//    }
//
//    override func windowDidLoad() {
//        super.windowDidLoad()
//        self.sortOutVersionMessage()
//            // Extract the standard delete toolbar icon
//        var filetype = UTGetOSTypeFromString(("tdel" as! CFString))
//        self.removeTorrentButton.image = NSWorkspace.shared().icon(forFileType: NSFileTypeForHFSTypeCode(filetype))
//        self.collectionView!.backgroundColors = [NSColor.clear]
//        self.server.addObserver(self, forKeyPath: "connected", options: (.initial || .new), context: serverContext)
//        if !self.server.address {
//            self.serverSettingsPopover(nil)
//        }
//        self.arrayController.addObserver(self, forKeyPath: "arrangedObjects", options: (.initial || .new), context: arrayControllerContext)
//        // updater notifications
//        NotificationCenter.default.addObserver(self, selector: #selector(self.updatesFound), name: SUUpdaterDidFindValidUpdateNotification, object: nil)
//        SUUpdater.shared().checkForUpdateInformation()
//    }
//// MARK: - Versioning and updates
//
//    func sortOutVersionMessage() {
//        var versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
//        if pendingUpdateItem {
//            self.versionButton.title = "Update available: v\(pendingUpdateItem.versionString)"
//            self.versionButton.cell.backgroundColor = NSColor(deviceRed: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
//        }
//        else {
//            self.versionButton.title = "Transmote v\(versionString)"
//        }
//    }
//
//    func updatesFound(_ notification: Notification) {
//        pendingUpdateItem = (notification.userInfo!.value(forKey: SUUpdaterAppcastItemNotificationKey) as! String)
//        self.sortOutVersionMessage()
//    }
//// MARK: - Server Settings
//

//
//    func sortOutPassiveAlert() {
//        if !self.server.connected {
//            self.passiveAlertBox.isHidden = false
//            self.passiveAlertImageView.image = UIImage(named: "NSCaution")!
//            self.passiveAlertMessageField.stringValue = "Disconnected"
//            return
//        }
//        if !(self.arrayController.arrangedObjects as! [Any]).count {
//            self.passiveAlertBox.isHidden = false
//            self.passiveAlertImageView.image = UIImage(named: "Magnet")!
//            self.passiveAlertMessageField.stringValue = "Click a magnet link in a browser to add a torrent"
//            return
//        }
//        self.passiveAlertBox.isHidden = true
//    }
//    var delete = false
//    var pendingUpdateItem: SUAppcastItem!
//
//}
