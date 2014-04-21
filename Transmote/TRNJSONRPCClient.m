//
//  TRNJSONRPCClient.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import "TRNJSONRPCClient.h"

@interface TRNJSONRPCClient()

@property (nonatomic,strong) NSString *sessionID;

@end

@implementation TRNJSONRPCClient
- (id)initWithEndpointURL:(NSURL *)URL {
    
    if ((self=[super initWithEndpointURL:URL])){
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/html",nil];
    }
    return self;
}

- (void)invokeMethod:(NSString *)method
      withParameters:(id)parameters
           requestId:(id)requestId
             success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
             failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{

    
    void  (^wrapFailureBlock)(AFHTTPRequestOperation *operation, NSError *error)  =^(AFHTTPRequestOperation *operation, NSError *error){
        if ([operation.response statusCode] == 409){
            self.sessionID=[[operation.response allHeaderFields] valueForKey:@"X-Transmission-Session-Id"];
            NSLog(@"setting session id to %@ and retrying",self.sessionID);
            [self.requestSerializer setValue:self.sessionID forHTTPHeaderField:@"X-Transmission-Session-Id"];
            NSMutableURLRequest *request = [self requestWithMethod:method parameters:parameters requestId:requestId];
            AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
            [self.operationQueue addOperation:operation];
        } else {
            if (failure){
                failure(operation,error);
            }
        }
    };
    
    NSMutableURLRequest *request = [self requestWithMethod:method parameters:parameters requestId:requestId];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:wrapFailureBlock];
    [self.operationQueue addOperation:operation];
}



@end
