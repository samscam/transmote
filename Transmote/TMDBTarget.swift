//
//  TMDBTarget.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 07/12/2016.
//

import Foundation

import Moya

enum TMDBTarget {
    case serviceConfiguration
    case multiSearch(query: String)
    case tvShowSearch(showName: String)
    case tvSeasonDetails(showID:Int, season:Int)
    case tvShowDetails(showID:Int, season:Int, episode:Int)
    case movieSearch(movieName: String, year: Int?)
    case image(path: String)
}

extension TMDBTarget: TargetType {
    var headers: [String: String]? {
        return nil
    }

    public var baseURL: URL {
        switch self {
        case .image:
            return Configuration.TMDB.imagesURL
        default:
            return Configuration.TMDB.baseURL
        }

    }

    public var path: String {
        switch self {
        case .serviceConfiguration:
            return "configuration"
        case .image(let path):
            return "w500/" + path
        case .multiSearch:
            return "search/multi"
        case .movieSearch:
            return "search/movie"
        case .tvSeasonDetails(let showID, let season):
            return "tv/\(showID)/season/\(season)"
        case .tvShowDetails(let showID, let season, let episode):
            return "tv/\(showID)/season/\(season)/episode/\(episode)"
        case .tvShowSearch:
            return "search/tv"
        }
    }

    public var method: Moya.Method { return .get }

    // And here's the fun part
    public var task: Task {
        var params: [String: Any] = ["api_key": Configuration.TMDB.apiKey]
        switch self {
        case .serviceConfiguration, .image, .tvShowDetails, .tvSeasonDetails:
            break
        case .movieSearch(let movieName, let year):
            params["query"] = movieName
            if let year = year {
                params["year"] = year
            }

        case .tvShowSearch(let showName):
            params["query"] = showName
        case .multiSearch(let query):
            params["query"] = query
        }
        return .requestParameters(parameters: params, encoding: URLEncoding.default)
    }

    public var sampleData: Data {
        return "Just can't be bothered".data(using: String.Encoding.utf8)! // swiftlint:disable:this force_unwrapping
    }

}
