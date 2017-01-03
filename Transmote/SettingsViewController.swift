//
//  SettingsViewController.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 22/11/2016.
//

import Foundation
import Cocoa

import RxSwift
import RxCocoa

class SettingsViewController: NSViewController {
    
    var session: TransmissionSession?
    
    @IBOutlet weak private var statusBlobImageView: NSImageView!
    
    @IBOutlet weak private var serverAddressField: NSTextField!
    
    @IBOutlet weak private var portField: NSTextField!
    @IBOutlet weak private var rpcPathField: NSTextField!
    @IBOutlet weak private var usernameField: NSTextField!
    @IBOutlet weak private var passwordField: NSSecureTextField!
    
    @IBOutlet weak private var rpcPathStack: NSStackView!
    @IBOutlet weak private var usernameStack: NSStackView!
    @IBOutlet weak private var passwordStack: NSStackView!
    
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
            .subscribe(onNext: { [weak self] status in
            
            switch status {
            case .connected:
                self?.statusBlobImageView.image = NSImage(named: "status-green")
            case .connecting:
                self?.statusBlobImageView.image = NSImage(named: "status-orange")
            case .indeterminate:
                self?.statusBlobImageView.image = NSImage(named: "status-gray")
            case .failed:
                self?.statusBlobImageView.image = NSImage(named: "status-red")
            }
            
        }).addDisposableTo(disposeBag)
        
        // Initial server values
        
        serverAddressField.stringValue = server.address ?? ""
        portField.stringValue = String(server.port)
        rpcPathField.stringValue = server.rpcPath
        

        // Bind the fields back to the session

        Observable.combineLatest(serverAddressField.rx.text, portField.rx.text, rpcPathField.rx.text) { ($0, $1, $2) }
            .throttle(0.5, scheduler: MainScheduler.instance )
            .debug("SERVER CHANGE")
            .skip(1)
            .subscribe(onNext: { [weak self] (address, port, path) in
                if let address = address {
                    var portInt: Int? = nil
                    if let port = port {
                        portInt = Int(port)
                    }
                    let server = TransmissionServer(address: address, port: portInt, rpcPath: path)
                    self?.session?.server = server
                }
        }).addDisposableTo(disposeBag)
        
    }

}
