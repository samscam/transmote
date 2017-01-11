//
//  TRNTorrent.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//

import Foundation
import AppKit
import ObjectMapper
import RxSwift
import Moya
import RxMoya

enum TorrentStatus: Int, CustomStringConvertible {
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

class Torrent: Mappable, Equatable, Hashable {

    // MARK: - Mappable variables
    var id: Int! // swiftlint:disable:this variable_name

    // Slightly funny arrangement here so that the Observable only changes when the value actually changes

    private var __name: String { // swiftlint:disable:this variable_name
        get { return _name.value }
        set {

            if newValue != __name {
                print("Name set to \(newValue)")
                _name.value = newValue
            } }
    }
    private let _name = Variable<String>("")
    var name: Observable<String> { return _name.asObservable() }

    // The rest is more straightforward

    private let _activityDate = Variable<Date?>(nil)
    var activityDate: Observable<Date?> { return _activityDate.asObservable() }

    private let _addedDate = Variable<Date?>(nil)
    var addedDate: Observable<Date?> { return _addedDate.asObservable() }

    private let _doneDate = Variable<Date?>(nil)
    var doneDate: Observable<Date?> { return _doneDate.asObservable() }

    private let _isFinished = Variable<Bool>(false)
    var isFinished: Observable<Bool> { return _isFinished.asObservable() }

    private let _isStalled = Variable<Bool>(false)
    var isStalled: Observable<Bool> { return _isStalled.asObservable() }

    private let _eta = Variable<Date?>(nil)
    var eta: Observable<Date?> { return _eta.asObservable() }

    private let _rateDownload = Variable<Int>(0)
    var rateDownload: Observable<Int> { return _rateDownload.asObservable() }

    private let _rateUpload = Variable<Int>(0)
    var rateUpload: Observable<Int> { return _rateUpload.asObservable() }

    private let _percentDone = Variable<Float>(0)
    var percentDone: Observable<Float> { return _percentDone.asObservable() }

    private let _totalSize = Variable<Int>(0)
    var totalSize: Observable<Int> { return _totalSize.asObservable() }

    private let _rawStatus = Variable<Int>(0)
    var rawStatus: Observable<Int> { return _rawStatus.asObservable() }

    // MARK: - Initialisation and parsing

    required init?(map: Map) {

    }

    func mapping(map: Map) {
        id <- map["id"]
        __name <- map["name"]
        _activityDate.value <- (map["activityDate"], DateTransform())
        _addedDate.value <- (map["addedDate"], DateTransform())
        _doneDate.value <- (map["doneDate"], DateTransform())
        _isFinished.value <- map["isFinished"]
        _isStalled.value <- map["isStalled"]
        _eta.value <- (map["eta"], DateTransform())
        _rateDownload.value <- map["rateDownload"]
        _rateUpload.value <- map["rateUpload"]
        _percentDone.value <- map["percentDone"]
        _totalSize.value <- map["totalSize"]
        _rawStatus.value <- map["status"]

    }

    func update(JSON: [String: Any]) -> Torrent {
        return Mapper<Torrent>().map(JSON: JSON, toObject: self)
    }

    // MARK: - Calculated variables

    lazy var status: Observable<TorrentStatus> = self.rawStatus.map { rawValue in
        guard let statusEnum = TorrentStatus(rawValue: rawValue) else {
            return TorrentStatus.stopped
        }
        return statusEnum
    }

    // Hashable

    var hashValue: Int { return id }
}

func == (lhs: Torrent, rhs: Torrent) -> Bool {
    return (lhs.id == rhs.id)
}
