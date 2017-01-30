//
//  TMDBMetadataSpecialisations.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 27/01/2017.
//

import Foundation
import ObjectMapper

struct Movie: Metadata, ImmutableMappable {

    var title: String
    var description: String {
        if let tagline = tagline {
            return "\(tagline)"
        } else if let year = year {
            return "\(year)"
        }
        return "Hello!"
    }

    var id: Int // swiftlint:disable:this variable_name
    var imagePath: String?
    var year: Int? {
        if let releaseDate = releaseDate {
            return Calendar.autoupdatingCurrent.component(.year, from: releaseDate)
        } else {
            return nil
        }
    }
    var releaseDate: Date?
    var tagline: String?

    init(map: Map) throws {
        id = try map.value("id")
        title = try map.value("title")
        tagline = try? map.value("tagline")
        imagePath = try? map.value("backdrop_path")
        releaseDate = try? map.value("release_date", using: SensibleDateTransform())
    }

    mutating func mapping(map: Map) {
        id >>> map["id"]
        title >>> map["title"]
        description >>> map["tagline"]
        imagePath >>> map["poster_path"]
    }

    var type: TorrentMetadataType = .video
}

struct TVShow: Metadata, ImmutableMappable {

    var title: String
    var description: String { return "" }

    var id: Int // swiftlint:disable:this variable_name

    var imagePath: String?

    init(map: Map) throws {
        id = try map.value("id")
        title = try map.value("name")
        imagePath = try? map.value("backdrop_path")
    }

    mutating func mapping(map: Map) {

    }

    var type: TorrentMetadataType = .video
}

struct TVSeason: Metadata, ImmutableMappable {

    var title: String { return show?.title ?? "" }
    var description: String { return "Season \(season)" }

    var id: Int // swiftlint:disable:this variable_name
    var name: String
    let season: Int
    var imagePath: String? {
        if let _imagePath = _imagePath {
            return _imagePath
        } else {
            return show?.imagePath
        }
    }
    private var _imagePath: String?

    var show: TVShow?

    init(map: Map) throws {
        id = try map.value("id")
        name = try map.value("name")
        season = try map.value("season_number")
        _imagePath = try? map.value("poster_path")
    }

    mutating func mapping(map: Map) {

    }

    let type: TorrentMetadataType = .video
}

struct TVEpisode: Metadata, ImmutableMappable {

    var title: String { return show.title }
    var description: String {
        return "Season \(season) • Episode \(episode)\n\(episodeName)"
    }

    let id: Int // swiftlint:disable:this variable_name
    var imagePath: String? {
        if let _imagePath = _imagePath {
            return _imagePath
        } else {
            return show.imagePath
        }
    }
    private var _imagePath: String?
    let season: Int
    let episode: Int
    var year: Int?
    let episodeName: String

    var show: TVShow!

    init(map: Map) throws {
        id = try map.value("id")
        episodeName = try map.value("name")
        season = try map.value("season_number")
        episode = try map.value("episode_number")
        _imagePath = try? map.value("still_path")
    }

    mutating func mapping(map: Map) {

    }

    let type: TorrentMetadataType = .video
}

open class SensibleDateTransform: TransformType {
    public typealias Object = Date
    public typealias JSON = String

    let dateFormatter = DateFormatter()

    public init() {
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "YYYY-MM-d"
    }

    open func transformFromJSON(_ value: Any?) -> Date? {

        if let timeStr = value as? String {
            return dateFormatter.date(from: timeStr)
        }

        return nil
    }

    open func transformToJSON(_ value: Date?) -> String? {
        if let date = value {
            return dateFormatter.string(from: date)
        }
        return nil
    }
}
