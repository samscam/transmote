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

struct Torrent: Mappable {
    
    // Mappable variables
    var id: Int!
    var activityDate: Date?
    var addedDate: Date?
    var doneDate: Date?
    var isFinished: Bool?
    var eta: Date?
    var name: String?
    var rateDownload: Int?
    var rateUpload: Int?
    var percentDone: Double?
    var totalSize: Int?
    
    // Calculated variables
    
    lazy var derivedMetadata: Metadata? = {
        return Metadata(from: self.name!)
        }()
    
    init?(map: Map){
        
    }
    
    mutating func mapping(map: Map){
        id              <- map["id"]
        activityDate    <- (map["activityDate"], DateTransform())
        addedDate       <- (map["addedDate"], DateTransform())
        doneDate        <- (map["doneDate"], DateTransform())
        isFinished      <- map["isFinished"]
        eta             <- (map["eta"], DateTransform())
        name            <- map["name"]
        rateDownload    <- map["rateDownload"]
        rateUpload      <- map["rateUpload"]
        percentDone     <- map["percentDone"]
        totalSize       <- map["totalSize"]
        
    }
    
}

enum TorrentMetadataType{
    case tv(season: Int?,episode: Int?)
    case movie(year: Int)
    case other
}

struct Metadata {
    
    var name: String = ""
    var type: TorrentMetadataType = .other
    
    init?(from rawName: String){
        
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
        print("Semi cleaned name: \(semiCleaned)")
        
        self.name = semiCleaned
        
        // Figure out if we have an episode code or season or year or whatnot
        let pattern = "^(.+?)\\s*(?:\\W*(?:(\\b\\d{4}\\b)|(?:\\b(?:s\\s?\\s?)?(\\d+)(?:(?:ep|episode|[ex]){1}\\s?(\\d+\\b)))|(?:season\\s?(\\d+)))){1,2}"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        guard let result = regex.firstMatch(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.characters.count)) else {
        // If we can't match the regex then give up, returning the name as cleaned up as we have it
            return
        }
        
        let title = (semiCleaned as NSString).substring(with: result.rangeAt(1))
        
        print("Fully cleaned name: \(title)")
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
