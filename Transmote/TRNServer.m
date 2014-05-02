//
//  TRNServer.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import "TRNServer.h"
#import "TRNTorrent.h"

#import "TRNJSONRPCClient.h"
#import "TRNAppDelegate.h"

@interface TRNServer(){
    BOOL connecting;
    BOOL updating;
}

@property (nonatomic,readwrite) BOOL connected;
@property (nonatomic,readwrite) NSMutableArray *torrents;
@property (nonatomic,readwrite) NSMutableDictionary *torrentDict;
@property (nonatomic,strong) TRNJSONRPCClient *client;
@property (nonatomic,strong) NSTimer *timer;

@end

@implementation TRNServer

static void *connectionContext=&connectionContext;

-(id) init{
    
    if ((self=[super init])){

        self.torrents=[[NSMutableArray alloc] init];
        self.torrentDict=[[NSMutableDictionary alloc] init];
        
        NSUserDefaultsController *userDefaultsController=[NSUserDefaultsController sharedUserDefaultsController];
        
        [self bind:@"address"
          toObject:userDefaultsController
       withKeyPath:@"values.address"
           options:@{NSContinuouslyUpdatesValueBindingOption : @YES }];
        
        
        [self bind:@"port"
          toObject:userDefaultsController
       withKeyPath:@"values.port"
           options:@{NSContinuouslyUpdatesValueBindingOption : @YES }];
        
        [self bind:@"rpcPath"
          toObject:userDefaultsController
       withKeyPath:@"values.rpcPath"
           options:@{NSContinuouslyUpdatesValueBindingOption : @YES }];
        
        
        [self addObserver:self forKeyPath:@"rpcPath" options:NSKeyValueObservingOptionNew context:connectionContext];
        [self addObserver:self forKeyPath:@"address" options:NSKeyValueObservingOptionNew context:connectionContext];
        [self addObserver:self forKeyPath:@"port" options:NSKeyValueObservingOptionNew context:connectionContext];
        
        [self tryToConnect];
    }
    return self;
}

-(void) tryToConnect{
    self.timer=[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES];
    [self connect];
}

-(void) timerDidFire:(id)timer{
    // the timer will fire every three seconds...
    // we should probably make this configurable...

    if (self.connected){
        // if we are connected update the torrents
        [self updateTorrents];
    } else {
        // otherwise, have another bash at connecting
        // should probably throttle this down if it fails a few times
        [self connect];
    }
}

-(void) connect{
    if (connecting){
        return;
    }
    
    connecting=YES;
    [self.torrentDict removeAllObjects];
    [self.torrents removeAllObjects];
    
    self.client=[TRNJSONRPCClient clientWithEndpointURL:[self serverURL]];
    
    [self.client invokeMethod:@"session-get" success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //WOO
        NSLog(@"Session alive\n%@",responseObject);
        self.connected=YES;
        connecting=NO;
        
        // force an immediate update of torrents
        [self updateTorrents];
        
        // Check for a deferred URL
        TRNAppDelegate *appDelegate=[NSApp delegate];
        if (appDelegate.deferredMagnetURL){
            [self addMagnetLink:appDelegate.deferredMagnetURL];
            appDelegate.deferredMagnetURL=nil;
        }
        connecting=NO;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // This will get called on session negotiation.. so don't trust it
        self.connected=NO;
        connecting=NO;
    }];
    
}
-(void) disconnect{
    self.connected=NO;
    self.client=nil;
    [self.timer invalidate];
    self.timer=nil;
}
-(void) addMagnetLink:(NSURL*)magnetLink{
    
    [self.client invokeMethod:@"torrent-add" withParameters:@{@"filename":[magnetLink absoluteString]}  success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Torrent added: %@",responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Torrent failed to add: %@",error.localizedDescription);
    }];
}

-(NSURL*) serverURL{
    NSURL *theURL=[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@/%@",self.address,self.port,self.rpcPath]];
    return theURL;
}



-(void) updateTorrents{
    if (updating){
        return;
    }
    
    updating=YES;
    [self.client invokeMethod:@"torrent-get" withParameters:@{@"fields":@[@"id",@"name",@"totalSize",@"rateDownload",@"rateUpload",@"percentDone"]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSDictionary *responseDict=(NSDictionary*)responseObject;
        
        if ([responseDict valueForKeyPath:@"arguments.torrents"]){
            NSArray *incomingTorrents=[responseDict valueForKeyPath:@"arguments.torrents"];
            NSMutableArray *foundTorrentKeys=[[NSMutableArray alloc] init];
            for (NSDictionary *thisTData in incomingTorrents){
                NSString *torrentID=[thisTData valueForKey:@"id"];
                TRNTorrent *importTo=[self.torrentDict objectForKey:torrentID];
                if (!importTo){
                    importTo=[[TRNTorrent alloc] initWithServer:self];
                    [self willChangeValueForKey:@"torrents"]; // This feels a bit nasty - forces the array controller to do initial update
                    [self.torrents addObject:importTo];
                    [self.torrentDict setObject:importTo forKey:torrentID];
                    [self didChangeValueForKey:@"torrents"];
                }
                [foundTorrentKeys addObject:torrentID];
                [importTo importJSONData:thisTData];
            }
            
            NSMutableArray *deleteKeys=[[self.torrentDict allKeys] mutableCopy];
            [deleteKeys removeObjectsInArray:foundTorrentKeys];
            NSArray *torrentsToDelete=[self.torrentDict objectsForKeys:deleteKeys notFoundMarker:[NSNull null]];
            if (torrentsToDelete.count>0){
                [self willChangeValueForKey:@"torrents"];
                [self.torrentDict removeObjectsForKeys:deleteKeys];
                [self.torrents removeObjectsInArray:torrentsToDelete];
                [self didChangeValueForKey:@"torrents"];
            }
            
        }
        updating=NO;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Some error occured... assume we have been disconnected...
        self.connected=NO;
        updating=NO;
    }];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if (context==&connectionContext){
        // The user edited the connection details - force a reconnect
        connecting=NO;
        [self connect];
        [self updateDefaults];
        return;
    }
    
    return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
}

-(void) updateDefaults{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    [defaults setValue:self.address forKey:@"address"];
    [defaults setValue:self.rpcPath forKey:@"rpcPath"];
    [defaults setValue:self.port forKey:@"port"];
}


-(void) removeTorrents:(NSArray*)torrentsToDelete deleteData:(BOOL)delete {
    NSMutableArray *torrentIDs=[[NSMutableArray alloc] init];
    for (TRNTorrent *thisTorrent in torrentsToDelete){
        [torrentIDs addObject:thisTorrent.id];
    }
    
    [self.client invokeMethod:@"torrent-remove" withParameters:@{@"ids":torrentIDs,@"delete-local-data":[NSNumber numberWithBool:delete]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Looks like it has gone.
        // Remove it locally too
        
        [self willChangeValueForKey:@"torrents"];// force the array controller to spot the change
        [self.torrentDict removeObjectsForKeys:torrentIDs];
        [self.torrents removeObjectsInArray:torrentsToDelete];
        [self didChangeValueForKey:@"torrents"];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Some error occured... assume we have been disconnected...
        self.connected=NO;
    }];

}

@end
