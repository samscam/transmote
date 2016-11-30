//
//  Moya-RPC.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 30/11/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Foundation
import Moya

extension Response {
    
    func catchSessionId() throws -> Response {
        return self
    }
    
    func mapJsonRpc() throws -> [String: Any] {

        let json = try self.mapJSON() as! [String: Any]
        if let result = json["result"] as? String {
            if result == "success" {
                return json["arguments"] as! [String: Any]
            } else {
                throw SessionError.serverError(result)
            }
        } else {
            throw SessionError.badRpcPath
        }

    }
}
