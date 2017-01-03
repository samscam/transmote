//
//  Metadata.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 07/12/2016.
//

import Foundation
import ObjectMapper

enum TorrentMetadataType{
    case tv(season: Int?, episode: Int?)
    case movie(year: Int)
    case other
}

enum MetadataError: Swift.Error {
    case couldNotRequest
    case noImagePath
}

struct Metadata: Mappable {
    
    var id: Int?
    var name: String = ""
    var type: TorrentMetadataType = .other
    var posterPath: String?
    
    init(from rawName: String){
        
        self.name = rawName
        
        // Clean up dots, underscores
        
        // swiftlint:disable force_try
        
        var cleaner = try! NSRegularExpression(pattern: "[\\[\\]\\(\\)\\.+_-]", options: [])
        var semiCleaned = cleaner.stringByReplacingMatches(in: rawName, options: [], range: NSRange(location: 0, length: rawName.characters.count), withTemplate: " ")
        
        // Clean runs of whitespace
        cleaner = try! NSRegularExpression(pattern: "\\s+", options: .caseInsensitive)
        semiCleaned = cleaner.stringByReplacingMatches(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.characters.count), withTemplate: " ")
        
        // Clean references to DVD BDRIP and boxset and things
        cleaner = try! NSRegularExpression(pattern: "\\b(1080p|720p|x264|dts|aac|complete|boxset|extras|dvd\\w*?|br|bluray|bd\\w*?|(from \\w* \\w* \\w*))\\b", options: .caseInsensitive)
        semiCleaned = cleaner.stringByReplacingMatches(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.characters.count), withTemplate: " ")
        
        // Clean runs of whitespace
        cleaner = try! NSRegularExpression(pattern: "\\s+", options: .caseInsensitive)
        semiCleaned = cleaner.stringByReplacingMatches(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.characters.count), withTemplate: " ")
        
        self.name = semiCleaned
        
        // Figure out if we have an episode code or season or year or whatnot
        let pattern = "^(.+?)\\s*(?:\\W*(?:(\\b\\d{4}\\b)|(?:\\b(?:s\\s?)?(\\d+)\\W*(?:(?:ep|episode|[ex])\\s?(\\d+\\b))?)|(?:season\\s?(\\d+)))){1,2}"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        // swiftlint:enable force_try
        
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
        
        if season != nil || episode != nil {
            self.type = .tv(season: season, episode: episode)
        } else if year != nil {
            self.type = .movie(year: year!)
        }
        
        print("Raw name: \(rawName)")
        print("... converted to: \(self.name)")
        
    }
    
    init?(map: Map){
        
    }
    
    mutating func mapping(map: Map){
        id <- map["id"]
        name <- map["name"]
        name <- map["title"]
        posterPath <- map["poster_path"]
        
    }
    
    
}


struct Episode: ImmutableMappable {
    let id: Int
    let stillPath: String?
    let season: Int
    let episode: Int
    let name: String
    
    init(map: Map) throws{
        id = try map.value("id")
        name = try map.value("name")
        season = try map.value("season_number")
        episode = try map.value("episode_number")
        stillPath = try? map.value("still_path")
    }
    
    mutating func mapping(map: Map){
        id >>> map["id"]
        name >>> map["name"]
        season >>> map["season_number"]
        episode >>> map["episode_number"]
        stillPath >>> map["still_path"]
    }
}
