//
//  Moya-RPC.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 30/11/2016.
//

import Foundation
import Moya

public enum JSONRPCError: Swift.Error, CustomStringConvertible {
    case jsonParsingError(String)
    case errorResponse(String)

    public var description: String {
        switch self {

        case .jsonParsingError(let str):
            return "JSON parsing error:\n\(str)"
        case .errorResponse(let str):
            return "Server error:\n\(str)"
        }
    }
}

class JSONRPCProvider<Target: TargetType>: MoyaProvider<Target> {

    var sessionId: String?

    /// Injects the session id into the endpoint
    override func endpoint(_ token: Target) -> Endpoint {
        let endpoint = endpointClosure(token)
        if let sessionId = sessionId {
            return endpoint.adding(newHTTPHeaderFields: ["X-Transmission-Session-Id": sessionId])
        } else {
            return endpoint
        }
    }

    /// Catches 409 status codes, stores the sessionID, and retries the request
    @discardableResult
    override func request(_ target: Target, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, completion: @escaping Completion) -> Cancellable {
        return super.request(target,
                             callbackQueue: callbackQueue,
                             progress: progress,
                             completion: { result in
            switch result {
            case .success(let response):
                switch response.statusCode {
                case 409:
                    if let httpResponse = response.response,
                        let sessionId = httpResponse.allHeaderFields["X-Transmission-Session-Id"] as? String {
                        self.sessionId = sessionId
                        print("Got new session id: \(sessionId)")
                        // WARNING: We are discarding the inner cancellable - this is kinda bad...
                        _ = self.request(target, completion: completion)
                        return
                    }
                default:
                    break
                }
            case .failure:
                break
            }

            completion(result)

        })
    }
}

extension Response {
    @discardableResult
    func filterJsonRpcFailures() throws -> Response {
        guard let json = try self.mapJSON() as? [String: Any] else {
            throw JSONRPCError.jsonParsingError("Top level container not a dictionary")
        }

        guard let result = json["result"] as? String else {
            throw JSONRPCError.jsonParsingError("Missing or mis-typed result token")
        }

        guard result == "success" else {
            throw JSONRPCError.errorResponse(result)
        }

        guard json["arguments"] as? [String: Any] != nil else {
            throw JSONRPCError.jsonParsingError("Arguments missing or mis-typed in response")
        }

        return self
    }
}
