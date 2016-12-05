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

class TorrentCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet weak var torrentImageView: NSImageView!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var episodeLabel: NSTextField!
    
    @IBOutlet weak var progressStatusLabel: NSTextField!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    var hueFilter: CIFilter = CIFilter(name: "CIFalseColor" , withInputParameters:["inputColor0":CIColor(red:0,green:0,blue:0), "inputColor1":CIColor(red:1,green:1,blue:1)] )!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.contentFilters = [hueFilter]
    }
    var torrent: Torrent? { didSet {
            titleLabel.stringValue = torrent?.bestName ?? ""
            episodeLabel.stringValue = torrent?.name ?? ""
            progressBar.doubleValue = torrent?.progress ?? 0
        
        if let torrent = torrent {
            switch torrent.status{
            case .fetchingMetadata:
                progressStatusLabel.stringValue = "Fetching metadata..."
                hueFilter.setValue(CIColor(red:1,green:1,blue:1), forKey: "inputColor1")
            case .downloading:
                hueFilter.setValue(CIColor(red:0,green:1,blue:0), forKey: "inputColor1")
                progressStatusLabel.stringValue = "Downloading"
            case .seeding:
                hueFilter.setValue(CIColor(red:0,green:0,blue:1), forKey: "inputColor1")
                progressStatusLabel.stringValue = "Seeding"
            case .stalled:
                hueFilter.setValue(CIColor(red:1,green:1,blue:1), forKey: "inputColor1")
                progressStatusLabel.stringValue = "Stalled"
            case .complete:
                hueFilter.setValue(CIColor(red:0,green:1,blue:1), forKey: "inputColor1")
                progressStatusLabel.stringValue = "Complete"
            }
           
        } else {
            hueFilter.setValue(CIColor(red:1,green:1,blue:1), forKey: "inputColor1")
        }

        
        }
    }
    
}
