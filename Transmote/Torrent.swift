////
////  TRNTorrent.h
////  Transmote
////
////  Created by Sam Easterby-Smith on 08/02/2014.
////  Copyright (c) 2014 Spotlight Kid. All rights reserved.
////
//

import Foundation
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
        _name.value            <- map["name"]
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



enum TorrentMetadataType{
    case tv(season: Int?,episode: Int?)
    case movie(year: Int)
    case other
}

struct Metadata {
    
    var name: String = ""
    var type: TorrentMetadataType = .other
    
    init(from rawName: String){
        
        self.name = rawName
        
        // Clean up dots, underscores
        var cleaner = try! NSRegularExpression(pattern: "[\\[\\]\\(\\)\\.+_-]", options: [])
        var semiCleaned = cleaner.stringByReplacingMatches(in: rawName, options: [], range: NSRange(location: 0, length: rawName.characters.count), withTemplate: " ")
        
        // Clean references to DVD BDRIP and boxset and things
        cleaner = try! NSRegularExpression(pattern: "\\b(1080p|720p|x264|dts|aac|complete|boxset|extras|dvd\\w*?|br|bluray|bd\\w*?)\\b", options: .caseInsensitive)
        semiCleaned = cleaner.stringByReplacingMatches(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.characters.count), withTemplate: " ")
        
        // Clean runs of whitespace
        cleaner = try! NSRegularExpression(pattern: "\\s+", options: .caseInsensitive)
        semiCleaned = cleaner.stringByReplacingMatches(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.characters.count), withTemplate: " ")
        
        self.name = semiCleaned
        
        // Figure out if we have an episode code or season or year or whatnot
        let pattern = "^(.+?)\\s*(?:\\W*(?:(\\b\\d{4}\\b)|(?:\\b(?:s\\s?\\s?)?(\\d+)(?:(?:ep|episode|[ex]){1}\\s?(\\d+\\b)))|(?:season\\s?(\\d+)))){1,2}"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        guard let result = regex.firstMatch(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.characters.count)) else {
        // If we can't match the regex then give up, returning the name as cleaned up as we have it
            return
        }
        
        let title = (semiCleaned as NSString).substring(with: result.rangeAt(1))

        self.name = title
        
        var year: Int?
        if !NSEqualRanges(result.rangeAt(2), NSRange(location: NSNotFound, length: 0)) {
            year = Int((semiCleaned as NSString).substring(with: result.rangeAt(2)))
        }
        
        var season: Int?
        if !NSEqualRanges(result.rangeAt(3), NSRange(location: NSNotFound, length: 0)) {
            season = Int((semiCleaned as NSString).substring(with: result.rangeAt(3)))
        } else if !NSEqualRanges(result.rangeAt(5), NSRange(location: NSNotFound, length: 0)) {
            season = Int((semiCleaned as NSString).substring(with: result.rangeAt(5)))
        }
        
        var episode: Int?
        if !NSEqualRanges(result.rangeAt(4), NSRange(location: NSNotFound, length: 0)) {
            episode = Int((semiCleaned as NSString).substring(with: result.rangeAt(4)))
        }
        
        if (season != nil || episode != nil) {
            self.type = .tv(season: season, episode: episode)
        } else if (year != nil) {
            self.type = .movie(year: year!)
        }
        
        print("Raw name: \(rawName)")
        print("... converted to: \(self.name)")
        
        
    }

}

//    private(set) var id = ""
//    private(set) var name = ""
//    var bestName: String {
//        if bestName {
//                return bestName
//            }
//            if cleanedName {
//                return cleanedName
//            }
//            return name
//    }
//    private(set) var poster: NSImage!
//    private(set) var percentDone: Int!
//    private(set) var rateDownload: Int!
//    private(set) var eta: Date!
//    private(set) var ulProgress: Int!
//    private(set) var rateUpload: Int!
//    private(set) var totalSize: Int!
//    weak private(set) var server: TRNServer?
//
//    convenience init(server: TRNServer) {
//        if (super.init()) {
//            self.server = server
//        }
//    }
//
//    func importJSONData(_ data: [AnyHashable: Any]) {
//        for thisKey: String in data {
//            var thisVal = (data.value(forKey: thisKey) as! String)
//                        do {
//                if (thisKey == "eta") {
//                    self.eta = Date(timeIntervalSinceNow: CDouble(thisVal))
//                }
//                else {
//                    self[thisKey] = thisVal
//                }
//            }             catch let exception {
//                print("Did not set \(thisKey) to \(thisVal)")
//            }
//        }
//    }
//
//
//    convenience init() {
//        assert(false)
//        return nil
//    }
//
//    override func setName(_ name: String) {
//        if (name == name) {
//            return
//        }
//        self.willChangeValue(forKey: "name")
//        self.name = name
//        self.didChangeValue(forKey: "name")
//        if name != "" {
//            // Presume it is new and clean up name
//            self.cleanName()
//            // And then fetch some metadata
//            self.fetchMetadata()
//        }
//    }
//
//    func setCleanedName(_ cleanedName: String) {
//        if (cleanedName == cleanedName) {
//            return
//        }
//        self.willChangeValue(forKey: "cleanedName")
//        self.willChangeValue(forKey: "bestName")
//        self.cleanedName = cleanedName
//        self.didChangeValue(forKey: "cleanedName")
//        self.didChangeValue(forKey: "bestName")
//    }
//

