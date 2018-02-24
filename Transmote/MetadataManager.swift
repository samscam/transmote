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

    let tmdbProvider = MoyaProvider<TMDBTarget>() // plugins:[ NetworkLoggerPlugin() ]
    var metadataStore: [String: Observable<Metadata>] = [:]

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

        switch derived.type {
        case .television:
            tmdbProvider.rx.request(.tvShowSearch(showName: derived.cleanedName))
                .mapTMDB(.show).asObservable()
                .flatMapLatest { show -> Observable<Metadata> in
                    if let show = show as? TVShow, let season = derived.season {
                        if let episode = derived.episode {
                            // episode
                            return self.tmdbProvider.rx.request(.tvShowDetails(showID: show.id, season: season, episode: episode)).mapTMDB(.episode, show: show).asObservable()
                        } else {
                            // season
                            return self.tmdbProvider.rx.request(.tvSeasonDetails(showID: show.id, season: season)).mapTMDB(.season, show: show).asObservable()
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

                .disposed(by: disposeBag)
        case .movie:
            tmdbProvider.rx.request(.movieSearch(movieName: derived.cleanedName, year: derived.year))
                .mapTMDB(.movie)
                .asObservable()
                .subscribe(onNext: { movie in
                    publishSubject.onNext(movie)
                }, onError: { error in
                    print(error)
                    // do nothing
                }).disposed(by: disposeBag)

        default:
            break
        }

        return publishSubject
    }
}
