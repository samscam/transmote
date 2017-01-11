//
//  MetadataManager.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 05/01/2017.
//

import Foundation

import RxSwift

import Moya
import RxMoya

class MetadataManager {

    let tmdbProvider = RxMoyaProvider<TMDBTarget>( plugins:[ NetworkLoggerPlugin() ])

    func metadata(for rawName: String) -> Observable<Metadata> {
        return Observable.just(DerivedMetadata(from: rawName))
    }

    // External metadata
    /*
    
     lazy var derivedMetadata: Observable<Metadata> = self.name.map {
     print("Deriving metadata for \($0)")
     return Metadata(from: $0)
     }.shareReplay(1).debug("derived metadata")
     
     lazy var bestName: Observable<String> = self.metadata.map { $0.name }
     
    lazy var externalMetadata: Observable<Metadata?> = {
        
        let response = self.derivedMetadata.flatMap({ derived -> Observable<Response> in
            
            switch derived.type {
            case .tv:
                return self.tmdbProvider.request(.tvShowMetadata(showName: derived.name))
            case .movie(let year):
                return self.tmdbProvider.request(.movieMetadata(movieName: derived.name, year: year))
            default:
                throw MetadataError.couldNotRequest
            }
        }).filterSuccessfulStatusCodes()
        
        let json = response.mapJSON()
        
        let metadata: Observable<Metadata?> = json.map { latestJSON in
            if let jsonDict = latestJSON as? [String:Any],
                let resultsArray = jsonDict["results"] as? [Any],
                let firstResult: [String: Any] = resultsArray.first as? [String : Any] {
                return Metadata(JSON: firstResult)
            }
            return nil
        }
        
        return metadata.catchError { _ in
            return Observable<Metadata?>.just(nil)
            }.shareReplay(1)
        
    }()
    
    lazy var metadata: Observable<Metadata> = Observable.combineLatest(self.derivedMetadata, self.externalMetadata) { derived, external in
        if var external = external {
            external.type = derived.type
            return external
        }
        return derived
        }.shareReplay(1)
    
    lazy var episodeMetadata: Observable<Episode?> = {
        let response: Observable<Response> = self.metadata
            .flatMap { metadata -> Observable<Response> in
                if let id = metadata.id {
                    switch metadata.type {
                    case .tv(let season, let episode):
                        if let season = season, let episode = episode {
                            return self.tmdbProvider.request(.tvShowDetails(showID: id, season: season, episode: episode))
                        }
                    default:
                        break
                    }
                }
                throw MetadataError.couldNotRequest
        }
        
        let episode = response.mapJSON().map { latestJSON -> Episode? in
            if let jsonDict = latestJSON as? [String: Any] {
                let ep = try? Episode(JSON: jsonDict)
                return ep
            }
            return nil
        }
        
        return episode.catchError { _ in
            return Observable<Episode?>.just(nil)
            }.shareReplay(1)
    }()
     
     
     lazy var image: Observable<NSImage?> = {
     let path: Observable<String?> = Observable.combineLatest(self.metadata, self.episodeMetadata) { overall, episode in
     if let episodeImage = episode?.stillPath {
     return episodeImage
     } else {
     return overall.posterPath
     }
     }
     
     let imageResponse = path.flatMapLatest { path -> Observable<Response> in
     if let path = path {
     return self.tmdbProvider.request(.image(path:path))
     } else {
     throw MetadataError.noImagePath
     }
     }
     
     return imageResponse.mapImage().shareReplay(1)
     }()

*/

}
