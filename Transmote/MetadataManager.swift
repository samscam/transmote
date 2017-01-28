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

class MetadataManager {

    let tmdbProvider = RxMoyaProvider<TMDBTarget>() // plugins:[ NetworkLoggerPlugin() ]
    var metadataStore: [String:Observable<Metadata>] = [:]

    let disposeBag = DisposeBag()

    func metadata(for rawName: String) -> Observable<Metadata> {
        if let retrieved = metadataStore[rawName] {
            return retrieved
        } else {
            let stream = metadataStream(for: rawName)
            metadataStore[rawName] = stream
            return stream
        }

    }

    func metadataStream(for rawName: String) -> Observable<Metadata> {
        let publishSubject = ReplaySubject<Metadata>.create(bufferSize: 1)

        let derived = DerivedMetadata(from: rawName)
        publishSubject.onNext(derived)

        if derived.year != nil {
            // movie
            tmdbProvider.request(.movieMetadata(movieName: derived.cleanedName, year: derived.year))
                .mapTMDB(.movie)
                .subscribe(onNext: { movie in
                    publishSubject.onNext(movie)
                }, onError: { error in
                    print(error)
                    // do nothing
                }).addDisposableTo(disposeBag)
        } else {
            // tv show
            tmdbProvider.request(.tvShowMetadata(showName: derived.cleanedName))
                .mapTMDB(.show)
                .flatMapLatest { show -> Observable<Metadata> in
                    if let show = show as? TVShow, let season = derived.season {
                        if let episode = derived.episode {
                            return self.tmdbProvider.request(.tvShowDetails(showID: show.id, season: season, episode: episode)).mapTMDB(.episode, show: show)
                        } else {
                            return self.tmdbProvider.request(.tvSeasonDetails(showID: show.id, season: season)).mapTMDB(.season, show: show)
                        }
                    } else {
                        return Observable.just(show)
                    }
                }
                .subscribe(onNext: { show in
                    publishSubject.onNext(show)
                }, onError: { error in
                    // do nothing
                    print(error)
                })

                .addDisposableTo(disposeBag)
        }
        // season

        // episode

        return publishSubject
    }
}

/*

class MungedMetadata {
    
    let derived: Observable<Metadata>
    let external: Observable<Metadata?>
    let episode: Observable<Metadata?>
    let tmdbProvider: RxMoyaProvider<TMDBTarget>

    init(rawName: String, tmdbProvider: RxMoyaProvider<TMDBTarget>) {

        self.tmdbProvider = tmdbProvider

        derived = Observable<Metadata>.just(DerivedMetadata(from:rawName)).shareReplay(1)

//        external = derived.flatMapLatest { derived -> Observable<Metadata?> in
//            var request: Observable<Response>
//            switch derived.type {
//            case .tvEpisode, .tvSeries, .tvSeason:
//                request = tmdbProvider.request(.tvShowMetadata(showName: derived.name))
//            case .movie(let year):
//                request = tmdbProvider.request(.movieMetadata(movieName: derived.name, year: year))
//            default:
//                throw(MetadataError.notWorthLookingUp)
//            }
//            return request.mapMetadata(preservingType:derived.type)
//        }
//        //.startWith(nil)
//        .catchErrorJustReturn(nil)
//        .shareReplay(1)

        let episodeRequest = external.flatMapLatest { metadata -> Observable<Response>  in
            guard let metadata = metadata else {
                throw(MetadataError.couldNotRequest)
            }
            if let id = metadata.id {
                switch metadata.type {
                case .tvEpisode:
                    if let season = metadata.season, let episode = metadata.episode {
                        return tmdbProvider.request(.tvShowDetails(showID: id, season: season, episode: episode))
                    }
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
*/
