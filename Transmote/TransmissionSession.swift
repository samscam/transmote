//
//  TransmissionConnection.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 28/11/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Foundation

import Moya

import RxSwift

// A session - which coordinates access to a server and its torrents

public enum SessionError: Swift.Error, CustomStringConvertible{
    case networkError(Moya.Error)
    case badRpcPath
    case unknownError(Swift.Error)
    case serverError(String)
    
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
        case .serverError(let str):
            return "Server error:\n\(str)"
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
                    return MoyaProvider.defaultEndpointMapping(target)
                }
                
                
                let endpoint = Endpoint<TransmissionTarget>(url: serverURL, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters , parameterEncoding: JSONEncoding.default)
                
                if let sessionId = self.sessionId {
                    return endpoint.adding(newHTTPHeaderFields: ["X-Transmission-Session-Id": sessionId])
                } else {
                    return endpoint
                }
                
            }
            
            self.provider = MoyaProvider<TransmissionTarget>(endpointClosure: endpointClosure)
            
            connect()
        }
    }
    
    var status: Variable<Status> = Variable<Status>(.indeterminate)
    var sessionId: String?
    
    var provider: MoyaProvider<TransmissionTarget>!
    
    var torrents: Variable<[Torrent]> = Variable([])
    var stats: SessionStats?
    
    var timer: Timer?
    
    var updating = false
    
    var disposeBag = DisposeBag()
    
    init(){
        
        // Observe our own status to start/stop update timer
        status.asObservable().subscribe(onNext: { status in
            print("Status is \(status)")
            switch status {
                case .connected:
                    self.startTimers()
                default:
                    self.torrents.value = []
                    self.stopTimers()
            }
        }).addDisposableTo(disposeBag)
        
    }
    
    // Timers
    
    func startTimers(){

        self.updateEverything()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            self?.updateEverything()
        })

    }
    
    func stopTimers(){
        timer?.invalidate()
        timer = nil
    }
    
    func updateEverything(){
        self.updateSessionStats()
        self.updateTorrents()
    }
    
    // Initial connection
    var connectCancellable: Cancellable?
    func connect(){
        
        connectCancellable?.cancel()
        
        self.status.value = .connecting
        connectCancellable = self.provider.request(.connect){ result in
            switch result {
            case let .success(moyaResponse):
                switch moyaResponse.statusCode {
                case 409:
                    // we should have a session id in this response
                    if let httpResponse = moyaResponse.response as? HTTPURLResponse, let sessionId = httpResponse.allHeaderFields["X-Transmission-Session-Id"] as? String {
                        self.sessionId = sessionId
                        print("Got session Id \(sessionId)")
                        self.connect()
                    }
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
                    self.status.value = .failed(SessionError.serverError("Unexpected status code \(moyaResponse.statusCode)"))
                    
                }
            case let .failure(error):
                print(error)
                self.status.value = .failed(.networkError(error))
            }
        }
    }
    
    
    func updateSessionStats(){
        self.provider.request(.stats){ result in
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
        self.provider.request(.torrents){ result in
            switch result {
            case .success(let moyaResponse):
                do {
                    let json = try moyaResponse.mapJsonRpc()
                    /*
                    self.torrents.value = (json["torrents"] as! [[String:Any]]).flatMap{
                        guard let id = $0["id"] as? Int else {
                            return nil
                        }
                        if let existing = self.torrents.value.element(matching: id) {
                            // Update existing torrent
                            return existing.update(JSON:$0)
                        } else {
                            // Create a new one
                            return Torrent(JSON:$0)
                        }
                    }
                    */
                    
                    var torrentsCpy = self.torrents.value
                    
                    let updatedTorrents: [Torrent] = (json["torrents"] as! [[String:Any]]).flatMap{
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
    
}

extension Collection where Iterator.Element: Hashable {
    func element(matching hash: Int) -> Iterator.Element? {
        return self.first(where: { $0.hashValue == hash })
    }
}
