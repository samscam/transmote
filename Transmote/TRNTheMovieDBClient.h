//
//  TRNTheMovieDBClient.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 01/05/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface TRNTheMovieDBClient : NSObject


-(void) fetchMetadataForMovieNamed:(NSString*)movieName year:(NSString*)year onCompletion:(void (^)(NSDictionary *data))completionBlock;
-(void) fetchMetadataForTVShowNamed:(NSString *)showName year:(NSString*)year onCompletion:(void (^)(NSDictionary *))completionBlock;
-(void) fetchDetailsForTVShowWithID:(NSString*)showID season:(NSNumber*)season episode:(NSNumber*)episode onCompletion:(void (^)(NSDictionary*))completionBlock;

-(void) fetchImageAtPath:(NSString*)imagePath onCompletion:(void (^)(NSImage *image))completionBlock;
                                                                   
@end
