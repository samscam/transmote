//
//  TorrentCollectionViewItem.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 05/12/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Foundation
import AppKit
import QuartzCore

import RxSwift
import RxCocoa
import ProgressKit

class TorrentCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var torrentImageView: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var episodeLabel: NSTextField!
    
    @IBOutlet weak var progressStatusLabel: NSTextField!
    @IBOutlet weak var progressView: CircularProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.strokeWidth = 3
        progressView.background = NSColor.clear
        progressView.foreground = NSColor.white
        
    }
    
    var disposeBag = DisposeBag()
    
    var torrent: Torrent? {
        didSet {
            
            guard torrent != oldValue else {
                // It was the same torrent we are already bound to. Ignore
                return
            }
            
            disposeBag = DisposeBag()
            
            guard let torrent = torrent else {
                // we got a nil. clean up and return
                return
            }
            
            print("Cell set torrent \(torrent.id)")
            
            torrent.name.bindTo(episodeLabel.rx.text).addDisposableTo(disposeBag)
            torrent.bestName.bindTo(titleLabel.rx.text).addDisposableTo(disposeBag)
            
            torrent.percentDone.subscribe(onNext: { newValue in
                self.progressView.progress = CGFloat(newValue)
                
            }).addDisposableTo(disposeBag)
            

            torrent.status.subscribe(onNext: { status in
                self.progressStatusLabel.stringValue = status.description
                self.progressView.foreground = status.color
                
            }).addDisposableTo(disposeBag)
            
        }
    }
}
