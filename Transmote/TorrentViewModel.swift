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

        torrentMetadata = torrent.name.flatMap { metadataManager.metadata(for: $0) }

        title = torrentMetadata.map { $0.name }
        subtitle = torrentMetadata.map { metadata in
            switch metadata.type {
            case .tvEpisode(let season, let episode, let episodeName):
                var description = "Season \(season) • Episode \(episode)"
                if let episodeName = episodeName {
                    description += "\n\(episodeName)"
                }
                return description
            case .tvSeason(let season):
                return "Season \(season)"
            case .tvSeries:
                return "Complete series"
            case .movie(let year):
                return "\(year)"
            case .video:
                return "Video"
            case .other:
                return "Not a video"
            }
        }
        image = Observable.just(NSImage(named:"Magnet")!).asDriver(onErrorJustReturn: NSImage(named:"Magnet")!)
        progress = torrent.percentDone

        statusMessage = torrent.status.map { $0.description }
        statusColor = torrent.status.map { $0.color }
    }

    var title: Observable<String>
    var subtitle: Observable<String>

    var image: Driver<Image>
    var progress: Observable<Float>
    var statusMessage: Observable<String>
    var statusColor: Observable<Color>
}

func == (lhs: TorrentViewModel, rhs: TorrentViewModel) -> Bool {
    return (lhs.torrent == rhs.torrent)
}
