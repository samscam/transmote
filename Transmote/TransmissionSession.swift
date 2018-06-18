//
//  TransmissionConnection.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 28/11/2016.
//

import Foundation

import Moya

import RxSwift

// A session - which coordinates access to a server and its torrents

class TransmissionSession {

    enum Status {
        case indeterminate
        case failed(SessionError)
        case connecting
        case connected
    }

    var server: TransmissionServer? {
        didSet {

            self.storeDefaultsServer(server: server) /// Storage should be elsewhere!!!

            guard let server = self.server else { // If the server is niled out...

                self.provider = nil
                if let connectCancellable = self.connectCancellable {
                    print("cancelling")
                    connectCancellable.cancel()
                }
                self.statusVar.value = .failed(.noServerSet)

                return
            }

            let endpointClosure = { (target: TransmissionTarget) -> Endpoint in

                // If we have no url then the provider ain't going to be no use...
                guard let serverURL = server.serverURL?.absoluteString else {
                    return MoyaProvider.defaultEndpointMapping(for: target)
                }

                let endpoint = Endpoint(url: serverURL,
                                                            sampleResponseClosure: {
                                                                .networkResponse(200, target.sampleData)
                                                            },
                                                            method: target.method,
                                                            task: target.task,
                                                            httpHeaderFields: target.headers)

                return endpoint
            }

            var plugins: [PluginType] = []
            if let credential = server.credential {
                plugins.append( CredentialsPlugin { _ -> URLCredential? in
                    return credential
                })
            }

            self.provider = JSONRPCProvider<TransmissionTarget>(endpointClosure: endpointClosure, plugins: plugins)

            connect()
        }
    }

    let statusVar: Variable<Status> = Variable<Status>(.indeterminate)
    lazy var status: Observable<Status> = self.statusVar
        .asObservable()
        .debounce(0.2, scheduler: MainScheduler.instance)
        .share(replay: 1)

    var provider: JSONRPCProvider<TransmissionTarget>?

    var torrents: Variable<[Int: BehaviorSubject<Torrent>]> = Variable([:])

    var timer: Timer?

    var updating = false

    var disposeBag = DisposeBag()

    var retryTimer: BackoffTimer?

    init() {

        // Observe our own status to start/stop update timer
        status
            .subscribe(onNext: { status in
            print("Status is \(status)")
            switch status {
            case .connected:
                self.startTimers()
                self.addDeferredTorrents()
            case .failed(let sessionError):
                self.torrents.value = [:]
                self.stopTimers()
                switch sessionError {
                case .networkError:
                    self.startRetryTimer()
                default:
                    break
                }

            default:
                self.torrents.value = [:]
            }
            }).disposed(by: disposeBag)

        defer {
            self.server = self.fetchDefaultsServer()
        }

        // This really shouldn't be here - it's desktop client stuff, not core
        let appleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(self,
                                          andSelector: #selector(TransmissionSession.handleGetURLEvent(_:withReplyEvent:)),
                                          forEventClass: AEEventClass(kInternetEventClass),
                                          andEventID: AEEventID(kAEGetURL))

    }

    var deferredMagnetURLs: [URL] = []

    @objc
    func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {

        if let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
            let url = URL(string: urlString) {
            if case .connected = self.statusVar.value {
                self.addTorrent(url: url)
            } else {
                self.deferredMagnetURLs.append(url)
            }
        }
    }

    // User defaults

    func fetchDefaultsServer() -> TransmissionServer? {
        let defaults = UserDefaults.standard
        if let address = defaults.string(forKey: "address"),
            let port = defaults.value(forKey: "port") as? Int,
            let rpcPath = defaults.string(forKey: "rpcPath") {
            let server = TransmissionServer(address: address, port: port, rpcPath: rpcPath)

            return server
        }
        return nil
    }

    func storeDefaultsServer(server: TransmissionServer?) {
        let defaults = UserDefaults.standard
        if let server = server {
            defaults.set(server.address, forKey: "address")
            defaults.set(server.port, forKey: "port")
            defaults.set(server.rpcPath, forKey: "rpcPath")
        } else {
            defaults.removeObject(forKey: "address")
            defaults.removeObject(forKey: "port")
            defaults.removeObject(forKey: "rpcPath")
        }
    }

