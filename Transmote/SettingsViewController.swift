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

protocol SettingsPopoverDelegate: class {
    func settingsDismissed(sender: SettingsViewController)
}

class SettingsViewController: NSViewController {

    var session: TransmissionSession?
    weak var delegate: SettingsPopoverDelegate?

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

    var showAuthThings: Bool = false {
        didSet {
            usernameStack.isHidden = !showAuthThings
            passwordStack.isHidden = !showAuthThings
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let session = session else {
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
            case .failed(let sessionError):
                self?.statusBlobImageView.image = NSImage(named: "status-red")

                switch sessionError {

                case .needsAuthentication:
                    self?.showAuthThings = true
                default:
                    self?.showAuthThings = false
//                    break
                }
            }

        }).addDisposableTo(disposeBag)

        // Initial server values
        var skip = 0
        if let server = session.server {
            serverAddressField.stringValue = server.address
            if server.port != 9_091 {
                portField.stringValue = String(server.port)
            } else {
                portField.stringValue = ""
            }
            if server.rpcPath != "transmission/rpc" {
                rpcPathField.stringValue = server.rpcPath
            } else {
                rpcPathField.stringValue = ""
            }
            skip = 1
        }

        // Bind the fields back to the session

        Observable.combineLatest(serverAddressField.rx.text, portField.rx.text, rpcPathField.rx.text) { ($0, $1, $2) }
            .throttle(0.5, scheduler: MainScheduler.instance )
            .debug("SERVER CHANGE")
            .skip(skip)
            .subscribe(onNext: { [weak self] (address, port, path) in
                var address = address
                var port = port
                var path = path

                if address == "" { address = nil }
                if port == "" { port = nil }
                if path == "" { path = nil }

                if let address = address {
                    var portInt: Int? = nil
                    if let port = port {
                        portInt = Int(port)
                    }
                    let server = TransmissionServer(address: address, port: portInt, rpcPath: path)
                    self?.session?.server = server
                } else {
                    self?.session?.server = nil
                }
        }).addDisposableTo(disposeBag)

    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.delegate?.settingsDismissed(sender: self)
    }

}
