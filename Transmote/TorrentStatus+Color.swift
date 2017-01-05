//
//  TorrentStatus+Color.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 05/01/2017.
//

import Foundation

#if os(iOS) || os(tvOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

#if os(iOS) || os(tvOS)
    typealias Color = UIColor
#elseif os(OSX)
    typealias Color = NSColor
#endif

extension TorrentStatus {
    var color: Color {
        switch self {
        case .stopped:
            return Color(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        case .checkWait:
            return Color(red: 1, green: 0.2, blue: 0, alpha: 1)
        case .check:
            return Color(red: 1, green: 0.5, blue: 0, alpha: 1)
        case .downloadWait:
            return Color(red: 0, green: 0.5, blue: 0, alpha: 1)
        case .download:
            return Color(red: 0.3, green: 0.7, blue: 1.0, alpha: 1)

        case .seedWait:
            return Color(red: 0, green: 0.5, blue: 0.5, alpha: 1)
        case .seed:
            return Color(red: 0, green: 0.8, blue: 0, alpha: 1)
        }
    }

}
