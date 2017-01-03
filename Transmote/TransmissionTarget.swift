//
//  TransmissionTarget.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 27/11/2016.
//

import Foundation
import Moya

enum TransmissionTarget {
    case connect
    case stats
    case torrents
    case addTorrent(URL)
    case removeTorrents([Torrent])
    case deleteTorrents([Torrent])
}

extension TransmissionTarget: TargetType {

    // These will always be ignored
    public var baseURL: URL { return URL(string: "http://localhost/")! } // swiftlint:disable:this force_unwrapping
    public var path: String { return "/rpc/" }

    // This is JSON/RPC so it will always be POST
    public var method: Moya.Method { return .post }

    // And here's the fun part
    public var parameters: [String: Any]? {
        let method: String
        var arguments: [String:Any]?
        switch self {
        case .connect:
            method = "session-get"
        case .stats:
            method = "session-stats"
        case .addTorrent(let url):
            method = "torrent-add"
            arguments = ["filename": url.absoluteString]
        case .deleteTorrents(let torrents):
            method = "torrent-remove"
            arguments = ["ids": torrents.map { $0.id }, "delete-local-data": false ]
        case .removeTorrents(let torrents):
            method = "torrent-remove"
            arguments = ["ids": torrents.map { $0.id }, "delete-local-data": true ]
        case .torrents:
            method = "torrent-get"
            arguments = ["fields": ["id",
                                    "activityDate",
                                    "addedDate",
                                    "doneDate",
                                    "isFinished",
                                    "isStalled",
                                    "status",
                                    "name",
                                    "totalSize",
                                    "rateDownload",
                                    "rateUpload",
                                    "percentDone",
                                    "eta"]]
        }

        var payload: [String: Any] = ["method": method]
        if let arguments = arguments {
            payload["arguments"] = arguments
        }
        return payload
    }

    public var sampleData: Data {
        return "Just can't be bothered".data(using: String.Encoding.utf8)! // swiftlint:disable:this force_unwrapping
    }

    public var task: Task {
        return .request
    }
}
