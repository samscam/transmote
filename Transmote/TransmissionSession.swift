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

public enum SessionError: Swift.Error, CustomStringConvertible{
    case networkError(Moya.Error)
    case badRpcPath
    case unexpectedStatusCode(Int)
    case unknownError(Swift.Error)
    case rpcError(JSONRPCError)
    
    public var description: String{
        switch self {
        case .networkError(let moyaError):
            switch moyaError {
            case .underlying(let underlying):
                return underlying.localizedDescription
            case .jsonMapping:
                return "The server returned something other than JSON\n\nProbably a bad RPC path or not a Transmission Server"
            default:
                return "Network error:\n\n\(moyaError.localizedDescription)"
            }
            
        case .badRpcPath:
            return "Bad RPC path or not a Transmission Server"
        case .unknownError:
            return "Unknown error"
        case .unexpectedStatusCode(let statusCode):
            return "Unexpected status code: \(statusCode)"
        case .rpcError(let rpcError):
            return rpcError.description
        }
    }
}

class TransmissionSession{
    
    enum Status{
        case indeterminate
        case failed(SessionError)
        case connecting
        case connected
    }
    
    var server: TransmissionServer? {
        didSet{
            let endpointClosure = { (target: TransmissionTarget) -> Endpoint<TransmissionTarget> in
                
                // If we have no url then the provider ain't going to be no use...
                guard let serverURL = self.server?.serverURL?.absoluteString else {
                    return MoyaProvider.defaultEndpointMapping(for: target)
                }
                
                
                let endpoint = Endpoint<TransmissionTarget>(url: serverURL, sampleResponseClosure: { .networkResponse(200, target.sampleData) }, method: target.method, parameters: target.parameters, parameterEncoding: JSONEncoding.default)
                return endpoint
            }
            
            self.provider = JSONRPCProvider<TransmissionTarget>(endpointClosure: endpointClosure)
            
            if let server = self.server {
                self.storeDefaultsServer(server: server)
            }
            
            connect()
        }
    }
    
    var status: Variable<Status> = Variable<Status>(.indeterminate)
    
    var provider: JSONRPCProvider<TransmissionTarget>?
    
    var torrents: Variable<[Torrent]> = Variable([])
    var stats: SessionStats?
    
    var timer: Timer?
    
    var updating = false
    
    var disposeBag = DisposeBag()
    
    var retryTimer: BackoffTimer?
    
    init(){
        
        // Observe our own status to start/stop update timer
        status.asObservable()
            .debounce(0.2, scheduler: MainScheduler.instance)
            .subscribe(onNext: { status in
            print("Status is \(status)")
            switch status {
                case .connected:
                    self.startTimers()
                    self.addDeferredTorrents()
                case .failed:
                    self.torrents.value = []
                    self.stopTimers()
                    self.startRetryTimer()
                default:
                    self.torrents.value = []
                    break
            }
        }).addDisposableTo(disposeBag)
        
        
        defer{
            self.server = self.fetchDefaultsServer()
        }
        
        let appleEventManager = NSAppleEventManager.shared()
        appleEventManager.setEventHandler(self, andSelector: #selector(TransmissionSession.handleGetURLEvent(_:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))
        
    }
    
    var deferredMagnetURLs: [URL] = []
    
    @objc
    func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor){
    
        if let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
            let url = URL(string: urlString) {
            if case .connected = self.status.value {
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
            let rpcPath = defaults.string(forKey: "rpcPath"){
            return TransmissionServer(address:address, port: port, rpcPath: rpcPath)
        }
        return nil
    }
    
    func storeDefaultsServer(server: TransmissionServer){
        let defaults = UserDefaults.standard
        defaults.set(server.address, forKey: "address")
        defaults.set(server.port, forKey: "port")
        defaults.set(server.rpcPath, forKey: "rpcPath")
    }
    
    
    // Timers
    
    func startTimers(){
        
        retryTimer?.invalidate()
        retryTimer = nil
        
        self.updateEverything()
        
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] (timer) in
            self?.updateEverything()
        })

    }
    
    func stopTimers(){
        timer?.invalidate()
        timer = nil
    }
    
    func startRetryTimer(){
        if self.retryTimer == nil {
            self.retryTimer = BackoffTimer(min: 5, max: 20){
                self.connect()
            }
        }
    }
    
    func updateEverything(){
//        self.updateSessionStats()
        self.updateTorrents()
    }
    
    // Initial connection
    var connectCancellable: Cancellable?
    func connect(){
        if let connectCancellable = self.connectCancellable {
            print("cancelling")
            connectCancellable.cancel()
        }
        print("connecting")
        self.status.value = .connecting
        connectCancellable = self.provider?.request(.connect){ result in
            switch result {
            case let .success(moyaResponse):
                switch moyaResponse.statusCode {

                case 200:
                    // Good so far
                    
                    do {
                        // We should expect to have valid RPC response saying "success"
                        let _ = try moyaResponse.mapJsonRpc()
                        self.status.value = .connected
                        
                    } catch let error as Moya.Error {
                        print("There was an error \(error)")
                        self.status.value = .failed(.networkError(error))
                    } catch let error as SessionError {
                        self.status.value = .failed(error)
                    } catch {
                        self.status.value = .failed(.unknownError(error))
                    }
                    
                case 404:
                    // The path was wrong probably
                    print("404 - wrong path")
                    self.status.value = .failed(SessionError.badRpcPath)
                default:
                    // Something else happened - I wonder what it was
                    print("Oh dear - status code \(moyaResponse.statusCode)")
                    self.status.value = .failed(SessionError.unexpectedStatusCode(moyaResponse.statusCode))
                }
            case let .failure(error):
                // Ignore cancellations - otherwise, pass the error along...
                switch error {
                case .underlying(let err):
                    if (err as NSError).code != -999 {
                        self.status.value = .failed(.networkError(error))
                    }
                default:
                    self.status.value = .failed(.networkError(error))
                }

            }
        }
    }
    
    
    func updateSessionStats(){
        self.provider?.request(.stats){ result in
            switch result {
            case .success(let moyaResponse):
                do {
                    let json = try moyaResponse.mapJsonRpc()
                    self.stats = SessionStats(JSON: json)
                } catch {
                    // RPC or server error
                    print(error)
                }
            case .failure(let error):
                // Network error
                print(error)
                self.status.value = .failed(.networkError(error))
            }
        }
    }
    
    func updateTorrents(){
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
                    
                    let updatedTorrents: [Torrent] = torrentsArray.flatMap{
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
                            let index = self.torrents.value.index(of: t){
                            self.torrents.value.remove(at: index)
                        }
                    }
                } catch {
                    print(error)
                }
            case .failure(let error):
                print(error)
                self.status.value = .failed(.networkError(error))
            }
        }
    }
    
    // MARK: Add torrents
    
    func addTorrent(url: URL){
        provider?.request(.addTorrent(url), completion: { (result) in
            print(result)
        })
    }
    
    func addDeferredTorrents(){
        for t in self.deferredMagnetURLs {
            self.addTorrent(url: t)
        }
        deferredMagnetURLs = []
    }
    
    // MARK: Remove torrents
    
    func removeTorrents(torrents: [Torrent], delete: Bool){
        if delete {
            provider?.request(.removeTorrents(torrents)) { (result) in
                print(result)
            }
        } else {
            provider?.request(.deleteTorrents(torrents)) { (result) in
                print(result)
            }
        }
    }
    
}

extension Collection where Iterator.Element: Hashable {
    func element(matching hash: Int) -> Iterator.Element? {
        return self.first(where: { $0.hashValue == hash })
    }
}
