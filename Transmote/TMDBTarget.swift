//
//  TMDBTarget.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 07/12/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Foundation

import Moya

enum TMDBTarget {
    case serviceConfiguration
    case tvShowMetadata(showName: String)
    case tvShowDetails(showID:Int, season:Int, episode:Int)
    case movieMetadata(movieName: String, year: Int?)
    case image(path: String)
}

extension TMDBTarget: TargetType {

    // These will always be ignored
    public var baseURL: URL {
        switch self {
        case .image:
            return URL(string: TMDB_IMAGES_URL)!
        default:
            return URL(string: TMDB_BASE_URL)!
        }
       
    }
    
    public var path: String {
        switch self {
        case .serviceConfiguration:
            return "configuration"
        case .image(let path):
            return "w500/" + path
        case .movieMetadata:
            return "search/movie"
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
        case .serviceConfiguration, .image,.tvShowDetails:
            break
        case .movieMetadata(let movieName, let year):
            params["query"] = movieName
            if let year = year {
                params["year"] = year
            }

        case .tvShowMetadata(let showName):
            params["query"] = showName
        }
        return params
    }
    
    public var sampleData: Data {
        return "Just can't be bothered".data(using: String.Encoding.utf8)!
    }
    
    public var task: Task {
        return .request
    }
}
