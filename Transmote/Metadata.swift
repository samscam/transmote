//
//  Metadata.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 07/12/2016.
//

import Foundation
import RxSwift
import Moya
import AppKit

enum TorrentMetadataType {
    case video
    case book
    case software
    case other
}

protocol Metadata {
    var title: String { get }
    var description: String { get }
    var type: TorrentMetadataType { get }
    var imagePath: String? { get }
}

enum MetadataError: Swift.Error {
    case notWorthLookingUp
    case couldNotRequest
    case itemNotFound
    case noImagePath
}

enum TMDBType {
    case show
    case season
    case episode
    case movie
}

extension ObservableType where E == Response {
    func mapTMDB(_ type: TMDBType, show: TVShow? = nil) -> Observable<Metadata> {
        return flatMap { response -> Observable<Metadata> in
            return Observable.just(try response.mapTMDB(type, show: show))
        }
    }
}

extension Response {
    func mapTMDB(_ type: TMDBType, show: TVShow? = nil) throws -> Metadata {

        let json = try self.mapJSON()

        if let jsonDict = json as? [String:Any] {
            switch type {
            case .movie, .show:
                if let resultsArray = jsonDict["results"] as? [Any],
                let firstResult: [String: Any] = resultsArray.first as? [String : Any] {

                    switch type {
                    case .show:
                        return try TVShow(JSON: firstResult)
                    case .movie:
                        return try Movie(JSON: firstResult)
                    default:
                        break
                    }
                }
            case .season:
                var season = try TVSeason(JSON: jsonDict)
                season.show = show
                return season
            case .episode:
                var episode = try TVEpisode(JSON: jsonDict)
                episode.show = show
                return episode
            }

        }

        throw(MetadataError.couldNotRequest)
    }
}
