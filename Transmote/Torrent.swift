//
//  TRNTorrent.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//

import Foundation

enum TorrentStatus: Int, Codable, CustomStringConvertible {
    case stopped = 0
    case checkWait = 1
    case check = 2
    case downloadWait = 3
    case download = 4
    case seedWait = 5
    case seed = 6

    var description: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .checkWait:
            return "Waiting to check files"
        case .check:
            return  "Checking files"
        case .downloadWait:
            return  "Queued for download"
        case .download:
            return "Downloading"
        case .seedWait:
            return "Queued for seeding"
        case .seed:
            return "Seeding"
        }
    }

}

struct Torrent: Codable, Equatable, Hashable {

    let id: Int // swiftlint:disable:this variable_name
    let name: String
    let activityDate: Date?
    let addedDate: Date?
    let doneDate: Date?
    let isFinished: Bool = false
    let isStalled: Bool = false
    let eta: Date?
    let rateDownload: Int
    let rateUpload: Int
    let percentDone: Float
    let totalSize: Int
    let status: TorrentStatus

    var hashValue: Int { return id }

    static func == (lhs: Torrent, rhs: Torrent) -> Bool {
        return (lhs.id == rhs.id)
    }
}
