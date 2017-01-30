//
//  TorrentViewModel.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 04/01/2017.
//

import Foundation
import RxSwift
import RxCocoa

#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

#if os(iOS) || os(tvOS)
    typealias Image = UIImage
#elseif os(OSX)
    typealias Image = NSImage
#endif

class TorrentViewModel: Equatable {

    let torrent: Torrent

    private let metadataManager: MetadataManager
    private let torrentMetadata: Observable<Metadata>

    init(torrent: Torrent, metadataManager: MetadataManager) {
        self.torrent = torrent
        self.metadataManager = metadataManager

        torrentMetadata = torrent.name.flatMapLatest { metadataManager.metadata(for: $0) }

        title = torrentMetadata.map { $0.title }
        subtitle = torrentMetadata.map { $0.description }

        let imageObs = torrentMetadata.map { $0.imagePath }.flatMapLatest { imagePath -> Observable<Image?> in
            if let imagePath = imagePath {
                return metadataManager.tmdbProvider.request(.image(path: imagePath)).mapImage()
            } else {
                return Observable<Image?>.just(nil)
            }

        }

        imageContentMode = imageObs.catchErrorJustReturn(nil).map { image in
            if let _ = image {
                return ContentMode.scaleAspectFill
            } else {
                return ContentMode.center
            }
        }

        image = imageObs
            .map {
                if $0 == nil {
                    return #imageLiteral(resourceName: "Magnet")
                } else {
                    return $0
                }
            }
            .asDriver(onErrorJustReturn: #imageLiteral(resourceName: "Magnet"))

        progress = torrent.percentDone

        statusMessage = torrent.status.map { $0.description }
        statusColor = torrent.status.map { $0.color }
    }

    var title: Observable<String>
    var subtitle: Observable<String>

    var image: Driver<Image?>
    var progress: Observable<Float>
    var statusMessage: Observable<String>
    var statusColor: Observable<Color>
    var imageContentMode: Observable<ContentMode>
}

func == (lhs: TorrentViewModel, rhs: TorrentViewModel) -> Bool {
    return (lhs.torrent == rhs.torrent)
}
