//
//  TRNJSONRPCClient.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import "TRNJSONRPCClient.h"
#import <objc/runtime.h>

static NSString * AFJSONRPCLocalizedErrorMessageForCode(NSInteger code) {
    switch(code) {
        case -32700:
            return @"Parse Error";
        case -32600:
            return @"Invalid Request";
        case -32601:
            return @"Method Not Found";
        case -32602:
            return @"Invalid Params";
        case -32603:
            return @"Internal Error";
        default:
            return @"Server Error";
    }
}

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

    // Transmission likes to send us a session id before we can talk to it
    // It does it by failing the first request with a 409 and providing the new one in the response headers
    // If that happens, we grab the ID and try our initial request again
    // See: https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
    
    void  (^wrappedFailureBlock)(AFHTTPRequestOperation *operation, NSError *error)  =^(AFHTTPRequestOperation *operation, NSError *error){
        if ([operation.response statusCode] == 409){
            self.sessionID=[[operation.response allHeaderFields] valueForKey:@"X-Transmission-Session-Id"];
            NSLog(@"Setting session id to %@ and retrying",self.sessionID);
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
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:wrappedFailureBlock];
    [self.operationQueue addOperation:operation];
}

// THIS is to change the outgoing "parameters" into "arguments"

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                parameters:(id)parameters
                                 requestId:(id)requestId
{
    NSParameterAssert(method);
    
    if (!parameters) {
        parameters = @[];
    }
    
    NSAssert([parameters isKindOfClass:[NSDictionary class]] || [parameters isKindOfClass:[NSArray class]], @"Expect NSArray or NSDictionary in JSONRPC parameters");
    
    if (!requestId) {
        requestId = @(1);
    }
    
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"jsonrpc"] = @"2.0";
    payload[@"method"] = method;
    payload[@"arguments"] = parameters;
    payload[@"id"] = [requestId description];
    
    return [self.requestSerializer requestWithMethod:@"POST" URLString:[self.endpointURL absoluteString] parameters:payload error:nil];
}

// THIS is to change the incoming JSON to not dump everything other than the "result"

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    void (^wrappedSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject){
        NSInteger code = 0;
        NSString *message = nil;
        id data = nil;
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            id result = responseObject;// HERE
            id error = responseObject[@"error"];
            
            if (result && result != [NSNull null]) {
                if (success) {
                    success(operation, result);
                    return;
                }
            } else if (error && error != [NSNull null]) {
                if ([error isKindOfClass:[NSDictionary class]]) {
                    if (error[@"code"]) {
                        code = [error[@"code"] integerValue];
                    }
                    
                    if (error[@"message"]) {
                        message = error[@"message"];
                    } else if (code) {
                        message = AFJSONRPCLocalizedErrorMessageForCode(code);
                    }
                    
                    data = error[@"data"];
                } else {
                    message = NSLocalizedStringFromTable(@"Unknown Error", @"AFJSONRPCClient", nil);
                }
            } else {
                message = NSLocalizedStringFromTable(@"Unknown JSON-RPC Response", @"AFJSONRPCClient", nil);
            }
        } else {
            message = NSLocalizedStringFromTable(@"Unknown JSON-RPC Response", @"AFJSONRPCClient", nil);
        }
        
        if (failure) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            if (message) {
                userInfo[NSLocalizedDescriptionKey] = message;
            }
            
            if (data) {
                userInfo[@"data"] = data;
            }
            
            NSError *error = [NSError errorWithDomain:AFJSONRPCErrorDomain code:code userInfo:userInfo];
            
            failure(operation, error);
        }
    };
    
    Class granny = [[self superclass] superclass];
    IMP grannyImp = class_getMethodImplementation(granny, _cmd);
    return grannyImp(self, _cmd,urlRequest,wrappedSuccessBlock,failure);
    
}
@end
