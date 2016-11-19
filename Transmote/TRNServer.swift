//
//  TRNServer.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//
import Foundation
import Cocoa
import AFNetworking
import AFJSONRPCClient


class TRNServer: NSObject {
    
    var address: String?
    var port: String?
    var rpcPath: String?
    var username: String?
    var password: String?
    
    var isConnected = false
    var torrents: [TRNTorrent] = []
    var torrentDict = [AnyHashable: Any]()
    var client: TRNJSONRPCClient?
    var timer: Timer?
    
    var connecting = false
    var updating = false
    var protectionSpace: URLProtectionSpace!
    
    var connectionContext = "connectionContext"

    override init() {
        
        // Bind user defaults
        let userDefaultsController = NSUserDefaultsController.shared()

        self.bind("address", to: userDefaultsController, withKeyPath: "values.address", options: [NSContinuouslyUpdatesValueBindingOption: true])
        self.bind("port", to: userDefaultsController, withKeyPath: "values.port", options: [NSContinuouslyUpdatesValueBindingOption: true])
        self.bind("rpcPath", to: userDefaultsController, withKeyPath: "values.rpcPath", options: [NSContinuouslyUpdatesValueBindingOption: true])
        self.bind("username", to: userDefaultsController, withKeyPath: "values.username", options: [NSContinuouslyUpdatesValueBindingOption: true])

        self.addObserver(self, forKeyPath: "address", options: .new, context: &connectionContext)
        self.addObserver(self, forKeyPath: "port", options: .new, context: &connectionContext)
        self.addObserver(self, forKeyPath: "rpcPath", options: .new, context: &connectionContext)
        self.addObserver(self, forKeyPath: "username", options: .new, context: &connectionContext)
        self.addObserver(self, forKeyPath: "password", options: .new, context: &connectionContext)
        
        
        self.tryToConnect()
    }
    
    
    