//
//    func fetchMetadata() {
//            // Assume if we have a Season or Episode code that it's TV
//        var client = TRNTheMovieDBClient()
//        if self.season {
//            client.fetchMetadata(forTVShowNamed: self.cleanedName, year: self.year, onCompletion: {(_ data: [AnyHashable: Any]) -> Void in
//                if !data.isEmpty {
//                    self.metadata() = data
//                    self.bestName = (data.value(forKey: "title") as! String)
//                    var showID = (data.value(forKey: "id") as! String)
//                    if self.episode && self.season {
//                        client.fetchDetailsForTVShow(withID: showID, season: self.season, episode: self.episode, onCompletion: {(_ res: [AnyHashable: Any]) -> Void in
//                            // somethign
//                            self.episodeTitle = (res.value(forKey: "name") as! String)
//                            var posterPath = (res.value(forKey: "still_path") as! String)
//                            client.fetchImage(atPath: posterPath, onCompletion: {(_ image: NSImage) -> Void in
//                                self.poster = image
//                            })
//                        })
//                    }
//                    else {
//                        var posterPath = (data.value(forKey: "poster_path") as! String)
//                        client.fetchImage(atPath: posterPath, onCompletion: {(_ image: NSImage) -> Void in
//                            self.poster = image
//                        })
//                    }
//                }
//            })
//        }
//        else {
//            // Otherwise assume that it's a movie
//            client.fetchMetadata(forMovieNamed: self.cleanedName, year: self.year, onCompletion: {(_ data: [AnyHashable: Any]) -> Void in
//                if !data.isEmpty {
//                    self.metadata() = data
//                    self.bestName = (data.value(forKey: "title") as! String)
//                    var posterPath = (data.value(forKey: "poster_path") as! String)
//                    client.fetchImage(atPath: posterPath, onCompletion: {(_ image: NSImage) -> Void in
//                        self.poster = image
//                    })
//                }
//            })
//        }
//    }
//
//    var id = ""
//    var name: String {
//        get {
//            // TODO: add getter implementation
//        }
//        set(name) {
//            if (name == name) {
//                return
//            }
//            self.willChangeValue(forKey: "name")
//            self.name = name
//            self.didChangeValue(forKey: "name")
//            if name != "" {
//                // Presume it is new and clean up name
//                self.cleanName()
//                // And then fetch some metadata
//                self.fetchMetadata()
//            }
//        }
//    }
//    var cleanedName: String {
//        get {
//            // TODO: add getter implementation
//        }
//        set(cleanedName) {
//            if (cleanedName == cleanedName) {
//                return
//            }
//            self.willChangeValue(forKey: "cleanedName")
//            self.willChangeValue(forKey: "bestName")
//            self.cleanedName = cleanedName
//            self.didChangeValue(forKey: "cleanedName")
//            self.didChangeValue(forKey: "bestName")
//        }
//    }
//    var bestName: String {
//        if bestName != "" {
//                return bestName
//            }
//            if cleanedName != "" {
//                return cleanedName
//            }
//            return name
//    }
//    var year = ""
//    var season: Int!
//    var episode: Int!
//    var episodeTitle = ""
//    var percentDone: Int!
//    var rateDownload: Int!
//    var eta: Date!
//    var ulProgress: Int!
//    var rateUpload: Int!
//    var totalSize: Int!
//    var metadata = [AnyHashable: Any]()
//    var poster: NSImage!
//    weak var server: TRNServer?
//}
////
////  TRNTorrent.m
////  Transmote
////
////  Created by Sam Easterby-Smith on 08/02/2014.
////  Copyright (c) 2014 Spotlight Kid. All rights reserved.
////
