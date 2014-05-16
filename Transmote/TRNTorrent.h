//
//  TRNTorrent.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TRNServer;

@interface TRNTorrent : NSObject


@property (nonatomic,readonly) NSString *id;

@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly) NSString *bestName;
@property (nonatomic,readonly) NSImage *poster;

@property (nonatomic,readonly) NSNumber *percentDone;
@property (nonatomic,readonly) NSNumber *rateDownload;
@property (nonatomic,readonly) NSDate *eta;

@property (nonatomic,readonly) NSNumber *ulProgress;
@property (nonatomic,readonly) NSNumber *rateUpload;
@property (nonatomic,readonly) NSNumber *totalSize;

@property (nonatomic,weak,readonly) TRNServer *server;

-(id) initWithServer:(TRNServer*)server;
-(void) importJSONData:(NSDictionary*)data;

@end
