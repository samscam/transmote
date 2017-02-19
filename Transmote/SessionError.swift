//
//  SessionError.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 19/02/2017.
//

import Foundation

import Moya

public enum SessionError: Swift.Error, CustomStringConvertible {
    case noServerSet
    case needsAuthentication
    case networkError(Moya.Error)
    case badRpcPath
    case unexpectedStatusCode(Int)
    case unknownError(Swift.Error)
    case rpcError(JSONRPCError)

    public var description: String {
        switch self {
        case .noServerSet:
            return "Configure your server"
        case .needsAuthentication:
            return "Server requires authentication"
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
        case .unexpectedStatusCode(let statusCode):
            return "Unexpected status code: \(statusCode)"
        case .rpcError(let rpcError):
            return rpcError.description
        }
    }
}
