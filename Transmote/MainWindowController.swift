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

class MainWindowController: NSWindowController, NSWindowDelegate, SettingsPopoverDelegate {

    var session: TransmissionSession = TransmissionSession()
    weak var mainViewController: MainViewController!

    var disposeBag = DisposeBag()

    @IBOutlet weak private var removeTorrentToolbarItem: NSToolbarItem!
    @IBOutlet weak private var deleteTorrentToolbarItem: NSToolbarItem!
    @IBOutlet weak private var viewControl: NSSegmentedControl!

    @IBAction func viewChange(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            self.mainViewController.viewStyle = .grid
        case 1:
            self.mainViewController.viewStyle = .list
        default:
            break
        }
    }

    var isShowingSettings = false

    override func windowDidLoad() {

        super.windowDidLoad()

        self.window?.delegate = self

        // Remember window positions

        self.shouldCascadeWindows = false
        let windowName = NSWindow.FrameAutosaveName("MainTransmoteWindow")
        if let window = self.window {
            if !window.setFrameUsingName(windowName) {
                window.center()
            }
            window.setFrameAutosaveName(windowName)
        }

        mainViewController = self.contentViewController! as! MainViewController // swiftlint:disable:this force_cast force_unwrapping

        // Inject the session into the main viewcontroller
        mainViewController.session = session

        // State for the toolbar buttons
        mainViewController.hasSelectedTorrents.subscribe(onNext: { hasSelectedTorrents in
            self.deleteTorrentToolbarItem.isEnabled = hasSelectedTorrents
            self.removeTorrentToolbarItem.isEnabled = hasSelectedTorrents
        }).addDisposableTo(disposeBag)

        self.viewControl.selectedSegment = mainViewController.viewStyle.rawValue

    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)

        // Automatically pop open settings if there is no server or similar session error
        session.status
            .asObservable()
            .subscribe(onNext: { status in
                switch status {
                case .failed(let sessionError):
                    switch sessionError {
                    case .noServerSet:
                            self.performSegue(withIdentifier: .settingsSegue, sender: self)
                    default:
                        break
                    }
                default:
                    break
                }
            }).addDisposableTo(disposeBag)
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {
        case .settingsSegue:
            if let settingsViewController = segue.destinationController as? SettingsViewController {
                settingsViewController.session = self.session
                settingsViewController.delegate = self
                self.isShowingSettings = true
            }
        case .deleteSegue:

            if let confirmationViewController = segue.destinationController as? ConfirmationViewController {
                confirmationViewController.message = "Do you really want to DELETE this torrent and any downloaded files?"
                confirmationViewController.action = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.session.removeTorrents(torrents: strongSelf.mainViewController.selectedTorrents, delete: true)
                    }
                }
            }
        case .removeSegue:
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

    // Prevent double-display of settings popover

    override func shouldPerformSegue(withIdentifier identifier: NSStoryboardSegue.Identifier, sender: Any?) -> Bool {
        switch identifier {
            case .settingsSegue:
                return !isShowingSettings
        default:
            return true
        }
    }

    func settingsDismissed(sender: SettingsViewController) {
        isShowingSettings = false
    }

    // Show settings on window foregrounding if there is no server

    func windowDidBecomeKey(_ notification: Notification) {
        if session.server == nil {
            self.performSegue(withIdentifier: .settingsSegue, sender: self)
        }
    }

    enum Segues: String {
        case settingsSegue
        case deleteSegue
        case removeSegue
    }

}

fileprivate extension NSStoryboardSegue.Identifier {
    static let settingsSegue: NSStoryboardSegue.Identifier = NSStoryboardSegue.Identifier("SettingsSegue")
    static let deleteSegue: NSStoryboardSegue.Identifier = NSStoryboardSegue.Identifier("DeleteSegue")
    static let removeSegue: NSStoryboardSegue.Identifier = NSStoryboardSegue.Identifier("RemoveSegue")
}
