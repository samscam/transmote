//
//  TRNTheMovieDBClient.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 01/05/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import "TRNTheMovieDBClient.h"

@interface TRNTheMovieDBClient(){

}
@property (nonatomic,strong) NSMutableDictionary *metadataStore;
@property (nonatomic,strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic,strong) AFHTTPSessionManager *imageSessionManager;

@end

@implementation TRNTheMovieDBClient

static NSString *apiKey = @"***REMOVED***";


-(AFHTTPSessionManager*) sessionManager{
    if (!_sessionManager){
        NSURL *baseURL = [NSURL URLWithString:@"https://api.themoviedb.org/3/"];
        _sessionManager=[[AFHTTPSessionManager alloc] initWithBaseURL:baseURL];
    }
    return _sessionManager;
}

-(void) fetchServiceConfigurationOnCompletion:(void (^) (void))completionBlock{
    [self.sessionManager GET:@"/3/configuration" parameters:@{@"api_key":apiKey} success:^(NSURLSessionDataTask *task, id responseObject) {
        NSString *imageBaseURLString=[(NSDictionary*)responseObject valueForKeyPath:@"images.secure_base_url"];
        self.imageSessionManager=[[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:imageBaseURLString]];
        self.imageSessionManager.responseSerializer=[AFImageResponseSerializer serializer];
        
        completionBlock();
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
    }];
}

-(void) fetchMetadataForMovieNamed:(NSString *)movieName year:(NSString*)year onCompletion:(void (^)(NSDictionary *))completionBlock{
    
    NSString *method=@"search/movie";
    
    NSDictionary *params=[@{@"api_key":apiKey,@"query":movieName} mutableCopy];
    
//    if (year){
//        [params setValue:year forKey:@"year"];
//    }
    
    [self.sessionManager GET:method parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSArray *results=[responseObject valueForKey:@"results"];
        if (results && results.count>0){
            NSDictionary *firstResult=[results objectAtIndex:0];
            completionBlock(firstResult);
        }

    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"error %@",error.localizedDescription);
    } ];
     

}

-(void) fetchMetadataForTVShowNamed:(NSString *)showName onCompletion:(void (^)(NSDictionary *))completionBlock{
    
    NSString *method=@"search/tv";
    
    NSDictionary *params=[@{@"api_key":apiKey,@"query":showName} mutableCopy];
    
    //    if (year){
    //        [params setValue:year forKey:@"year"];
    //    }
    
    [self.sessionManager GET:method parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        NSArray *results=[responseObject valueForKey:@"results"];
        if (results && results.count>0){
            NSDictionary *firstResult=[results objectAtIndex:0];
            completionBlock(firstResult);
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"error %@",error.localizedDescription);
    } ];
    
    
}

-(void) fetchImageAtPath:(NSString*)imagePath onCompletion:(void (^)(NSImage *image))completionBlock{
    void (^wrapBlock)(void)=^{
        NSString *realPath=[@"w342" stringByAppendingPathComponent:imagePath];
        
        [self.imageSessionManager GET:realPath  parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            completionBlock(responseObject);
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"error %@",error.localizedDescription);
        }];
    };
    
    if (!self.imageSessionManager){
        [self fetchServiceConfigurationOnCompletion:wrapBlock];
    } else {
        wrapBlock();
    }

}


@end
