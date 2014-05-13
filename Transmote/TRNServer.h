//
//  TRNServer.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TRNServer : NSObject

@property (nonatomic,strong) NSString *address;
@property (nonatomic,strong) NSString *port;
@property (nonatomic,strong) NSString *rpcPath;
@property (nonatomic,strong) NSString *username;
@property (nonatomic,strong) NSString *password;

@property (nonatomic,readonly) BOOL connected;
@property (nonatomic,readonly) NSMutableArray *torrents;



-(void) tryToConnect;
-(void) disconnect;
-(void) addMagnetLink:(NSURL*)magnetLink;

-(void) removeTorrents:(NSArray*)torrentsToDelete deleteData:(BOOL)delete;


@end
