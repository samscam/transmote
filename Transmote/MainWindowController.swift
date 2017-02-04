//
//  MainWindowController.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//

import Cocoa
import Sparkle
import RxSwift
import RxCocoa

class MainWindowController: NSWindowController {

    var session: TransmissionSession = TransmissionSession()
    weak var mainViewController: MainViewController!

    var disposeBag = DisposeBag()

    @IBOutlet weak private var removeTorrentToolbarItem: NSToolbarItem!
    @IBOutlet weak private var deleteTorrentToolbarItem: NSToolbarItem!

    override func windowDidLoad() {
        super.windowDidLoad()

        // Remember window positions

        self.shouldCascadeWindows = false

        if let window = self.window {
            if !window.setFrameUsingName("MainTransmoteWindow") {
                window.center()
            }
            window.setFrameAutosaveName("MainTransmoteWindow")
        }

        mainViewController = self.contentViewController! as! MainViewController // swiftlint:disable:this force_cast force_unwrapping

        // Inject the session into the main viewcontroller
        mainViewController.session = session

        // State for the toolbar buttons
        mainViewController.hasSelectedTorrents.subscribe(onNext: { hasSelectedTorrents in
            self.deleteTorrentToolbarItem.isEnabled = hasSelectedTorrents
            self.removeTorrentToolbarItem.isEnabled = hasSelectedTorrents
        }).addDisposableTo(disposeBag)

    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {
        case "SettingsSegue":
            if let settingsViewController = segue.destinationController as? SettingsViewController {
                settingsViewController.session = self.session
            }
        case "DeleteSegue":

            if let confirmationViewController = segue.destinationController as? ConfirmationViewController {
                confirmationViewController.message = "Do you really want to DELETE this torrent and any downloaded files?"
                confirmationViewController.action = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.session.removeTorrents(torrents: strongSelf.mainViewController.selectedTorrents, delete: true)
                    }
                }
            }
        case "RemoveSegue":
            if let confirmationViewController = segue.destinationController as? ConfirmationViewController {
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
