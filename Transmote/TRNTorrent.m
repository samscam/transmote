//
//  TRNTorrent.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import "TRNTorrent.h"
#import "TRNTheMovieDBClient.h"

@interface TRNTorrent()

@property (nonatomic,strong) NSString *id;

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *cleanedName;
@property (nonatomic,strong) NSString *bestName;

@property (nonatomic,strong) NSString *year;
@property (nonatomic,strong) NSString *episode;

@property (nonatomic,strong) NSNumber *percentDone;
@property (nonatomic,strong) NSNumber *rateDownload;

@property (nonatomic,strong) NSNumber *ulProgress;
@property (nonatomic,strong) NSNumber *rateUpload;

@property (nonatomic,strong) NSNumber *totalSize;

@property (nonatomic,strong) NSDictionary *metadata;

@property (nonatomic,strong) NSImage *poster;

@property (nonatomic,weak) TRNServer *server;


@end

@implementation TRNTorrent

-(id) init{
    assert(FALSE);
    return nil;
}

-(id) initWithServer:(TRNServer*)server{
    if ((self=[super init])){
        self.server=server;
    }
    return self;
}

-(void) importJSONData:(NSDictionary*)data{
    
    for (NSString *thisKey in data){
        id thisVal=[data valueForKey:thisKey];
        @try {
            [self setValue:thisVal forKey:thisKey];
        }
        @catch (NSException *exception) {
            NSLog(@"Did not set %@ to %@",thisKey,thisVal);
        }
        if ([thisKey isEqualToString:@"name"] && !_cleanedName){
            // Presume it is new and clean up name
            [self cleanName];
            
            // And then fetch some metadata
            [self fetchMetadata];
        }

    }
    
}

-(void) setCleanedName:(NSString *)cleanedName{
    [self willChangeValueForKey:@"cleanedName"];
    [self willChangeValueForKey:@"bestName"];
    _cleanedName=cleanedName;
    [self didChangeValueForKey:@"cleanedName"];
    [self didChangeValueForKey:@"bestName"];
    
}
-(NSString*) bestName{

    if (_bestName){
        return _bestName;
    }
    if (_cleanedName){
        return _cleanedName;
    }
    
    return _name;
}


-(void) cleanName{
    
    NSError *error=nil;
    
    // Clean up dots, underscores
    NSRegularExpression *cleaner=[NSRegularExpression regularExpressionWithPattern:@"[\\.+_]" options:0 error:&error];
    NSString *semiCleaned=[cleaner stringByReplacingMatchesInString:self.name options:0 range:NSMakeRange(0,self.name.length) withTemplate:@" "];
    
    // Clean things in square brackets
    cleaner=[NSRegularExpression regularExpressionWithPattern:@"\\[.*\\]" options:(NSRegularExpressionCaseInsensitive) error:&error];
    semiCleaned=[cleaner stringByReplacingMatchesInString:semiCleaned options:0 range:NSMakeRange(0,semiCleaned.length) withTemplate:@" "];

    // Clean references to DVD BDRIP and boxset and things
    cleaner=[NSRegularExpression regularExpressionWithPattern:@"(complete|boxset|extras|dvd\\w*?|br\\w*?|blu\\w*?|bd\\w*?)" options:(NSRegularExpressionCaseInsensitive) error:&error];
    semiCleaned=[cleaner stringByReplacingMatchesInString:semiCleaned options:0 range:NSMakeRange(0,semiCleaned.length) withTemplate:@" "];
    
    // Clean runs of whitespace
    cleaner=[NSRegularExpression regularExpressionWithPattern:@"\\s+" options:(NSRegularExpressionCaseInsensitive) error:&error];
    semiCleaned=[cleaner stringByReplacingMatchesInString:semiCleaned options:0 range:NSMakeRange(0,semiCleaned.length) withTemplate:@" "];
    NSLog(@"Semi cleaned name: %@",semiCleaned);
    
    
    
    // Figure out if we have an episode code or season or year or whatnot
    NSRegularExpression *regex=[NSRegularExpression regularExpressionWithPattern:@"(.*?)\\s((\\(?\\d{4}\\)?)|(s\\d+(?:\\s?e\\d+)?)|(season\\s?\\d+))(.*)" options:(NSRegularExpressionCaseInsensitive) error:&error];
    NSTextCheckingResult *result=[regex firstMatchInString:semiCleaned options:0 range:NSMakeRange(0, semiCleaned.length)];
    
    if (!result){
        self.cleanedName=semiCleaned;
        return;
    }
    
    NSString *title=[semiCleaned substringWithRange:[result rangeAtIndex:1]];
    if (!NSEqualRanges([result rangeAtIndex:3],NSMakeRange(NSNotFound,0))){
        self.year=[semiCleaned substringWithRange:[result rangeAtIndex:3]];
    }
    if (!NSEqualRanges([result rangeAtIndex:4],NSMakeRange(NSNotFound,0))){
        self.episode=[semiCleaned substringWithRange:[result rangeAtIndex:4]];
    }
    if (!NSEqualRanges([result rangeAtIndex:5],NSMakeRange(NSNotFound,0))){
        self.episode=[semiCleaned substringWithRange:[result rangeAtIndex:5]];
    }
    NSString *fullyCleaned=[NSString stringWithFormat:@"%@",title];
    NSLog(@"Fully cleaned name: %@",fullyCleaned);
    
    self.cleanedName=fullyCleaned;
}

-(void) fetchMetadata{
    
    // Assume if we have a Season or Episode code that it's TV
    TRNTheMovieDBClient *client=[[TRNTheMovieDBClient alloc] init];
    if (self.episode){
        [client fetchMetadataForTVShowNamed:self.cleanedName onCompletion:^(NSDictionary *data) {
            if (data){
                self.metadata=data;
                self.bestName=[data valueForKey:@"title"];
                NSString *posterPath=[data valueForKey:@"poster_path"];
                [client fetchImageAtPath:posterPath onCompletion:^(NSImage *image) {
                    self.poster=image;
                }];
            }
        }];
    } else {
        // Otherwise assume that it's a movie
        [client fetchMetadataForMovieNamed:self.cleanedName year:self.year onCompletion:^(NSDictionary *data) {
            if (data){
                self.metadata=data;
                self.bestName=[data valueForKey:@"title"];
                NSString *posterPath=[data valueForKey:@"poster_path"];
                [client fetchImageAtPath:posterPath onCompletion:^(NSImage *image) {
                    self.poster=image;
                }];
            }
        }];
    }
}

@end
