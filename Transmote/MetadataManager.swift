//
//  MetadataManager.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 05/01/2017.
//

import Foundation

import RxSwift
import AppKit

import Moya
import RxMoya

enum MetadataError: Swift.Error {
    case notWorthLookingUp
    case couldNotRequest
    case itemNotFound
    case noImagePath
}

class MetadataManager {

    let tmdbProvider = RxMoyaProvider<TMDBTarget>() // plugins:[ NetworkLoggerPlugin() ]
    var metadataStore: [String:MungedMetadata] = [:]

    func metadata(for rawName: String) -> MungedMetadata {
        if let retrieved = metadataStore[rawName] {
            return retrieved
        } else {
            let munged = MungedMetadata(rawName: rawName, tmdbProvider: tmdbProvider)
            metadataStore[rawName] = munged
            return munged
        }

    }
}

class MungedMetadata {

    let derived: Observable<Metadata>
    let external: Observable<Metadata?>
    let episode: Observable<Metadata?>
    let tmdbProvider: RxMoyaProvider<TMDBTarget>

    init(rawName: String, tmdbProvider: RxMoyaProvider<TMDBTarget>) {

        self.tmdbProvider = tmdbProvider

        derived = Observable<Metadata>.just(DerivedMetadata(from:rawName)).shareReplay(1)

        external = derived.flatMapLatest { derived -> Observable<Metadata?> in
            var request: Observable<Response>
            switch derived.type {
            case .tvEpisode, .tvSeries, .tvSeason:
                request = tmdbProvider.request(.tvShowMetadata(showName: derived.name))
            case .movie(let year):
                request = tmdbProvider.request(.movieMetadata(movieName: derived.name, year: year))
            default:
                throw(MetadataError.notWorthLookingUp)
            }
            return request.mapMetadata(preservingType:derived.type)
        }
        //.startWith(nil)
        .catchErrorJustReturn(nil)
        .shareReplay(1)

        let episodeRequest = external.flatMapLatest { metadata -> Observable<Response>  in
            guard let metadata = metadata else {
                throw(MetadataError.couldNotRequest)
            }
            if let id = metadata.id {
                switch metadata.type {
                case .tvEpisode(let season, let episode, _):

                        return tmdbProvider.request(.tvShowDetails(showID: id, season: season, episode: episode))

                default:
                    break
                }
            }
            throw(MetadataError.couldNotRequest)
        }

        episode = episodeRequest.mapJSON().map { latestJSON -> EpisodeMetadata in
            if let jsonDict = latestJSON as? [String: Any] {
                return try EpisodeMetadata(JSON: jsonDict)
            }
            throw(MetadataError.couldNotRequest)
        }
        //.startWith(nil)
        .catchErrorJustReturn(nil)
        .shareReplay(1)

    }

    lazy var combo: Observable<Metadata> = Observable.combineLatest(self.derived, self.external) { derived, external in
        if let external = external {
            return external
        } else {
            return derived
        }
    }

    lazy var name: Observable<String> = self.combo.map { $0.name }

    lazy var bigCombo: Observable<Metadata> = Observable
        .combineLatest(self.combo, self.episode) { combo, episode in
            if let episode = episode {
                return episode
            } else {
                return combo
            }
        }
        .debug()
        .shareReplay(1)

    lazy var type: Observable<TorrentMetadataType> = self.bigCombo.map { $0.type }

    lazy var image: Observable<NSImage?> = {
        let path: Observable<String?> = self.bigCombo.map { $0.imagePath }

        let imageResponse = path.flatMapLatest { path -> Observable<NSImage?> in
            if let path = path {
                return self.tmdbProvider.request(.image(path:path)).mapImage()
            } else {
                return Observable<NSImage?>.just(nil)
            }
        }

        return imageResponse.shareReplay(1)
    }()

}

extension ObservableType where E == Response {
    func mapMetadata(preservingType: TorrentMetadataType) -> Observable<Metadata?> {
        return flatMap { response -> Observable<Metadata?> in
            return Observable.just(try response.mapMetadata(preservingType: preservingType))
        }
    }
}
extension Response {
    func mapMetadata(preservingType: TorrentMetadataType) throws -> Metadata? {

        let json = try self.mapJSON()
        if let jsonDict = json as? [String:Any],
            let resultsArray = jsonDict["results"] as? [Any],
            let firstResult: [String: Any] = resultsArray.first as? [String : Any] {
            var external = try ExternalMetadata(JSON: firstResult)
            external.type = preservingType
            return external
        } else {
            throw(MetadataError.couldNotRequest)
        }
    }
}
