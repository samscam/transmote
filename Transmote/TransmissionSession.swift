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

public enum SessionError: Swift.Error{
    case networkError(Moya.Error)
    case badRpcPath
    case unknownError
    case serverError(String)
}

class TransmissionSession{
    
    enum Status{
        case indeterminate
        case failed(Swift.Error)
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
                
                
                let endpoint = Endpoint<TransmissionTarget>(URL: serverURL, sampleResponseClosure: {.networkResponse(200, target.sampleData)}, method: target.method, parameters: target.parameters , parameterEncoding: JSONEncoding.default)
                
                if let sessionId = self.sessionId {
                    return endpoint.adding(newHttpHeaderFields: ["X-Transmission-Session-Id": sessionId])
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
    
    var torrents: [Torrent] = []
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
                    self.stopTimers()
            }
        }).addDisposableTo(disposeBag)
        
    }
    
    // Timers
    
    func startTimers(){

        self.updateEverything()
        
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { [weak self] (timer) in
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
    
    func connect(){
        
        self.status.value = .connecting
        self.provider.request(.connect){ result in
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
                        
                    } catch {
                        print("There was an error \(error)")
                        self.status.value = .failed(error)
                    }
                case 404:
                    // The path was wrong probably
                    print("404 - wrong path")
                    self.status.value = .failed(SessionError.badRpcPath)
                default:
                    // Something else happened - I wonder what it was
                    print("Oh dear - status code \(moyaResponse.statusCode)")
                    self.status.value = .failed(SessionError.unknownError)
                }
            case let .failure(error):
                print(error)
                self.status.value = .failed(error)
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
                self.status.value = .failed(error)
            }
        }
    }
    
    func updateTorrents(){
        self.provider.request(.torrents){ result in
            switch result {
            case .success(let moyaResponse):
                do {
                    let json = try moyaResponse.mapJsonRpc()
                    self.torrents = (json["torrents"] as! [[String:Any]]).flatMap{ Torrent(JSON:$0) }
                    for torrent in self.torrents {
                        var torrent = torrent
                        print(torrent.derivedMetadata!)
                    }
                } catch {
                    print(error)
                }
            case .failure(let error):
                print(error)
                self.status.value = .failed(error)
            }
        }
    }
    
}


