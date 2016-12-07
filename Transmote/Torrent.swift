////
////  TRNTorrent.h
////  Transmote
////
////  Created by Sam Easterby-Smith on 08/02/2014.
////  Copyright (c) 2014 Spotlight Kid. All rights reserved.
////
//

import Foundation
import AppKit
import ObjectMapper
import RxSwift
import RxCocoa


enum TorrentStatus: Int, CustomStringConvertible{
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
    
    var color: NSColor {
        switch self {
        case .stopped:
            return NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        case .checkWait:
            return NSColor(red: 1, green: 0.2, blue: 0, alpha: 1)
        case .check:
            return NSColor(red: 1, green: 0.5, blue: 0, alpha: 1)
        case .downloadWait:
            return NSColor(red: 0, green: 0.5, blue: 0, alpha: 1)
        case .download:
            return NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1)
           
        case .seedWait:
            return NSColor(red: 0, green: 0.5, blue: 0.5, alpha: 1)
        case .seed:
            return NSColor(red: 0, green: 0.8, blue: 0, alpha: 1)
        }
    }
}

class Torrent: Mappable, Equatable, Hashable {
    
    // Mappable variables
    var id: Int!
    
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
    
    private var __name: String {
        get{ return _name.value }
        set{ if newValue != __name { _name.value = newValue } }
    }
    private let _name = Variable<String>("")
    var name: Observable<String> { return _name.asObservable() }
    
    private let _rateDownload = Variable<Int>(0)
    var rateDownload: Observable<Int> { return _rateDownload.asObservable() }
    
    private let _rateUpload = Variable<Int>(0)
    var rateUpload: Observable<Int> { return _rateUpload.asObservable() }
    
    private let _percentDone = Variable<Double>(0)
    var percentDone: Observable<Double> { return _percentDone.asObservable() }
    
    private let _totalSize = Variable<Int>(0)
    var totalSize: Observable<Int> { return _totalSize.asObservable() }
    
    private let _rawStatus = Variable<Int>(0)
    var rawStatus: Observable<Int> { return _rawStatus.asObservable() }
    
    
    // Calculated variables
    
    var derivedMetadata: Observable<Metadata> { return name.map{ return Metadata(from: $0) } }
    
    var bestName: Observable<String> { return derivedMetadata.map{ $0.name } }
    
    
    var status: Observable<TorrentStatus> { return self.rawStatus.map{ rawValue in
        return TorrentStatus(rawValue: rawValue)!
        }
    }
    
    // Initialisation and parsing
    
    required init?(map: Map){
        
    }
    
    func mapping(map: Map){
        id        <- map["id"]
        _activityDate.value    <- (map["activityDate"], DateTransform())
        _addedDate.value       <- (map["addedDate"], DateTransform())
        _doneDate.value        <- (map["doneDate"], DateTransform())
        _isFinished.value      <- map["isFinished"]
        _isStalled.value       <- map["isStalled"]
        _eta.value             <- (map["eta"], DateTransform())
        __name            <- map["name"]
        _rateDownload.value    <- map["rateDownload"]
        _rateUpload.value      <- map["rateUpload"]
        _percentDone.value     <- map["percentDone"]
        _totalSize.value       <- map["totalSize"]
        _rawStatus.value       <- map["status"]
        
    }
    
    func update(JSON:[String: Any]) -> Torrent {
        return Mapper<Torrent>().map(JSON: JSON, toObject: self)
    }
    
    var hashValue: Int { return id! }
}




func == (lhs: Torrent, rhs: Torrent) -> Bool {
    return (lhs.id! == rhs.id!)
}


