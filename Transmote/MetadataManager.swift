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
            tmdbProvider.request(.movieSearch(movieName: derived.cleanedName, year: derived.year))
                .mapTMDB(.movie)
                .subscribe(onNext: { movie in
                    publishSubject.onNext(movie)
                }, onError: { error in
                    print(error)
                    // do nothing
                }).addDisposableTo(disposeBag)
        } else {
            // tv show
            tmdbProvider.request(.tvShowSearch(showName: derived.cleanedName))
                .mapTMDB(.show)
                .flatMapLatest { show -> Observable<Metadata> in
                    if let show = show as? TVShow, let season = derived.season {
                        if let episode = derived.episode {
                            // episode
                            return self.tmdbProvider.request(.tvShowDetails(showID: show.id, season: season, episode: episode)).mapTMDB(.episode, show: show)
                        } else {
                            // season
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

        return publishSubject
    }
}
