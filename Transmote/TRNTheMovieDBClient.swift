////
////  TRNTheMovieDBClient.h
////  Transmote
////
////  Created by Sam Easterby-Smith on 01/05/2014.
////  Copyright (c) 2014 Spotlight Kid. All rights reserved.
////
//import Foundation
//import Cocoa
//import AFNetworking
//
//class TRNTheMovieDBClient: NSObject {
//    func fetchMetadata(forMovieNamed movieName: String, year: String, onCompletion completionBlock: @escaping () -> Void) {
//        var method = "search/movie"
//        var params = ["api_key": TMDB_API_KEY, "query": movieName]
//        if year != "" {
//            params["year"] = year
//        }
//        self.sessionManager.get(method, parameters: params, success: {(_ task: URLSessionDataTask, _ responseObject: Any) -> Void in
//            var results = (responseObject.value(forKey: "results") as! String)
//            if results && results.count > 0 {
//                var firstResult = results[0]
//                completionBlock(firstResult)
//            }
//        }, failure: {(_ task: URLSessionDataTask, _ error: Error) -> Void in
//            print("error \(error.localizedDescription)")
//        })
//    }
//
//    func fetchMetadata(forTVShowNamed showName: String, year: String, onCompletion completionBlock: @escaping () -> Void) {
//        var method = "search/tv"
//        var params = ["api_key": TMDB_API_KEY, "query": showName]
//        if year != "" {
//            params["first_air_date_year"] = year
//        }
//        self.sessionManager.get(method, parameters: params, success: {(_ task: URLSessionDataTask, _ responseObject: Any) -> Void in
//            var results = (responseObject.value(forKey: "results") as! String)
//            if results && results.count > 0 {
//                var firstResult = results[0]
//                completionBlock(firstResult)
//            }
//        }, failure: {(_ task: URLSessionDataTask, _ error: Error) -> Void in
//            print("error \(error.localizedDescription)")
//        })
//    }
//
//    func fetchDetailsForTVShow(withID showID: String, season: Int, episode: Int, onCompletion completionBlock: @escaping () -> Void) {
//        var method = "tv/\(showID)/season/\(season)/episode/\(episode)"
//        var params = ["api_key": TMDB_API_KEY]
//        self.sessionManager.get(method, parameters: params, success: {(_ task: URLSessionDataTask, _ responseObject: Any) -> Void in
//            print("\(responseObject)")
//            completionBlock(responseObject)
//        }, failure: {(_ task: URLSessionDataTask, _ error: Error) -> Void in
//            print("ERR \(error.localizedDescription)")
//        })
//    }
//
//    func fetchImage(atPath imagePath: String, onCompletion completionBlock: @escaping (_ image: NSImage) -> Void) {
//        var wrapBlock = {() -> Void in
//                if !imagePath || (imagePath is NSNull) {
//                    return
//                }
//                    // Hard-coded image size here... should perhaps extract this from TMDB config?
//                var realPath = URL(fileURLWithPath: "w300").appendingPathComponent(imagePath).absoluteString
//                self.imageSessionManager.get(realPath, parameters: nil, success: {(_ task: URLSessionDataTask, _ responseObject: Any) -> Void in
//                    completionBlock(responseObject)
//                }, failure: {(_ task: URLSessionDataTask, _ error: Error) -> Void in
//                    print("error \(error.localizedDescription)")
//                })
//            }
//        if !self.imageSessionManager {
//            self.fetchServiceConfiguration(onCompletion: wrapBlock)
//        }
//        else {
//            wrapBlock()
//        }
//    }
//
//
//    func sessionManager() -> AFHTTPSessionManager {
//        if !sessionManager {
//            var baseURL = URL(string: TMDB_BASE_URL)!
//            self.sessionManager = AFHTTPSessionManager(baseURL: baseURL)
//        }
//        return sessionManager
//    }
//
//    func fetchServiceConfiguration(onCompletion completionBlock: @escaping () -> Void) {
//        self.sessionManager().get("configuration", parameters: ["api_key": TMDB_API_KEY], success: {(_ task: URLSessionDataTask, _ responseObject: Any) -> Void in
//            var imageBaseURLString = (responseObject as! [AnyHashable: Any]).value(forKeyPath: "images.secure_base_url")!
//            self.imageSessionManager = AFHTTPSessionManager(baseURL: URL(string: imageBaseURLString)!)
//            self.imageSessionManager.responseSerializer = AFImageResponseSerializer()
//            completionBlock()
//        }, failure: {(_ task: URLSessionDataTask, _ error: Error) -> Void in
//        })
//    }
//
//
//    var metadataStore = [AnyHashable: Any]()
//    var sessionManager: AFHTTPSessionManager? {
//        if !sessionManager {
//                var baseURL = URL(string: TMDB_BASE_URL)!
//                self.sessionManager = AFHTTPSessionManager(baseURL: baseURL)
//            }
//            return sessionManager
//    }
//    var imageSessionManager: AFHTTPSessionManager!
//}
////
////  TRNTheMovieDBClient.m
////  Transmote
////
////  Created by Sam Easterby-Smith on 01/05/2014.
////  Copyright (c) 2014 Spotlight Kid. All rights reserved.
////
