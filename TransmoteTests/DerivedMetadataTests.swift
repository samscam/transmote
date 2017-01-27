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

    // swiftlint:disable force_try conditional_returns_on_newline function_body_length force_unwrapping

    override func spec() {
        describe("Identifying types") {
            context("TV Season") {

            }
            context("TV Episode") {
                let samples = ["Lucifer.S02E11.HDTV.x264-LOL[ettv]",
                               "Marvels.Agents.of.S.H.I.E.L.D.S04E10.HDTV.x264-LOL[ettv]",
                               "Gotham.S03E12.HDTV.x264-LOL[ettv]",
                               "Sherlock.S04E02.WEBRip.x264-FUM[ettv]",
                               "Sherlock.S04E01.The.Six.Thatchers.PROPER.HDTV.x264-DEADPOOL[e..."]
                let allDerived: [DerivedMetadata] = samples.map { DerivedMetadata(from: $0) }
                for item in allDerived {
                    it("should identify them as TV Episodes") {
                        expect(item.type) == TorrentMetadataType.tvEpisode
                    }
                }

            }
            context("TV Series") {

            }
            context("Movie") {

            }
            context("Other") {

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
                        expect(item.name).toNot(contain([".", "-", "_"]))
                    }
                }
            }

            context("Torrents which are TV Episodes") {
                let tv = allDerived.filter {
                    if case .tvEpisode = $0.type { return true } else { return false }
                }

                for item in tv {
                    context("Torrent named \(item.rawName)") {

                        it("Should extract the season number") {
                            expect(item.season).toNot(beNil())
                        }
                        it("Should extract the episode number") {
                            expect(item.episode).toNot(beNil())
                        }
                    }
                }
            }

            context("Torrents which are TV Series") {
                let tv = allDerived.filter {
                    if case .tvSeason = $0.type { return true } else { return false }
                }

                for item in tv {
                    context("Torrent named \(item.rawName)") {

                        it("Should have a season number") {
                            expect(item.season).toNot(beNil())
                        }
                        it("Should NOT have an episode number") {
                            expect(item.episode).to(beNil())
                        }
                    }
                }
            }

            context("Items which are NOT tv episodes") {
                let notTv = allDerived.filter {
                    if case .tvEpisode = $0.type { return false } else { return true }
                }
                for item in notTv {
                    context("Torrent named \(item.rawName)") {

                        it("Should not have a season number") {
                            expect(item.season).to(beNil())
                        }
                        it("Should not have an episode number") {
                            expect(item.episode).to(beNil())
                        }
                    }
                }
            }

        }

    }

}

