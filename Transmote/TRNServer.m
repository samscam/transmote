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
        
        self.address=@"drobo5n.local";
        self.port=@"9091";
        self.rpcPath=@"transmission/rpc";
        
        [self addObserver:self forKeyPath:@"rpcPath" options:NSKeyValueObservingOptionNew context:obvContext];
        [self addObserver:self forKeyPath:@"address" options:NSKeyValueObservingOptionNew context:obvContext];
        [self addObserver:self forKeyPath:@"port" options:NSKeyValueObservingOptionNew context:obvContext];
    }
    return self;
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
            
            for (NSDictionary *thisTData in incomingTorrents){
                NSString *torrentID=[thisTData valueForKey:@"id"];
                TRNTorrent *importTo=[self.torrentDict objectForKey:torrentID];
                if (!importTo){
                    importTo=[[TRNTorrent alloc] init];
                    [self.torrents addObject:importTo];
                    [self.torrentDict setObject:importTo forKey:torrentID];
                }
                [importTo importJSONData:thisTData];
                
            }
            
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        
    }];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if (context==&obvContext){
        [self connect];
        return;
    }
    
    return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
}


@end
