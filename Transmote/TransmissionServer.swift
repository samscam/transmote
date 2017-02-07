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

    var username: String?
    var password: String? {
        didSet {
            if password != nil {
                needsCredentialStorage = true
            }
        }
    }

    var needsCredentialStorage: Bool = false

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

    var protectionSpace: URLProtectionSpace {
        let proto: String = useTLS ? "https" : "http"
        return URLProtectionSpace(host: address, port: port, protocol: proto, realm: nil, authenticationMethod: nil)
    }

    var credential: URLCredential? {
        if let username = self.username, let password = self.password {
            return URLCredential(user: username, password: password, persistence: .permanent)
        } else {
            return self.storedCredential
        }
    }

    var storedCredential: URLCredential? {
        guard let username = self.username else {
            return nil
        }
        let credentials = URLCredentialStorage.shared.credentials(for: protectionSpace)
        return credentials?[username]
    }

    func storeCredentialIfNeeded() {
        if needsCredentialStorage {
            if let credential = credential {
                URLCredentialStorage.shared.set(credential, for: protectionSpace)
                needsCredentialStorage = false
                password = nil
            }
        }
    }

    func removeCredential() {
        if let credential = credential {
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
