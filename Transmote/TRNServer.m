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

@interface TRNServer()

@property (nonatomic,readwrite) BOOL connected;
@property (nonatomic,readwrite) NSMutableArray *torrents;
@property (nonatomic,readwrite) NSMutableDictionary *torrentDict;
@property (nonatomic,strong) TRNJSONRPCClient *client;
@property (nonatomic,strong) NSTimer *timer;

@end

@implementation TRNServer

static void *obvContext=&obvContext;

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
        
        
        [self addObserver:self forKeyPath:@"rpcPath" options:NSKeyValueObservingOptionNew context:obvContext];
        [self addObserver:self forKeyPath:@"address" options:NSKeyValueObservingOptionNew context:obvContext];
        [self addObserver:self forKeyPath:@"port" options:NSKeyValueObservingOptionNew context:obvContext];
    }
    return self;
}

-(void) tryToConnect{
    [self connect];
}

-(void) connect{

    [self.torrentDict removeAllObjects];
    [self.torrents removeAllObjects];

    [self.timer invalidate];
    self.timer=nil;
    
    self.client=[TRNJSONRPCClient clientWithEndpointURL:[self serverURL]];
    
    [self.client invokeMethod:@"session-get" success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //WOO
        NSLog(@"Session alive\n%@",responseObject);
        self.connected=YES;
        self.timer=[NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateTorrents:) userInfo:nil repeats:YES];
        
        // Check for a deferred URL
        TRNAppDelegate *appDelegate=[NSApp delegate];
        if (appDelegate.deferredMagnetURL){
            [self addMagnetLink:appDelegate.deferredMagnetURL];
            appDelegate.deferredMagnetURL=nil;
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //BOO
        self.connected=NO;
        [self.timer invalidate];
        self.timer=nil;
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
        NSLog(@"Looks like we win...");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Torrent Fails");
    }];
}

-(NSURL*) serverURL{
    NSURL *theURL=[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@/%@",self.address,self.port,self.rpcPath]];
    return theURL;
}

-(void) updateTorrents:(id)timer{
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
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        
    }];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if (context==&obvContext){
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




@end
