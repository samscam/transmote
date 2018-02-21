//
//  ViewController.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 19/11/2016.
//

import AppKit
import RxSwift
import RxCocoa
import Moya
import Sparkle
import QuartzCore

class MainViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, SUUpdaterDelegate {

    var session: TransmissionSession? {
        didSet {
            bindToSession()
        }
    }

    var disposeBag: DisposeBag = DisposeBag()

    @IBOutlet weak private var collectionView: NSCollectionView!
    @IBOutlet weak private var collectionViewContainer: NSScrollView!

    @IBOutlet weak private var passiveAlertContainer: NSBox!
    @IBOutlet weak private var passiveAlertLabel: NSTextField!
    @IBOutlet weak private var passiveAlertImageView: NSImageView!

    @IBOutlet weak private var versionWidget: NSButton!

    // swiftlint:disable force_cast
    let shortVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    let longVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    // swiftlint:enable force_cast

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let savedStyle = UserDefaults.standard.integer(forKey: "viewStyle")
        if let viewStyle = ViewStyle(rawValue: savedStyle) {
            self.viewStyle = viewStyle
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell
        let nib = NSNib(nibNamed: NSNib.Name("TorrentCollectionViewItem"), bundle: nil)

        self.collectionView.register(nib, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TorrentCell"))

        // We should persist the view style

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.collectionView.collectionViewLayout = self.viewStyle.layout

        sortOutVersionWidget()
        startUpdater()
        bindToSession()

    }

    func bindToSession() {

        guard let session = session else {
            return
        }

        guard self.isViewLoaded else {
            return
        }
        disposeBag = DisposeBag()

        // Observe the session status

        Observable
            .combineLatest(session.status, session.torrents.asObservable()) {
                return ($0, $1)
            }
            .debounce(0.2, scheduler: MainScheduler.instance)
            .subscribe({ event in
                switch event {
                case .next(let status, let torrents):
                switch status {
                case .connected:
                    if torrents.isEmpty {
                        self.passiveAlertContainer.isHidden = false
                        self.passiveAlertImageView.image = #imageLiteral(resourceName: "magnet")
                        self.collectionViewContainer.isHidden = true
                        self.passiveAlertLabel.stringValue = "Open a magnet link from a browser to add a torrent"
                    } else {
                        self.passiveAlertContainer.isHidden = true
                        self.collectionViewContainer.isHidden = false
                    }
                case .connecting, .indeterminate:
                    self.passiveAlertContainer.isHidden = false
                    self.collectionViewContainer.isHidden = true
                    self.passiveAlertImageView.image = #imageLiteral(resourceName: "connecting")
                    self.passiveAlertLabel.stringValue = "Connecting"
                case .failed(let error):
                    self.collectionViewContainer.isHidden = true
                    self.passiveAlertContainer.isHidden = false
                    self.passiveAlertImageView.image = #imageLiteral(resourceName: "disconnect")
                    self.passiveAlertLabel.stringValue = error.description
                }

                default:
                break
                }
            }).disposed(by: disposeBag)

        session.torrents.asDriver().drive(onNext: { _ in
            self.collectionView.reloadData()
        }).disposed(by: disposeBag)

        viewModels = session.torrents.asObservable().map { $0.map { TorrentViewModel(torrent: $0, metadataManager: self.metadataManager) } }
        viewModels.bind(to: varViewModels).disposed(by: disposeBag)
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.session?.torrents.value.count ?? 0
    }

    let metadataManager = MetadataManager()

    var viewModels: Observable<[TorrentViewModel]> = Observable.just([])
    var varViewModels: Variable<[TorrentViewModel]> = Variable([])

    func collectionView(_ collectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        let item = self.collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: self.viewStyle.reuseIdentifier),
                                                for: indexPath) as! TorrentCollectionViewItem // swiftlint:disable:this force_cast

        item.torrentViewModel = varViewModels.value[indexPath.item]
        return item
    }

    // MARK: Selected Torrents

    var selectedTorrents: [Torrent] {
        let indexes = self.collectionView.selectionIndexPaths
        return indexes.flatMap { self.session?.torrents.value[$0.item] }
    }

    lazy var øSelectedTorrents: Observable<[Torrent]> = {
        let obs = self.collectionView.rx
            .observe(Set<IndexPath>.self, "selectionIndexPaths")

        let tor = obs
            .map { optionalIndexes -> Set<IndexPath> in
                if let optionalIndexes = optionalIndexes {
                    return optionalIndexes
                } else {
                    return Set<IndexPath>()
                }
            }
            .map { $0.flatMap { self.session?.torrents.value[$0.item] } }
        return tor
    }()

    lazy var hasSelectedTorrents: Observable<Bool> = {
        let obs = self.collectionView.rx
            .observe(Set<IndexPath>.self, "selectionIndexPaths")

        return obs
            .map { optionalIndexes -> Set<IndexPath> in
                if let optionalIndexes = optionalIndexes {
                    return optionalIndexes
                } else {
                    return Set<IndexPath>()
                }
            }
            .map {
                return !$0.isEmpty
            }

    }()

    // MARK: Sparkle Updater Stuff

    let updater = SUUpdater.shared()
    var pendingUpdateItem: SUAppcastItem?

    func startUpdater() {
        updater?.delegate = self
        updater?.checkForUpdatesInBackground()
    }

    func sortOutVersionWidget() {
        if let pendingUpdateItem = pendingUpdateItem,
            let newVersion = pendingUpdateItem.versionString {
            self.versionWidget.title="Update available: v\(newVersion)"
        } else {
            self.versionWidget.title = "Transmote v\(shortVersion)"
        }
    }

    @IBAction func updateWidgetClicked(_ sender: Any) {
        self.updater?.checkForUpdates(self)
    }
    func updater(_ updater: SUUpdater, didFindValidUpdate item: SUAppcastItem) {
        pendingUpdateItem = item
        sortOutVersionWidget()
    }

    // View style

    enum ViewStyle: Int {
        case grid = 0
        case list = 1

        var reuseIdentifier: String {
                return "TorrentCell"
        }

        var layout: NSCollectionViewLayout {
            switch self {
            case .grid:
                let layout = NSCollectionViewFlowLayout()
                layout.itemSize = NSSize(width: 400, height: 225)
                layout.minimumInteritemSpacing = 10
                layout.sectionInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
                return layout
            case .list:
                return ListLayout()
            }
        }
    }

    var viewStyle: ViewStyle = .grid {
        didSet {
            if let collectionView = self.collectionView {

                NSAnimationContext.beginGrouping()
                collectionView.animator().collectionViewLayout = viewStyle.layout

                NSAnimationContext.current.completionHandler = {
                    // This is a nasty hack to make it get the scrollers right...
                    if let window = self.view.window {
                        NSDisableScreenUpdates()
                        let origRect = window.frame
                        let insetRect = origRect.insetBy(dx: 1, dy: 1)
                        window.setFrame(insetRect, display: true)
                        window.setFrame(origRect, display: true)
                        NSEnableScreenUpdates()
                    }

                }
                NSAnimationContext.endGrouping()

            }

            UserDefaults.standard.set(viewStyle.rawValue, forKey: "viewStyle")
        }
    }

}
