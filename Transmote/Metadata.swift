//
//  Metadata.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 07/12/2016.
//

import Foundation
import ObjectMapper

enum TorrentMetadataType {
    case video
    case tvSeries
    case tvSeason(season: Int)
    case tvEpisode(season: Int, episode: Int, episodeName: String?)
    case movie(year: Int)
    case other
}

enum MetadataError: Swift.Error {
    case couldNotRequest
    case noImagePath
}

protocol Metadata {
    var id: Int? { get }  // swiftlint:disable:this variable_name
    var name: String { get }
    var type: TorrentMetadataType { get }
    var imagePath: String? { get }
}

struct DerivedMetadata: Metadata {

    var id: Int? // swiftlint:disable:this variable_name
    var name: String = ""
    var type: TorrentMetadataType = .other
    var imagePath: String?

    init(from rawName: String) {

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

        guard let result = regex.firstMatch(in: semiCleaned,
                                            options: [],
                                            range: NSRange(location: 0, length: semiCleaned.characters.count))
            else {
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
        if let season = season, let episode = episode {
            self.type = .tvEpisode(season: season, episode: episode, episodeName: nil)
        } else if let season = season {
            self.type = .tvSeason(season: season)
        } else if let year = year {
            self.type = .movie(year: year)
        }

        print("Raw name: \(rawName)")
        print("... converted to: \(self.name)")

    }

}

struct ExternalMetadata: Metadata, ImmutableMappable {

    var id: Int? // swiftlint:disable:this variable_name
    var name: String = ""
    var type: TorrentMetadataType = .other
    var imagePath: String?

    init(map: Map) throws {
        id = try map.value("id")
        name = try map.value("title")
        imagePath = try? map.value("poster_path")
    }

    mutating func mapping(map: Map) {
        id >>> map["id"]
        name >>> map["name"]
        name >>> map["title"]
        imagePath >>> map["poster_path"]
    }
}

struct EpisodeMetadata: Metadata, ImmutableMappable {
    let id: Int? // swiftlint:disable:this variable_name
    let imagePath: String?
    let season: Int
    let episode: Int
    let name: String

    init(map: Map) throws {
        id = try map.value("id")
        name = try map.value("name")
        season = try map.value("season_number")
        episode = try map.value("episode_number")
        imagePath = try? map.value("still_path")
    }

    mutating func mapping(map: Map) {
        id >>> map["id"]
        name >>> map["name"]
        season >>> map["season_number"]
        episode >>> map["episode_number"]
        imagePath >>> map["still_path"]
    }
    var type: TorrentMetadataType {
        return .tvEpisode(season: season, episode: episode, episodeName: name)
    }
}
