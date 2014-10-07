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
@property (nonatomic,strong) NSNumber *season;
@property (nonatomic,strong) NSNumber *episode;

@property (nonatomic,copy) NSString *episodeTitle;

@property (nonatomic,strong) NSNumber *percentDone;
@property (nonatomic,strong) NSNumber *rateDownload;

@property (nonatomic,strong) NSDate *eta;

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
            
            if ([thisKey isEqualToString:@"eta"]){
                self.eta=[NSDate dateWithTimeIntervalSinceNow:[thisVal doubleValue]];
            } else {
                [self setValue:thisVal forKey:thisKey];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Did not set %@ to %@",thisKey,thisVal);
        }

    }
    
}

-(void) setName:(NSString *)name{
    if ([name isEqualToString:_name]){
        return;
    }
    
    [self willChangeValueForKey:@"name"];
    _name=name;
    [self didChangeValueForKey:@"name"];
    
    if (_name){
        // Presume it is new and clean up name
        [self cleanName];
        
        // And then fetch some metadata
        [self fetchMetadata];
    }
    
}

-(void) setCleanedName:(NSString *)cleanedName{
    if ([cleanedName isEqualToString:_cleanedName]){
        return;
    }
    
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
    NSRegularExpression *cleaner=[NSRegularExpression regularExpressionWithPattern:@"[\\[\\]\\(\\)\\.+_-]" options:0 error:&error];
    NSString *semiCleaned=[cleaner stringByReplacingMatchesInString:self.name options:0 range:NSMakeRange(0,self.name.length) withTemplate:@" "];
    
    // Clean references to DVD BDRIP and boxset and things
    cleaner=[NSRegularExpression regularExpressionWithPattern:@"\\b(1080p|720p|x264|dts|aac|complete|boxset|extras|dvd\\w*?|br|bluray|bd\\w*?)\\b" options:(NSRegularExpressionCaseInsensitive) error:&error];
    semiCleaned=[cleaner stringByReplacingMatchesInString:semiCleaned options:0 range:NSMakeRange(0,semiCleaned.length) withTemplate:@" "];
    
    // Clean runs of whitespace
    cleaner=[NSRegularExpression regularExpressionWithPattern:@"\\s+" options:(NSRegularExpressionCaseInsensitive) error:&error];
    semiCleaned=[cleaner stringByReplacingMatchesInString:semiCleaned options:0 range:NSMakeRange(0,semiCleaned.length) withTemplate:@" "];
    NSLog(@"Semi cleaned name: %@",semiCleaned);
    
    
    
    // Figure out if we have an episode code or season or year or whatnot
    //@"^(.+?)\\s*(?:\\W*(?:(\\b\\d{4}\\b)|(?:\\bs?(\\d+)[ex](\\d+)))){1,2}";
    NSString *pattern=@"^(.+?)\\s*(?:\\W*(?:(\\b\\d{4}\\b)|(?:\\b(?:s\\s?\\s?)?(\\d+)(?:(?:ep|episode|[ex]){1}\\s?(\\d+\\b)))|(?:season\\s?(\\d+)))){1,2}";
    NSRegularExpression *regex=[NSRegularExpression regularExpressionWithPattern:pattern options:(NSRegularExpressionCaseInsensitive) error:&error];
    
    NSTextCheckingResult *result=[regex firstMatchInString:semiCleaned options:0 range:NSMakeRange(0, semiCleaned.length)];
    
    if (!result){
        self.cleanedName=semiCleaned;
        return;
    }
    
    NSString *title=[semiCleaned substringWithRange:[result rangeAtIndex:1]];
    
    if (!NSEqualRanges([result rangeAtIndex:2],NSMakeRange(NSNotFound,0))){
        self.year=[semiCleaned substringWithRange:[result rangeAtIndex:2]];
    }

    if (!NSEqualRanges([result rangeAtIndex:3],NSMakeRange(NSNotFound,0))){
        self.season=[NSNumber numberWithInteger:[[semiCleaned substringWithRange:[result rangeAtIndex:3]] integerValue]];
    } else if (!NSEqualRanges([result rangeAtIndex:5],NSMakeRange(NSNotFound,0))){
        self.season=[NSNumber numberWithInteger:[[semiCleaned substringWithRange:[result rangeAtIndex:5]] integerValue]];
    }
    
        if (!NSEqualRanges([result rangeAtIndex:4],NSMakeRange(NSNotFound,0))){
            self.episode=[NSNumber numberWithInteger:[[semiCleaned substringWithRange:[result rangeAtIndex:4]] integerValue]];
        }
    
    
        

    NSString *fullyCleaned=[NSString stringWithFormat:@"%@",title];
    NSLog(@"Fully cleaned name: %@",fullyCleaned);
    
    self.cleanedName=fullyCleaned;
}

-(void) fetchMetadata{
    
    // Assume if we have a Season or Episode code that it's TV
    TRNTheMovieDBClient *client=[[TRNTheMovieDBClient alloc] init];
    if (self.season){
        [client fetchMetadataForTVShowNamed:self.cleanedName year:self.year onCompletion:^(NSDictionary *data) {
            if (data){
                self.metadata=data;
                self.bestName=[data valueForKey:@"title"];
                NSString *showID=[data valueForKey:@"id"];
                
                if (self.episode && self.season){
                    [client fetchDetailsForTVShowWithID:showID season:self.season episode:self.episode onCompletion:^(NSDictionary *res) {
                        // somethign
                        self.episodeTitle=[res valueForKey:@"name"];
                        NSString *posterPath=[res valueForKey:@"still_path"];
                        [client fetchImageAtPath:posterPath onCompletion:^(NSImage *image) {
                            self.poster=image;
                        }];
                    } ];
                } else {
                    NSString *posterPath=[data valueForKey:@"poster_path"];
                    [client fetchImageAtPath:posterPath onCompletion:^(NSImage *image) {
                        self.poster=image;
                    }];
                }
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
