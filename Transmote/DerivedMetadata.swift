//
//  DerivedMetadata.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 27/01/2017.
//

import Foundation

struct DerivedMetadata: Metadata {

    var title: String { return self.cleanedName }
    var description: String { return self.rawName }
    var type: TorrentMetadataType = .other
    var imagePath: String?

    var cleanedName: String = ""
    var season: Int?
    var year: Int?
    var episode: Int?
    var rawName: String

    init(from rawName: String) {
        self.rawName = rawName
        self.cleanedName = rawName

        // Clean up dots, underscores

        // swiftlint:disable force_try

        var cleaner = try! NSRegularExpression(pattern: "[\\[\\]\\(\\)\\.+_-]", options: [])
        var semiCleaned = cleaner.stringByReplacingMatches(in: rawName, options: [], range: NSRange(location: 0, length: rawName.count), withTemplate: " ")

        // Clean runs of whitespace
        cleaner = try! NSRegularExpression(pattern: "\\s+", options: .caseInsensitive)
        semiCleaned = cleaner.stringByReplacingMatches(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.count), withTemplate: " ")

        // Clean references to DVD BDRIP and boxset and things
        cleaner = try! NSRegularExpression(pattern: "\\b(1080p|720p|x264|dts|aac|boxset|extras|dvd\\w*?|br|bluray|bd\\w*?|((from )?www .* com\\w*))\\b", options: .caseInsensitive)
        semiCleaned = cleaner.stringByReplacingMatches(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.count), withTemplate: " ")

        // Clean runs of whitespace
        cleaner = try! NSRegularExpression(pattern: "\\s+", options: .caseInsensitive)
        semiCleaned = cleaner.stringByReplacingMatches(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.count), withTemplate: " ")

        // Trim leading and trailing
        cleaner = try! NSRegularExpression(pattern: "(^\\s*)|(\\s*$)", options: .caseInsensitive)
        semiCleaned = cleaner.stringByReplacingMatches(in: semiCleaned, options: [], range: NSRange(location: 0, length: semiCleaned.count), withTemplate: "")

        self.cleanedName = semiCleaned

        // Figure out if we have an episode code or season or year or whatnot
        let pattern = "^(.+?)\\s*(?:\\W*(?:(\\b\\d{4}\\b)|(?:\\b(?:s\\s?)+(\\d+)\\W*(?:(?:ep|episode|[ex])\\s?(\\d+\\b))?)|(?:season\\s?(\\d+)))){1,2}"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        // swiftlint:enable force_try

        guard let result = regex.firstMatch(in: semiCleaned,
                                            options: [],
                                            range: NSRange(location: 0, length: semiCleaned.count))
            else {
                // If we can't match the regex then give up, returning the name as cleaned up as we have it
                return
        }

        let title = (semiCleaned as NSString).substring(with: result.range(at: 1))

        self.cleanedName = title

        if !NSEqualRanges(result.range(at: 2), NSRange(location: NSNotFound, length: 0)) {
            year = Int((semiCleaned as NSString).substring(with: result.range(at: 2)))
        }

        if !NSEqualRanges(result.range(at: 3), NSRange(location: NSNotFound, length: 0)) {
            season = Int((semiCleaned as NSString).substring(with: result.range(at: 3)))
        } else if !NSEqualRanges(result.range(at: 5), NSRange(location: NSNotFound, length: 0)) {
            season = Int((semiCleaned as NSString).substring(with: result.range(at: 5)))
        }

        if !NSEqualRanges(result.range(at: 4), NSRange(location: NSNotFound, length: 0)) {
            episode = Int((semiCleaned as NSString).substring(with: result.range(at: 4)))
        }

        // Figure out what type it probably is

        if season != nil && episode != nil {
            self.type = .television
        } else if season != nil {
            self.type = .television
        } else if year != nil {
            self.type = .movie
        }

        print("Raw name: \(rawName)")
        print("... converted to: \(self.cleanedName)")

    }

}
