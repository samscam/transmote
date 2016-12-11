////
////  TRNTorrent.h
////  Transmote
////
////  Created by Sam Easterby-Smith on 08/02/2014.
////  Copyright (c) 2014 Spotlight Kid. All rights reserved.
////
//

import Foundation
import AppKit
import ObjectMapper
import RxSwift
import RxCocoa
import Moya
import RxMoya

enum TorrentStatus: Int, CustomStringConvertible{
    case stopped = 0
    case checkWait = 1
    case check = 2
    case downloadWait = 3
    case download = 4
    case seedWait = 5
    case seed = 6
    
    var description: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .checkWait:
            return "Waiting to check files"
        case .check:
            return  "Checking files"
        case .downloadWait:
            return  "Queued for download"
        case .download:
            return "Downloading"
        case .seedWait:
            return "Queued for seeding"
        case .seed:
            return "Seeding"
        }
    }
    
    var color: NSColor {
        switch self {
        case .stopped:
            return NSColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        case .checkWait:
            return NSColor(red: 1, green: 0.2, blue: 0, alpha: 1)
        case .check:
            return NSColor(red: 1, green: 0.5, blue: 0, alpha: 1)
        case .downloadWait:
            return NSColor(red: 0, green: 0.5, blue: 0, alpha: 1)
        case .download:
            return NSColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1)
           
        case .seedWait:
            return NSColor(red: 0, green: 0.5, blue: 0.5, alpha: 1)
        case .seed:
            return NSColor(red: 0, green: 0.8, blue: 0, alpha: 1)
        }
    }
}

class Torrent: Mappable, Equatable, Hashable {
    
    // MARK: - Mappable variables
    var id: Int!
    
    // Slightly funny arrangement here so that the Observable only changes when the value actually changes
    
    private var __name: String {
        get{ return _name.value }
        set{
            
            if newValue != __name {
                print("Name set to \(newValue)")
                _name.value = newValue
            } }
    }
    private let _name = Variable<String>("")
    var name: Observable<String> { return _name.asObservable() }
    
    // The rest is more straightforward
    
    private let _activityDate = Variable<Date?>(nil)
    var activityDate: Observable<Date?> { return _activityDate.asObservable() }
    
    private let _addedDate = Variable<Date?>(nil)
    var addedDate: Observable<Date?> { return _addedDate.asObservable() }
    
    private let _doneDate = Variable<Date?>(nil)
    var doneDate: Observable<Date?> { return _doneDate.asObservable() }
    
    private let _isFinished = Variable<Bool>(false)
    var isFinished: Observable<Bool> { return _isFinished.asObservable() }
    
    private let _isStalled = Variable<Bool>(false)
    var isStalled: Observable<Bool> { return _isStalled.asObservable() }
    
    private let _eta = Variable<Date?>(nil)
    var eta: Observable<Date?> { return _eta.asObservable() }
    
    private let _rateDownload = Variable<Int>(0)
    var rateDownload: Observable<Int> { return _rateDownload.asObservable() }
    
    private let _rateUpload = Variable<Int>(0)
    var rateUpload: Observable<Int> { return _rateUpload.asObservable() }
    
    private let _percentDone = Variable<Double>(0)
    var percentDone: Observable<Double> { return _percentDone.asObservable() }
    
    private let _totalSize = Variable<Int>(0)
    var totalSize: Observable<Int> { return _totalSize.asObservable() }
    
    private let _rawStatus = Variable<Int>(0)
    var rawStatus: Observable<Int> { return _rawStatus.asObservable() }
    
    // MARK: - Initialisation and parsing
    
    required init?(map: Map){
        
    }
    
    func mapping(map: Map){
        id                     <- map["id"]
        __name                 <- map["name"]
        _activityDate.value    <- (map["activityDate"], DateTransform())
        _addedDate.value       <- (map["addedDate"], DateTransform())
        _doneDate.value        <- (map["doneDate"], DateTransform())
        _isFinished.value      <- map["isFinished"]
        _isStalled.value       <- map["isStalled"]
        _eta.value             <- (map["eta"], DateTransform())
        _rateDownload.value    <- map["rateDownload"]
        _rateUpload.value      <- map["rateUpload"]
        _percentDone.value     <- map["percentDone"]
        _totalSize.value       <- map["totalSize"]
        _rawStatus.value       <- map["status"]
        
    }
    
    func update(JSON:[String: Any]) -> Torrent {
        return Mapper<Torrent>().map(JSON: JSON, toObject: self)
    }
    
    // MARK: - Calculated variables
    
    lazy var derivedMetadata: Observable<Metadata> = self.name.map{
        print("Deriving metadata for \($0)")
        return Metadata(from: $0)
    }.shareReplay(1) // << If this isn't here it does it repeatedly
    
    lazy var bestName: Observable<String> = self.metadata.map{ $0.name }
    
    
    lazy var status: Observable<TorrentStatus> = self.rawStatus.map{ rawValue in
        return TorrentStatus(rawValue: rawValue)!
        }
    
    // External metadata
    
    let tmdbProvider = RxMoyaProvider<TMDBTarget>()
    

    lazy var externalMetadata: Observable<Metadata?> = {
        
        let response = self.derivedMetadata.flatMap({ derived -> Observable<Response> in
            
            switch derived.type {
            case .tv:
                return self.tmdbProvider.request(.tvShowMetadata(showName: derived.name))
            case .movie(let year):
                return self.tmdbProvider.request(.movieMetadata(movieName: derived.name, year: year))
            default:
                throw MetadataError.couldNotRequest
            }
        })
        
        let json = response.mapJSON()
        
        let metadata: Observable<Metadata?> = json.map{ latestJSON in
            if let jsonDict = latestJSON as? [String:Any],
                let firstResult: [String: Any] = (jsonDict["results"] as! [Any]).first as! [String : Any]? {
                return Metadata(JSON: firstResult)
            }
            return nil
        }
        
        return metadata
        
    }()
    
    lazy var metadata: Observable<Metadata> = Observable.combineLatest(self.derivedMetadata, self.externalMetadata){
            if let external = $1 {
                return external
            }
            return $0
        }
    
    
    lazy var image: Observable<NSImage?> = {
        
        let imageResponse = self.metadata.flatMap{ bestMetadata -> Observable<Response> in
            if let path = bestMetadata.posterPath {
                return self.tmdbProvider.request(.image(path:path))
            } else {
                throw MetadataError.noImagePath
            }
        }

        return imageResponse.mapImage()
    }()
    
    // Hashable
    
    var hashValue: Int { return id! }
}




func == (lhs: Torrent, rhs: Torrent) -> Bool {
    return (lhs.id! == rhs.id!)
}


