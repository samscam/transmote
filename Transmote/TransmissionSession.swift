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
class TransmissionSession{
    
    enum Status{
        case indeterminate
        case unreachable
        case authFailed
        case connecting
        case connected
    }
    
    var server: TransmissionServer {
        didSet{
            connect()
        }
    }
    
    var status: Status = .indeterminate
    
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
                    self.status = .connected
                    let json = try? moyaResponse.mapJSON()
                    print(json!)
                    self.getSessionStats()
                    print("Connected woo!")
                case 404:
                    // The path was wrong probably
                    print("404 - wrong path")
                default:
                    // Something else happened - I wonder what it was
                    print("Oh dear - status code \(moyaResponse.statusCode)")
                    self.status = .authFailed
                }
            case let .failure(error):
                print(error)
                self.status = .unreachable
            }
        }
    }
    
    func getSessionStats(){
        self.provider.request(.stats){ result in
            switch result {
            case .success(let moyaResponse):
                if let json = try? moyaResponse.mapJSON() as! [String: Any],
                let args = json["dogs"] as? [String: Any] {
                    let stats = SessionStats(JSON: args)
                    print(stats!)
                }
            case .failure(let error):
                break
            }
        }
    }
    
    
    
}
