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

            self.storeDefaultsServer(server: server)

            guard let server = self.server else {
                self.provider = nil
                if let connectCancellable = self.connectCancellable {
                    print("cancelling")
                    connectCancellable.cancel()
                }
                self.statusVar.value = .failed(.noServerSet)

                return
            }

            let endpointClosure = { (target: TransmissionTarget) -> Endpoint<TransmissionTarget> in

                // If we have no url then the provider ain't going to be no use...
                guard let serverURL = server.serverURL?.absoluteString else {
                    return MoyaProvider.defaultEndpointMapping(for: target)
                }

                let endpoint = Endpoint<TransmissionTarget>(url: serverURL,
                                                            sampleResponseClosure: {
                                                                .networkResponse(200, target.sampleData)
                                                            },
                                                            method: target.method,
                                                            parameters: target.parameters,
                                                            parameterEncoding: target.parameterEncoding)
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
        .shareReplay(1)

    var provider: JSONRPCProvider<TransmissionTarget>?

    var torrents: Variable<[Torrent]> = Variable([])

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
                    self.torrents.value = []
                    self.stopTimers()
                    switch sessionError {
                    case .networkError:
                        self.startRetryTimer()
                    default:
                        break
                    }

                default:
                    self.torrents.value = []
                    break
            }
        }).addDisposableTo(disposeBag)

        defer {
            self.server = self.fetchDefaultsServer()
        }

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
            let server = TransmissionServer(address:address, port: port, rpcPath: rpcPath)

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
                        _ = try moyaResponse.mapJsonRpc()
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
                    if (err as NSError).code != -999 {
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
                    let json = try moyaResponse.mapJsonRpc()

                    var torrentsCpy = self.torrents.value

                    // We are mutating the existing array rather than simply replacing it with a fresh one - this could be genericised
                    guard let torrentsArray = json["torrents"] as? [[String:Any]] else {
                        throw JSONRPCError.jsonParsingError("Missing Torrents array")
                    }

                    let updatedTorrents: [Torrent] = torrentsArray.flatMap {
                        guard let id = $0["id"] as? Int else {
                            return nil
                        }
                        if let existing = torrentsCpy.element(matching: id) {
                            // Update existing torrent
                            return existing.update(JSON:$0)
                        } else {
                            // Create a new one
                            return Torrent(JSON:$0)
                        }
                    }

                    for t in updatedTorrents {
                        // add new ones
                        if self.torrents.value.index(of: t) == nil {
                            self.torrents.value.append(t)
                        }
                    }

                    torrentsCpy = self.torrents.value
                    for t in self.torrents.value {
                        if updatedTorrents.index(of: t) == nil ,
                            let index = self.torrents.value.index(of: t) {
                            self.torrents.value.remove(at: index)
                        }
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
        for t in self.deferredMagnetURLs {
            self.addTorrent(url: t)
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
