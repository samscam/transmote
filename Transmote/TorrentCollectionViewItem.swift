//
//  TorrentCollectionViewItem.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 05/12/2016.
//

import Foundation
import AppKit
import QuartzCore

import RxSwift
import RxCocoa
import ProgressKit

class TorrentCollectionViewItem: NSCollectionViewItem {

    @IBOutlet weak private var box: NSBox!
    @IBOutlet weak private var torrentImageView: ProperImageView!

    @IBOutlet weak private var titleLabel: NSTextField!
    @IBOutlet weak private var episodeLabel: NSTextField!

    @IBOutlet weak private var progressStatusLabel: NSTextField!
    @IBOutlet weak private var progressView: CircularProgressView!

    var persistentDisposeBag = DisposeBag()

    var light: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.strokeWidth = 3
        progressView.background = NSColor.clear
        progressView.foreground = NSColor.white
        sortSelection()
    }

    private var _isSelected: Bool = false
    override var isSelected: Bool {
        set {
            _isSelected = newValue
            sortSelection()
        }
        get {
            return _isSelected
        }
    }
    private var _highlightState: NSCollectionViewItemHighlightState = .none

    override var highlightState: NSCollectionViewItemHighlightState {
        set {
            _highlightState = newValue
            sortSelection()
        }
        get {
            return _highlightState
        }
    }

    func sortSelection() {
        switch _highlightState {
        case .none:
            if _isSelected {
                self.box.fillColor = NSColor(red: 0, green: 0.5, blue: 0.75, alpha: 0.7)
                self.box.borderColor = NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.8)
                self.box.borderWidth = 3
            } else {
                if light {
                    self.box.fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.05)
                } else {
                    self.box.fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.5)
                }
                self.box.borderWidth = 0
            }
        case .forSelection:
            if light {
                self.box.fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.2)
            } else {
                self.box.fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.6)
            }

            self.box.borderColor = NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.5)
            self.box.borderWidth = 3
        case .forDeselection:
            if light {
                self.box.fillColor = NSColor(red: 0, green: 0.5, blue: 0.75, alpha: 0.2)
            } else {
                self.box.fillColor = NSColor(red: 0, green: 0.5, blue: 0.75, alpha: 0.6)
            }
            self.box.borderColor = NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.5)
            self.box.borderWidth = 3
        case .asDropTarget:
            break
        }

    }

    var disposeBag = DisposeBag()

    var torrentViewModel: TorrentViewModel? {
        didSet {

            guard torrentViewModel != oldValue else {
                // It was the same torrent we are already bound to. Ignore
                return
            }

            disposeBag = DisposeBag()

            guard let torrentViewModel = torrentViewModel else {
                // we got a nil. clean up and return
                return
            }

            print("Cell set torrent \(torrentViewModel.torrent.id)")

            torrentViewModel.title.bindTo(titleLabel.rx.text).addDisposableTo(disposeBag)

            torrentViewModel.subtitle.bindTo(episodeLabel.rx.text).addDisposableTo(disposeBag)

            torrentViewModel.image.drive(torrentImageView.rx.image).addDisposableTo(disposeBag)
            torrentViewModel.imageContentMode.bindTo(torrentImageView.rx.contentMode).addDisposableTo(disposeBag)

            torrentViewModel.progress.subscribe(onNext: { newValue in
                self.progressView.progress = CGFloat(newValue)

            }).addDisposableTo(disposeBag)

            torrentViewModel.statusMessage.bindTo(progressStatusLabel.rx.text).addDisposableTo(disposeBag)

            torrentViewModel.statusColor.subscribe(onNext: { color in
                self.progressView.foreground = color
            }).addDisposableTo(disposeBag)
        }
    }
}
