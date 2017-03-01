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

    var disposeBag = DisposeBag()

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

        let transition = CATransition()
        transition.duration = 0.1

        box.wantsLayer = true
        box.layer?.add(transition, forKey: "transition")

        let subject: NSBox = self.box

        switch _highlightState {
        case .none:
            if _isSelected {
                subject.fillColor = NSColor(red: 0, green: 0.5, blue: 0.75, alpha: 0.7)
                subject.borderColor = NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.8)
                subject.borderWidth = 3
            } else {
                subject.fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.5)
                subject.borderWidth = 0
            }
        case .forSelection:
            subject.fillColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.6)
            subject.borderColor = NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.5)
            subject.borderWidth = 3
        case .forDeselection:
            subject.fillColor = NSColor(red: 0, green: 0.5, blue: 0.75, alpha: 0.6)
            subject.borderColor = NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.5)
            subject.borderWidth = 3
        case .asDropTarget:
            break
        }

    }

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

    var firstPass: Bool = true

    override func apply(_ layoutAttributes: NSCollectionViewLayoutAttributes) {

        super.apply(layoutAttributes)

        // This is so that it animates the subviews when changing bounds but doesn't bork the initial positioning
        if !firstPass {
            self.view.layoutSubtreeIfNeeded()
        } else {
            firstPass = false
        }
    }

}
