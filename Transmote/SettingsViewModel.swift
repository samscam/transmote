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
    public var showUsernameAndPassword: Driver<Bool>

    public let settingsHost: Variable<String?> = Variable("")
    public let settingsPort: Variable<String?> = Variable("")
    public let settingsPath: Variable<String?> = Variable("")
    public let settingsUsername: Variable<String?> = Variable("")
    public let settingsPassword: Variable<String?> = Variable("")

    let server: Variable<TransmissionServer?>

    let session: TransmissionSession
    let disposeBag = DisposeBag()

    init(session: TransmissionSession) {

        self.session = session
        self.server = Variable(session.server)

        // make sure we have initialised everything before actually configuring it all
        self.statusBlobImage = Driver.never()
        self.showUsernameAndPassword = Driver.never()

        self.statusBlobImage = configureStatusBlob().asDriver(onErrorJustReturn: #imageLiteral(resourceName: "warning"))
        self.showUsernameAndPassword = configureShowPassword().asDriver(onErrorJustReturn:false)

        self.populate()
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

    /// It should show the password fields if...
    /// - the server has a credential
    /// - or the session has reported that authentication is needed
    func configureShowPassword() -> Observable<Bool> {
        return Observable.combineLatest(server.asObservable(), session.status) { ($0, $1) }
            .map { server, status -> Bool in
                var show: Bool = false

                switch status {
                case .failed(let sessionError):

                    switch sessionError {
                    case .needsAuthentication:
                        show = true
                    default:
                        break
                    }
                default:
                    break
                }

                if let _ = server?.credential {
                    show = true
                }

                return show
            }
    }

    func populate() {
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
                                 settingsPath.asObservable()) {
                                    ($0, $1, $2)
        }
        .throttle(0.3, scheduler: MainScheduler.instance )
        .skip(2) // skip both the initial (nil) value and the value set during populateInitialValues()
        .debug("SERVER CHANGE")
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

                self?.server.value = server
            } else {
                self?.server.value = nil
            }

        }).addDisposableTo(disposeBag)

        Observable.combineLatest(settingsUsername.asObservable(), settingsPassword.asObservable()) { ($0, $1) }
            .subscribe(onNext: { username, password in
                print("U/P setting changed")
                var username = username
                var password = password
                if username == "" { username = nil }
                if password == "" { password = nil }

                if let username = username, let password = password {
                    self.server.value?.setUsername(username, password: password)
                } else {
                    self.server.value?.removeCredential()
                }

                // force the session to try connecting again
                self.session.server = self.server.value
            }).addDisposableTo(disposeBag)

        self.server.asObservable().skip(1).subscribe(onNext: { (server) in
            print("Pushing server to session")
            self.session.server = server
        }).addDisposableTo(disposeBag)

    }
}