    // Timers

    func startTimers() {

        retryTimer?.invalidate()
        retryTimer = nil

        self.updateEverything()

        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] _ in
            self?.updateEverything()
        })

    }

    func stopTimers() {
        timer?.invalidate()
        timer = nil

        retryTimer?.invalidate()
        retryTimer = nil
    }

    func startRetryTimer() {
        if self.retryTimer == nil {
            self.retryTimer = BackoffTimer(min: 5, max: 20) {
                self.connect()
            }
        }
    }

    func updateEverything() {
//        self.updateSessionStats()
        self.updateTorrents()
    }

    // Initial connection
    var connectCancellable: Cancellable?
    func connect() {
        if let connectCancellable = self.connectCancellable {
            print("cancelling")
            connectCancellable.cancel()
            self.connectCancellable = nil
        }

        guard self.server != nil else {
            print("No server")
            self.statusVar.value = .failed(.noServerSet)
            return
        }

        print("connecting")
        self.statusVar.value = .connecting
        connectCancellable = self.provider?.request(.connect) { result in
            switch result {
            case let .success(moyaResponse):

                switch moyaResponse.statusCode {

                case 200:
                    // Good so far

                    do {
                        // We should expect to have valid RPC response saying "success"
                        _ = try moyaResponse.filterJsonRpcFailures()
                        self.statusVar.value = .connected

                    } catch let error as MoyaError {
                        self.statusVar.value = .failed(.networkError(error))
                    } catch let error as SessionError {
                        self.statusVar.value = .failed(error)
                    } catch {
                        self.statusVar.value = .failed(.unknownError(error))
                    }

                case 404:
                    // The path was wrong probably
                    self.statusVar.value = .failed(SessionError.badRpcPath)
                case 401:
                    // The path was wrong probably
                    self.statusVar.value = .failed(SessionError.needsAuthentication)
                default:
                    // Something else happened - I wonder what it was
                    self.statusVar.value = .failed(SessionError.unexpectedStatusCode(moyaResponse.statusCode))
                }
            case let .failure(error):
                // Ignore cancellations - otherwise, pass the error along...
                switch error {
                case .underlying(let err):
                    if (err.0 as NSError).code != -999 {
                        self.statusVar.value = .failed(.networkError(error))
                    }
                default:
                    self.statusVar.value = .failed(.networkError(error))
                }

            }
        }
    }

    func updateTorrents() {
        self.provider?.request(.torrents) { result in
            switch result {
            case .success(let moyaResponse):
                do {

                    try moyaResponse.filterJsonRpcFailures()

                    let incomingTorrents = try moyaResponse.map([Torrent].self, atKeyPath: "arguments.torrents")

                    incomingTorrents.forEach { torrent in
                        if let innerObservable = self.torrents.value[torrent.id] {
                            // Update an existing torrent
                            innerObservable.on(.next(torrent))
                        } else {
                            // Add a new one
                            self.torrents.value[torrent.id] = BehaviorSubject(value: torrent)
                        }
                    }

                    // cleanup any removed ones
                    let allKeys = Set(self.torrents.value.keys)
                    let incomingIds = Set(incomingTorrents.map { $0.id })
                    let toRemove = allKeys.subtracting(incomingIds)

                    toRemove.forEach {
                        self.torrents.value[$0] = nil
                    }

                } catch let error as JSONRPCError {
                    self.statusVar.value = .failed(.rpcError(error))
                } catch {
                    self.statusVar.value = .failed(.unknownError(error))
                }

            case .failure(let error):
                print(error)
                self.statusVar.value = .failed(.networkError(error))
            }
        }
    }

    // MARK: Add torrents

    func addTorrent(url: URL) {
        provider?.request(.addTorrent(url), completion: { (result) in
            print(result)
        })
    }

    func addDeferredTorrents() {
        self.deferredMagnetURLs.forEach {
            self.addTorrent(url: $0)
        }
        deferredMagnetURLs = []
    }

    // MARK: Remove torrents

    func removeTorrents(torrents: [Torrent], delete: Bool) {
        if delete {
            provider?.request(.deleteTorrents(torrents)) { (result) in
                print(result)
            }
        } else {
            provider?.request(.removeTorrents(torrents)) { (result) in
                print(result)
            }
        }
    }

}
