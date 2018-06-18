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

class TorrentViewModel {

    private let torrent: Observable<Torrent>
    private let metadataManager: MetadataManager

    init(torrent: Observable<Torrent>, metadataManager: MetadataManager) {
        self.torrent = torrent
        self.metadataManager = metadataManager
    }

    private lazy var metadata: Observable<Metadata> = { self.torrent.flatMap { self.metadataManager.metadata(for: $0.name) } }()

    lazy var title: Observable<String> = { self.metadata.map { $0.title } }()
    lazy var subtitle: Observable<String> = { self.metadata.map { $0.description } }()

    private lazy var remoteImage: Observable<Image?> = {
        self.metadata
            .map { $0.imagePath }
            .flatMap { imagePath -> Observable<Image?> in
                if let imagePath = imagePath {
                    return self.metadataManager.tmdbProvider.rx.request(.image(path: imagePath)).mapImage().asObservable()
                } else {
                    return Observable<Image?>.just(nil)
                }
            }
    }()
    lazy var image: Observable<Image> = {
        self.remoteImage.map { remoteImageValue in
            if let remoteImageValue = remoteImageValue {
                return remoteImageValue
            } else {
                return #imageLiteral(resourceName: "magnet")
            }
        }
    }()

    lazy var imageContentMode: Observable<ContentMode> = {
        self.remoteImage.map { $0 == nil ? ContentMode.center : ContentMode.scaleAspectFill }
    }()

    lazy var progress: Observable<Float> = { self.torrent.map { $0.percentDone } }()
    lazy var statusMessage: Observable<String> = { self.torrent.map { $0.status.description } }()
    lazy var statusColor: Observable<Color> = { self.torrent.map { $0.status.color } }()

}