    func tryToConnect() {
        self.timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.timerDidFire), userInfo: nil, repeats: true)
        self.connect()
    }

    func disconnect() {
        self.connected = false
        self.client = nil
        self.timer.invalidate()
        self.timer = nil
    }

    func addMagnetLink(_ magnetLink: URL) {
        self.client?.invokeMethod("torrent-add", withParameters: ["filename": magnetLink.absoluteString], success: {(_ operation: AFHTTPRequestOperation, _ responseObject: Any) -> Void in
            print("Torrent added: \(responseObject)")
        }, failure: {(_ operation: AFHTTPRequestOperation, _ error: Error) -> Void in
            print("Torrent failed to add: \(error.localizedDescription)")
        })
    }

    func removeTorrents(_ torrentsToDelete: [Any], deleteData delete: Bool) {
        var torrentIDs = [Any]()
        for thisTorrent: TRNTorrent in torrentsToDelete {
            torrentIDs.append(thisTorrent.id)
        }
        self.client!.invokeMethod("torrent-remove", withParameters: ["ids": torrentIDs, "delete-local-data": Int(delete)], success: {(_ operation: AFHTTPRequestOperation, _ responseObject: Any) -> Void in
            // Looks like it has gone.
            // Remove it locally too
            self.willChangeValue(forKey: "torrents")
            // force the array controller to spot the change
            for k in torrentIDs { self.torrentDict.removeValueForKey(k) }
            self.torrents.removeObjects(in: torrentsToDelete)
            self.didChangeValue(forKey: "torrents")
        }, failure: {(_ operation: AFHTTPRequestOperation, _ error: Error) -> Void in
            // Some error occured... assume we have been disconnected...
            self.connected = false
        })
    }




    func timerDidFire(_ timer: Any) {
        // the timer will fire every three seconds...
        // we should probably make this configurable...
        if self.connected {
            // if we are connected update the torrents
            self.updateTorrents()
        }
        else {
            // otherwise, have another bash at connecting
            // should probably throttle this down if it fails a few times
            self.connect()
        }
    }

    func connect() {
        if connecting {
            return
        }
        connecting = true
        self.torrentDict.removeAll()
        self.torrents.removeAll()
        self.client! = TRNJSONRPCClient(endpointURL: self.serverURL())
        if self.credential {
            self.client!.credential = self.credential
        }
        self.client!.invokeMethod("session-get", success: {(_ operation: AFHTTPRequestOperation, _ responseObject: Any) -> Void in
            //WOO
            print("Session alive\n\(responseObject)")
            self.connected = true
            connecting = false
            // force an immediate update of torrents
            self.updateTorrents()
                // Check for a deferred URL
            var appDelegate = (NSApp.delegate as! TRNAppDelegate)
            if appDelegate.deferredMagnetURL {
                self.addMagnetLink(appDelegate.deferredMagnetURL)
                appDelegate.deferredMagnetURL = nil
            }
            connecting = false
        }, failure: {(_ operation: AFHTTPRequestOperation, _ error: Error) -> Void in
            // This will get called on session negotiation.. so don't trust it
            self.connected = false
            connecting = false
        })
    }

    func serverURL() -> URL {
        var theURL = URL(string: "http://\(self.address):\(self.port)/\(self.rpcPath)")!
        return theURL
    }

    func updateTorrents() {
        if updating {
            return
        }
        updating = true
        self.client!.invokeMethod("torrent-get", withParameters: ["fields": ["id", "name", "totalSize", "rateDownload", "rateUpload", "percentDone", "eta"]], success: {(_ operation: AFHTTPRequestOperation, _ responseObject: Any) -> Void in
            if !(responseObject is [AnyHashable: Any]) {
                // Oh dear - the response object was not a dictionary! What happened??
                return
            }
            var responseDict = (responseObject as! [AnyHashable: Any])
            if responseDict.value(forKeyPath: "arguments.torrents")! {
                var incomingTorrents = responseDict.value(forKeyPath: "arguments.torrents")!
                var foundTorrentKeys = [Any]()
                for thisTData: [AnyHashable: Any] in incomingTorrents {
                    var torrentID = (thisTData.value(forKey: "id") as! String)
                    var importTo = (self.torrentDict[torrentID] as! String)
                    if !importTo {
                        importTo = TRNTorrent(self)
                        self.willChangeValue(forKey: "torrents")
                        // This feels a bit nasty - forces the array controller to do initial update
                        self.torrents.append(importTo)
                        self.torrentDict[torrentID] = importTo
                        self.didChangeValue(forKey: "torrents")
                    }
                    foundTorrentKeys.append(torrentID)
                    importTo.importJSONData(thisTData)
                }
                var deleteKeys = self.torrentDict.allKeys()
                deleteKeys.removeObjects(in: foundTorrentKeys)
                var torrentsToDelete = self.torrentDict.objects(forKeys: deleteKeys, notFoundMarker: NSNull())
                if torrentsToDelete.count > 0 {
                    self.willChangeValue(forKey: "torrents")
                    for k in deleteKeys { self.torrentDict.removeValueForKey(k) }
                    self.torrents.removeObjects(in: torrentsToDelete)
                    self.didChangeValue(forKey: "torrents")
                }
            }
            updating = false
        }, failure: {(_ operation: AFHTTPRequestOperation, _ error: Error) -> Void in
            // Some error occured... assume we have been disconnected...
            self.connected = false
            updating = false
        })
    }

    override func observeValue(forKeyPath keyPath: String, ofObject object: Any, change: [AnyHashable: Any], context: UnsafeMutableRawPointer) {
        if context == connectionContext {
            if (keyPath == "password") || (keyPath == "username") {
                self.passwordChanged()
            }
            // The user edited the connection details - force a reconnect
            connecting = false
            self.connect()
            self.updateDefaults()
            return
        }
        return super.observeValue(forKeyPath: keyPath, ofObject: object, change: change, context: context)
    }

    func updateDefaults() {
        var defaults = UserDefaults.standard
        defaults.setValue(self.address, forKey: "address")
        defaults.setValue(self.rpcPath, forKey: "rpcPath")
        defaults.setValue(self.port, forKey: "port")
        defaults.setValue(self.username, forKey: "username")
    }

    func passwordChanged() {
        if !self.username || (self.username == "") {
            return
        }
        protectionSpace = URLProtectionSpace(host: self.address, port: self.port.integerValue)
        var credentialStore = URLCredentialStorage.shared
        if credential {
            // clear out old credentials?
            credentialStore.removeCredential(credential, forProtectionSpace: protectionSpace)
        }
        self.willChangeValue(forKey: "credential")
        self.credential = URLCredential(user: self.username, password: self.password!, persistence: NSURLCredentialPersistencePermanent)
        credentialStore.set(credential, for: protectionSpace)
        self.didChangeValue(forKey: "credential")
    }

    func credential() -> URLCredential {
        if !self.username || (self.username == "") {
            return nil
        }
        protectionSpace = URLProtectionSpace(host: self.address, port: self.port.integerValue)
        var credentialStore = URLCredentialStorage.shared
        var credentials = credentialStore.credentials(forProtectionSpace: protectionSpace)!
        print("Credentials: \(credentials)")
        self.credential = (credentials.value(forKey: self.username) as! String)
        print("Using credential: \(credential)")
        return credential
    }

    var credential: URLCredential? {
        if !self.username| (self.username == "") {
                return nil
            }
            protectionSpace = URLProtectionSpace(host: self.address, port: self.port.integerValue)
            var credentialStore = URLCredentialStorage.shared
            var credentials = credentialStore.credentials(forProtectionSpace: protectionSpace)!
            print("Credentials: \(credentials)")
            self.credential = (credentials.value(forKey: self.username) as! String)
            print("Using credential: \(credential)")
            return credential
    }

}
//
//  TRNServer.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//
