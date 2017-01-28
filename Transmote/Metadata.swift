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

extension Metadata {

//    var image: Observable<NSImage?> {
//        return self.tmdbProvider.request(.image(path:imagePath)).mapImage()
//    }

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
            var external = try TVShow(JSON: firstResult)
            external.type = preservingType
            return external
        } else {
            throw(MetadataError.couldNotRequest)
        }
    }
}
