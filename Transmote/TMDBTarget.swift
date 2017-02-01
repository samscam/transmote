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
    case tvShowMetadata(showName: String)
    case tvSeasonDetails(showID:Int, season:Int)
    case tvShowDetails(showID:Int, season:Int, episode:Int)
    case movieMetadata(movieName: String, year: Int?)
    case image(path: String)
}

extension TMDBTarget: TargetType {

    public var baseURL: URL {
        switch self {
        case .image:
            return URL(string: TMDB_IMAGES_URL)! // swiftlint:disable:this force_unwrapping
        default:
            return URL(string: TMDB_BASE_URL)! // swiftlint:disable:this force_unwrapping
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
        case .movieMetadata:
            return "search/movie"
        case .tvSeasonDetails(let showID, let season):
            return "tv/\(showID)/season/\(season)"
        case .tvShowDetails(let showID, let season, let episode):
            return "tv/\(showID)/season/\(season)/episode/\(episode)"
        case .tvShowMetadata:
            return "search/tv"
        }
    }

    public var method: Moya.Method { return .get }

    // And here's the fun part
    public var parameters: [String: Any]? {
        var params: [String: Any] = ["api_key": TMDB_API_KEY]
        switch self {
        case .serviceConfiguration, .image, .tvShowDetails, .tvSeasonDetails:
            break
        case .movieMetadata(let movieName, let year):
            params["query"] = movieName
            if let year = year {
                params["year"] = year
            }

        case .tvShowMetadata(let showName):
            params["query"] = showName
        case .multiSearch(let query):
            params["query"] = query
        }
        return params
    }

    public var sampleData: Data {
        return "Just can't be bothered".data(using: String.Encoding.utf8)! // swiftlint:disable:this force_unwrapping
    }

    public var task: Task {
        return .request
    }

    /// The method used for parameter encoding.
    public var parameterEncoding: ParameterEncoding {
        return URLEncoding()
    }
}
