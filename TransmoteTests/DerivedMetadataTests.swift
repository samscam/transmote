//
//  DerivedMetadataTests.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 17/01/2017.
//

import Foundation
import Quick
import Nimble
@testable import Transmote

class DerivedMetadataSpec: QuickSpec {

    // swiftlint:disable force_try force_unwrapping

    override func spec() {
        describe("Identifying types") {
            context("TV") {
                let samples = ["Lucifer.S02.HDTV.x264-LOL[ettv]",
                               "Some.Thing.Season.2.HDTV.x264-LOL[ettv]",
                               "Gotham.S03E12.HDTV.x264-LOL[ettv]",
                               "Sherlock.S04E02.WEBRip.x264-FUM[ettv]",
                               "Sherlock.S04E01.The.Six.Thatchers.PROPER.HDTV.x264-DEADPOOL[e..."]
                let allDerived: [DerivedMetadata] = samples.map { DerivedMetadata(from: $0) }
                for item in allDerived {
                    it("should identify them as TV") {
                        expect(item.type) == TorrentMetadataType.tv
                    }
                }

            }
            context("Movies") {
                let samples = ["Arrival.2016.DVDScr.XVID.AC3.HQ.Hive-CM8",
                               "La.La.Land.2016.DVDScr.XVID.AC3.HQ.Hive-CM8",
                    "Fantastic.Beasts.and.Where.to.Find.Them.2016.720p.HC.HDRip.x264.",
                    "Arrival.2016.DVDScr.x264-4RRIVED",
                    "Fantastic.Beasts.and.Where.to.Find.Them.2016.HC.HDRip ETRG"]
                let allDerived: [DerivedMetadata] = samples.map { DerivedMetadata(from: $0) }
                for item in allDerived {
                    it("should identify them as Movies") {
                        expect(item.type) == TorrentMetadataType.movie
                    }
                }

            }

            xcontext("Software") {
                let samples = ["Adobe Photoshop CS6 13.0.1 Final  Multilanguage (cracked dll) [C",
                               "Windows 10 Pro v.1511 En-us x64 July2016 Pre-Activated-=TEAM OS=",
                               "Far Cry Primal-CPY",
                               "The Sims 4-RELOADED",
                               "MICROSOFT Office PRO Plus 2016 v16.0.4266.1003 RTM + ActivatorG"]
                let allDerived: [DerivedMetadata] = samples.map { DerivedMetadata(from: $0) }
                for item in allDerived {
                    it("should identify them as Software") {
                        expect(item.type) == TorrentMetadataType.software
                    }
                }
            }
        }
        describe("Deriving metadata") {

            let testBundle = Bundle(for: type(of: self))
            let fileURL = testBundle.url(forResource: "sample-top100", withExtension: "txt")!
            let names = try! String(contentsOf: fileURL).components(separatedBy: .newlines)
            let allDerived: [DerivedMetadata] = names.map { DerivedMetadata(from: $0) }

            context("Everything") {
                for item in allDerived {
                    it("should clean up dots and underscores and whitespace and so forth") {
                        expect(item.title).toNot(contain([".", "-", "_"]))
                    }
                }
            }

        }

    }

}
