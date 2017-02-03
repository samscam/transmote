//
//  TransmissionServer.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//

import Foundation
import Cocoa
import ObjectMapper

struct TransmissionServer {

    var address: String
    var port: Int
    var rpcPath: String
    var useTLS: Bool

    var username: String?
    var password: String?

    init(address: String, port: Int? = nil, rpcPath: String? = nil, useTLS: Bool = false) {

        self.address = address
        self.port = port ?? 9_091
        self.rpcPath = rpcPath ?? "transmission/rpc"
        self.useTLS = useTLS

    }

    var serverURL: URL? {
        let scheme: String = useTLS ? "https" : "http"
        let theURL = URL(string: "\(scheme)://\(self.address):\(self.port)/\(self.rpcPath)")
        return theURL
    }

}

struct SessionStats: Mappable {
    var activeTorrentCount: Int!

    init?(map: Map) {

    }

    mutating func mapping(map: Map) {
        activeTorrentCount <- map["activeTorrentCount"]
    }

}
