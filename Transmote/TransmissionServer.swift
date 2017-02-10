//
//  TransmissionServer.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//

import Foundation
import Cocoa
import ObjectMapper

class TransmissionServer {

    var address: String
    var port: Int
    var rpcPath: String
    var useTLS: Bool

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

/// Extension adding keychain stuff
extension TransmissionServer {

    var username: String? {
        return credential?.user
    }
    var password: String? {
        return credential?.password
    }

    func setUsername(_ username: String, password: String) {
        removeCredential()
        print("Setting credential")
        let cred = URLCredential(user: username, password: password, persistence: .permanent)
        URLCredentialStorage.shared.setDefaultCredential(cred, for: protectionSpace)
    }

    var protectionSpace: URLProtectionSpace {
        let proto: String = useTLS ? "https" : "http"
        return URLProtectionSpace(host: address, port: port, protocol: proto, realm: rpcPath, authenticationMethod: nil)
    }

    var credential: URLCredential? {
        return URLCredentialStorage.shared.defaultCredential(for: protectionSpace)
    }

    func removeCredential() {
        if let credential = credential {
            print("Removing credential")
            URLCredentialStorage.shared.remove(credential, for: protectionSpace)
        }
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
