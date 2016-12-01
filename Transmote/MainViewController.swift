//
//  ViewController.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 19/11/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Cocoa
import RxSwift
import Moya

class MainViewController: NSViewController {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    }
}

