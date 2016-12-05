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
    
//    var hueFilter: CIFilter = CIFilter(name: "CIFalseColor" , withInputParameters:["inputColor0":CIColor(red:0,green:0,blue:0), "inputColor1":CIColor(red:1,green:1,blue:1)] )!
    var hueFilter: CIFilter = CIFilter(name: "CIHueAdjust" , withInputParameters:["inputAngle":0] )!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.controlTint = .blueControlTint
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
                hueFilter.setValue( Double.pi * 2 * 0.3 , forKey: "inputAngle")
            case .downloading:
                hueFilter.setValue(Double.pi * 2 * 0, forKey: "inputAngle")
                progressStatusLabel.stringValue = "Downloading"
            case .seeding:
                hueFilter.setValue(Double.pi * 2 * 0.3, forKey: "inputAngle")
                progressStatusLabel.stringValue = "Seeding"
            case .stalled:
                hueFilter.setValue(Double.pi * 2 * 0.5, forKey: "inputAngle")
                progressStatusLabel.stringValue = "Stalled"
            case .complete:
                hueFilter.setValue(Double.pi * 2 * 0.65, forKey: "inputAngle")
                progressStatusLabel.stringValue = "Complete"
            }
           
        } else {
            progressStatusLabel.stringValue = ""
            hueFilter.setValue(Double.pi * 2 * 0.3, forKey: "inputAngle")
        }

        }
    }
}
