//
//  Configuration.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 02/05/2014.
//

import Foundation

// swiftlint:disable force_unwrapping

#if SUBSTITUTED
    // This should not be compiled if substitution has been run
#else

///  For general configuration of things, URLs and API keys
enum Configuration {

    static let updatesURL = URL(string: "http://github.com/samscam/transmote")!

    enum TMDB {
        static let apiKey = "{**TMDB_API_KEY**}"
        static let baseURL = URL(string: "https://api.themoviedb.org/3/")!
        static let imagesURL = URL(string: "https://image.tmdb.org/t/p/")!
    }
}

#endif
