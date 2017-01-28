//
//  TMDBMetadataSpecialisations.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 27/01/2017.
//  Copyright © 2017 Sam Easterby-Smith. All rights reserved.
//

import Foundation
import ObjectMapper

struct Movie: Metadata, ImmutableMappable {

    var title: String
    var description: String

    var id: Int? // swiftlint:disable:this variable_name
    var imagePath: String?
    var year: Int?

    init(map: Map) throws {
        id = try map.value("id")
        title = try map.value("title")
        description = try map.value("tagline")
        imagePath = try? map.value("still_path")
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

    var id: Int? // swiftlint:disable:this variable_name

    var imagePath: String?

    init(map: Map) throws {
        id = try map.value("id")
        title = try map.value("name")
        imagePath = try? map.value("still_path")
    }

    mutating func mapping(map: Map) {

    }

    var type: TorrentMetadataType = .video
}

struct TVSeason: Metadata, ImmutableMappable {

    var title: String { return show.title }
    var description: String { return "Season \(season)" }

    var id: Int? // swiftlint:disable:this variable_name
    var name: String
    let season: Int
    var imagePath: String?

    var show: TVShow!

    init(map: Map) throws {
        id = try map.value("id")
        name = try map.value("name")
        season = try map.value("season_number")
        imagePath = try? map.value("poster_path")
    }

    mutating func mapping(map: Map) {

    }

    let type: TorrentMetadataType = .video
}

struct TVEpisode: Metadata, ImmutableMappable {

    var title: String { return show.title }
    var description: String { return episodeName }

    let id: Int? // swiftlint:disable:this variable_name
    let imagePath: String?
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
        imagePath = try? map.value("still_path")
    }

    mutating func mapping(map: Map) {

    }

    let type: TorrentMetadataType = .video
}
