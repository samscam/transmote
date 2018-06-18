//
//  TransmissionServer.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//

import Foundation
import Cocoa

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

    var username: String? {
        return credential?.user
    }

    var password: String? {
        return credential?.password
    }

    func setUsername(_ username: String, password: String) {
        removeCredential()
        print("Setting credential")
        _credential = URLCredential(user: username, password: password, persistence: .permanent)
    }

    var protectionSpace: URLProtectionSpace {
        let proto: String = useTLS ? "https" : "http"
        return URLProtectionSpace(host: address, port: port, protocol: proto, realm: "Transmission", authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
    }

    private var _credential: URLCredential?
    var credential: URLCredential? {
        if _credential == nil {
            _credential = URLCredentialStorage.shared.defaultCredential(for: protectionSpace)
        }
        return _credential
    }

    func removeCredential() {
        if let cred = URLCredentialStorage.shared.defaultCredential(for: protectionSpace) {
            URLCredentialStorage.shared.remove(cred, for: protectionSpace)
        }
        _credential = nil
    }
}
