//
//  TRNTorrent.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import "TRNTorrent.h"

@interface TRNTorrent()

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *id;

@property (nonatomic,strong) NSNumber *percentDone;
@property (nonatomic,strong) NSNumber *rateDownload;

@property (nonatomic,strong) NSNumber *ulProgress;
@property (nonatomic,strong) NSNumber *rateUpload;

@property (nonatomic,strong) NSNumber *totalSize;

@end

@implementation TRNTorrent

-(void) importJSONData:(NSDictionary*)data{

    for (NSString *thisKey in data){
        id thisVal=[data valueForKey:thisKey];
        @try {
            [self setValue:thisVal forKey:thisKey];
        }
        @catch (NSException *exception) {
            NSLog(@"Did not set %@ to %@",thisKey,thisVal);
        }

    }
}

@end
