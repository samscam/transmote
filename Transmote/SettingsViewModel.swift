//
//  SettingsViewModel.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 07/02/2017.
//

import Foundation
import RxSwift
import RxCocoa

class SettingsViewModel {

    public var statusBlobImage: Driver<Image>
//    public let showAuthThings: Driver<Bool>

    public let settingsHost: Variable<String?> = Variable("")
    public let settingsPort: Variable<String?> = Variable("")
    public let settingsPath: Variable<String?> = Variable("")
    public let settingsUsername: Variable<String?> = Variable("")
    public let settingsPassword: Variable<String?> = Variable("")

    let session: TransmissionSession
    let disposeBag = DisposeBag()

    var showingFakePassword: Bool = false

    init(session: TransmissionSession) {

        self.session = session

        // make sure we have initialised everything before actually configuring it all
        self.statusBlobImage = Driver.never()

        self.statusBlobImage = configureStatusBlob().asDriver(onErrorJustReturn: #imageLiteral(resourceName: "warning"))

        self.populateInitialValues()
        self.bindToSession()
    }

    func configureStatusBlob() -> Observable<Image> {
        return session.status
            .asObservable()
            .debounce(0.2, scheduler: MainScheduler.instance)
            .map { status -> Image in

                switch status {
                case .connected:
                    return #imageLiteral(resourceName: "status-green")
                case .connecting:
                    return #imageLiteral(resourceName: "status-orange")
                case .indeterminate:
                    return #imageLiteral(resourceName: "status-gray")
                case .failed(let sessionError):

                    switch sessionError {
                    case .needsAuthentication:
                        return #imageLiteral(resourceName: "status-orange")
                    default:
                        return #imageLiteral(resourceName: "status-red")
                    }
                }
            }
    }

    func populateInitialValues() {
        // Initial server values
        if let server = session.server {
            settingsHost.value = server.address
            if server.port != 9_091 {
                settingsPort.value = String(server.port)
            } else {
                settingsPort.value = ""
            }
            if server.rpcPath != "transmission/rpc" {
                settingsPath.value = server.rpcPath
            } else {
                settingsPath.value = ""
            }

            settingsUsername.value = server.username ?? ""
            settingsPassword.value = server.password ?? ""
        }
    }
    func bindToSession() {
        // Bind the fields back to the session

        Observable.combineLatest(settingsHost.asObservable(),
                                 settingsPort.asObservable(),
                                 settingsPath.asObservable(),
                                 settingsUsername.asObservable(),
                                 settingsPassword.asObservable() ) {
                                    ($0, $1, $2, $3, $4)
        }
        .throttle(1.0, scheduler: MainScheduler.instance )
        .skip(2) // skip both the initial (nil) value and the value set during populateInitialValues()
        .debug("SERVER CHANGE")
        .subscribe(onNext: { [weak self] (address, port, path, username, password) in
            var address = address
            var port = port
            var path = path
            var username = username
            var password = password

            if address == "" { address = nil }
            if port == "" { port = nil }
            if path == "" { path = nil }
            if username == "" { username = nil }
            if password == "" { password = nil }

            if let address = address {
                var portInt: Int? = nil
                if let port = port {
                    portInt = Int(port)
                }

                let server = TransmissionServer(address: address, port: portInt, rpcPath: path)
                self?.session.server = server
            }

            if let address = address {
                var portInt: Int? = nil
                if let port = port {
                    portInt = Int(port)
                }

                let server = TransmissionServer(address: address, port: portInt, rpcPath: path)

                if let username = username, let password = password {
                    server.setUsername(username, password: password)
                } else {
                    server.removeCredential()
                }

                self?.session.server = server
            } else {
                self?.session.server = nil
            }

        }).addDisposableTo(disposeBag)
    }
}
