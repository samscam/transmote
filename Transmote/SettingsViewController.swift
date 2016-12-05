//
//  SettingsViewController.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 22/11/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Foundation
import Cocoa

import RxSwift
import RxCocoa

class SettingsViewController: NSViewController {
    
    var session: TransmissionSession?
    
    @IBOutlet weak var statusBlobImageView: NSImageView!
    
    @IBOutlet weak var serverAddressField: NSTextField!
    
    @IBOutlet weak var portField: NSTextField!
    @IBOutlet weak var rpcPathField: NSTextField!
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    
    @IBOutlet weak var rpcPathStack: NSStackView!
    @IBOutlet weak var usernameStack: NSStackView!
    @IBOutlet weak var passwordStack: NSStackView!
    
    var disposeBag: DisposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let session = session else {
            return
        }
        
        guard let server = session.server else {
            return
        }
        
        disposeBag = DisposeBag()
        
        usernameStack.isHidden = true
        passwordStack.isHidden = true
        
        
        // Observe the session status
        
        session.status.asObservable()
            .debounce(0.2, scheduler: MainScheduler.instance)
            .subscribe(onNext:{ status in
            
            switch status {
            case .connected:
                self.statusBlobImageView.image = NSImage(named: "status-green")
            case .connecting:
                self.statusBlobImageView.image = NSImage(named: "status-orange")
            case .indeterminate:
                self.statusBlobImageView.image = NSImage(named: "status-gray")
            case .failed:
                self.statusBlobImageView.image = NSImage(named: "status-red")
            }
            
        }).addDisposableTo(disposeBag)
        
        // Initial server values
        
        serverAddressField.stringValue = server.address ?? ""
        portField.stringValue = String(server.port)
        rpcPathField.stringValue = server.rpcPath
        

        // Bind the fields back to the session

        Observable.combineLatest(serverAddressField.rx.text, portField.rx.text, rpcPathField.rx.text){ ($0,$1,$2) }
            .throttle(0.5, scheduler: MainScheduler.instance )
            .subscribe(onNext:{(address,port,path) in
                server.address = address
                server.port = Int(port!) ?? 9091
                server.rpcPath = path!
                self.session?.connect()
        }).addDisposableTo(disposeBag)
        
    }

}
