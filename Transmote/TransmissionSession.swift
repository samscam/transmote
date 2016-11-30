//
//  TransmissionConnection.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 28/11/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Foundation

import Moya

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
        case failed(SessionError)
        case connecting
        case connected
    }
    
    var server: TransmissionServer {
        didSet{
            connect()
        }
    }
    
    var status: Status = .indeterminate {
        didSet{
            switch status {
            case .connected:
                self.startTimers()
            default:
                self.stopTimers()
            }
        }
    }
    
    var sessionId: String?
    
    var provider: MoyaProvider<TransmissionTarget>!
    
    var torrents: [Torrent] = []
    
    var timer: Timer?
    
    var updating = false
    
    init(server: TransmissionServer){
        self.server = server
        
        let endpointClosure = { (target: TransmissionTarget) -> Endpoint<TransmissionTarget> in
            
            // If we have no url then the provider ain't going to be no use...
            guard let serverURL = self.server.serverURL?.absoluteString else {
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
    }
    
    // Timers
    
    func startTimers(){
        timer = Timer(fire: Date(), interval: 10, repeats: true, block: { (timer) in
            self.updateSessionStats()
//            self.updateTorrents()
        })
    }
    
    func stopTimers(){
        timer?.invalidate()
        timer = nil
    }
    
    // Initial connection
    
    func connect(){
        self.status = .connecting
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
                    // All is well with the world
                    
                    // NO beware! if you point it at the wrong path it will try for a redirect to the web interface - we should check the payload

                    do {
                        let json = try moyaResponse.mapJSON() as! [String: Any]
                        if let result = json["result"] as? String, result == "success" {
                            self.status = .connected
                            print("Connected woo!")
                            print(json)
                            self.updateSessionStats()
                        } else {
                            print("looks like it isn't Transmission on the other end...")
                        }
                        
                    } catch {
                        print("Not JSON - we are probably hitting the web interface by mistake")
                    }
                case 404:
                    // The path was wrong probably
                    print("404 - wrong path")
                default:
                    // Something else happened - I wonder what it was
                    print("Oh dear - status code \(moyaResponse.statusCode)")
                    self.status = .failed(.unknownError)
                }
            case let .failure(error):
                print(error)
                self.status = .failed(.networkError(error))
            }
        }
    }
    
    
    func updateSessionStats(){
        self.provider.request(.stats){ result in
            switch result {
            case .success(let moyaResponse):
                do {
                    let json = try moyaResponse.mapJsonRpc()
                    let stats = SessionStats(JSON: json)
                    print(stats!)
                } catch {
                    print(error)
                }
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    
    
}
