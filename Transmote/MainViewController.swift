//
//  ViewController.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 19/11/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import AppKit
import RxSwift
import Moya

class MainViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {

    var session: TransmissionSession? {
        didSet{
            bindToSession()
        }
    }
    
    var disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var collectionViewContainer: NSScrollView!
    
    @IBOutlet weak var passiveAlertContainer: NSBox!
    @IBOutlet weak var passiveAlertLabel: NSTextField!
    @IBOutlet weak var passiveAlertImageView: NSImageView!
    
    @IBOutlet weak var versionWidget: NSButton!
    
    let shortVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    
    let longVersion: String=Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register cell
        let nib = NSNib(nibNamed: "TorrentCollectionViewItem", bundle: nil)
        self.collectionView.register(nib, forItemWithIdentifier: "TorrentCell")
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.versionWidget.title = "Version \(shortVersion) (\(longVersion))"
        
        bindToSession()
    }

    func bindToSession(){
        
        guard let session = session else {
            return
        }

        guard self.isViewLoaded else {
            return
        }
        disposeBag = DisposeBag()
        
        
        // Observe the session status
        
        session.status.asObservable()
            .debounce(0.2, scheduler: MainScheduler.instance)
            .subscribe(onNext:{ status in
                
                switch status {
                case .connected:
                    self.passiveAlertContainer.isHidden = true
                    self.collectionViewContainer.isHidden = false
                case .connecting, .indeterminate:
                    self.passiveAlertContainer.isHidden = false
                    self.collectionViewContainer.isHidden = true
                case .failed(let error):
                    self.collectionViewContainer.isHidden = true
                    self.passiveAlertContainer.isHidden = false
                    self.passiveAlertLabel.stringValue = error.description

                }
                
            }).addDisposableTo(disposeBag)
        
        session.torrents.asDriver().drive(onNext: { _ in
            self.collectionView.reloadData()
        }).addDisposableTo(disposeBag)
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.session?.torrents.value.count ?? 0
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = self.collectionView.makeItem(withIdentifier: "TorrentCell", for: indexPath) as! TorrentCollectionViewItem
        item.torrent = self.session?.torrents.value[indexPath.item]
        return item
    }
    
}

