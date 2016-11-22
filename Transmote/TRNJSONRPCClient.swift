////
////  TRNJSONRPCClient.h
////  Transmote
////
////  Created by Sam Easterby-Smith on 08/02/2014.
////  Copyright (c) 2014 Spotlight Kid. All rights reserved.
////
//
//import AFJSONRPCClient
//import AFNetworking
//
//class TRNJSONRPCClient: AFJSONRPCClient {
//    
//    var sessionID: String?
//
//    convenience override init(endpointURL URL: URL) {
//        self.init(endpointURL: URL)
//        self.responseSerializer.acceptableContentTypes = Set<String>(["application/json", "text/html"])
//        
//    }
//    
//    /** 
//        Transmission likes to send us a session id before we can talk to it
//        It does it by failing the first request with a 409 and providing the new one in the response headers
//        If that happens, we grab the ID and try our initial request again
//        See: https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
//     */
//    
//    override func invokeMethod(_ method: String!, withParameters parameters: Any!, success: ((URLSessionDataTask?, Any?) -> Void)!, failure: ((URLSessionDataTask?, Error?) -> Void)!) {
//        
//    }
//    
//    override func invokeMethod(_ method: String!, withParameters parameters: Any!, requestId: Any!, success: ((URLSessionDataTask?, Any?) -> Void)!, failure: ((URLSessionDataTask?, Error?) -> Void)!) {
//        let wrappedFailureBlock: ((URLSessionDataTask?, Error?) -> Void)! = { (sessionDataTask, error) in
//            if let response = sessionDataTask?.response as? HTTPURLResponse,
//                response.statusCode == 409,
//                let sessionID = response.allHeaderFields["X-Transmission-Session-Id"] as? String {
//                
//                print("Setting session id to \(self.sessionID) and retrying")
//                self.sessionID = sessionID
//                self.requestSerializer.setValue(sessionID, forHTTPHeaderField: "X-Transmission-Session-Id")
//                let request = self.request(withMethod: method, parameters: parameters, requestId: requestId)
//                let dataTask = self.dataTask(with: request as URLRequest){ (response, responseObject, error) in
//                    if response
//                }
//                self.operationQueue.addOperation(dataTask)
//            }
//            
//        }
//    }
//    
//    func invokeMethod(_ method: String, withParameters parameters: Any, requestId: Any, success: @escaping (_ operation: AFHTTPRequestOperation, _ responseObject: Any) -> Void, failure: @escaping (_ operation: AFHTTPRequestOperation, _ error: Error) -> Void) {
//        var wrappedFailureBlock = {(_ operation: AFHTTPRequestOperation, _ error: Error) -> Void in
//                if operation.response.statusCode == 409 {
//                    self.sessionID = (operation.response.allHeaderFields().value(forKey: "X-Transmission-Session-Id") as! String)
//                    print("Setting session id to \(self.sessionID) and retrying")
//                    self.requestSerializer.setValue(self.sessionID, forHTTPHeaderField: "X-Transmission-Session-Id")
//                    var request = self.init(method: method, parameters: parameters, requestId: requestId)
//                    var operation = self.httpRequestOperation(with: request, success: success, failure: failure)
//                    self.operationQueue!.addOperation(operation)
//                }
//                else {
//                    if failure {
//                        failure(operation, error)
//                    }
//                }
//            }
//        var request = self.init(method: method, parameters: parameters, requestId: requestId)
//        var operation = self.httpRequestOperation(with: request, success: success, failure: wrappedFailureBlock)
//        self.operationQueue!.addOperation(operation)
//    }
//    /** This is to change the outgoing "parameters" into "arguments" */
//
//    func request(withMethod method: String, parameters: Any, requestId: Any) -> NSMutableURLRequest {
//        NSParameterAssert(method)
//        if !parameters {
//            parameters = []
//        }
//        assert((parameters is [AnyHashable: Any]) || (parameters is [Any]), "Expect NSArray or NSDictionary in JSONRPC parameters")
//        if !requestId {
//            requestId = (1)
//        }
//        var payload = [AnyHashable: Any]()
//        payload["jsonrpc"] = "2.0"
//        payload["method"] = method
//        payload["arguments"] = parameters
//        payload["id"] = requestId.description
//        do {
//            return try self.requestSerializer(method: "POST", urlString: self.endpointURL.absoluteString, parameters: payload)
//        }
//        catch let error {
//        }
//    }
//    // This is to change the client to return the whole json payload rather than just whatever is in the "result" key
//
//    func httpRequestOperation(with urlRequest: URLRequest, success: @escaping (_ operation: AFHTTPRequestOperation, _ responseObject: Any) -> Void, failure: @escaping (_ operation: AFHTTPRequestOperation, _ error: Error) -> Void) -> AFHTTPRequestOperation {
//        var wrappedSuccessBlock = {(_ operation: AFHTTPRequestOperation, _ responseObject: Any) -> Void in
//                var code = 0
//                var message: String? = nil
//                var data: Any? = nil
//                if (responseObject is [AnyHashable: Any]) {
//                    var result = responseObject
//                        // HERE
//                    var error = responseObject["error"]
//                    if result && result != NSNull() {
//                        if success {
//                            success(operation, result)
//                            return
//                        }
//                    }
//                    else if error && error != NSNull() {
//                        if (error is [AnyHashable: Any]) {
//                            if error["code"] {
//                                code = CInt(error["code"])
//                            }
//                            if error["message"] {
//                                message = error["message"]
//                            }
//                            else if code != 0 {
//                                message = AFJSONRPCLocalizedErrorMessageForCode(code)
//                            }
//
//                            data = error["data"]
//                        }
//                        else {
//                            message = NSLocalizedStringFromTable("Unknown Error", "AFJSONRPCClient", nil)
//                        }
//                    }
//                    else {
//                        message = NSLocalizedStringFromTable("Unknown JSON-RPC Response", "AFJSONRPCClient", nil)
//                    }
//                }
//                else {
//                    message = NSLocalizedStringFromTable("Unknown JSON-RPC Response", "AFJSONRPCClient", nil)
//                }
//                if failure {
//                    var userInfo = [AnyHashable: Any]()
//                    if message != nil {
//                        userInfo[NSLocalizedDescriptionKey] = message
//                    }
//                    if data != nil {
//                        userInfo["data"] = data
//                    }
//                    var error = Error(domain: AFJSONRPCErrorDomain, code: code, userInfo: userInfo)
//                    failure(operation, error)
//                }
//            }
//            // We have to skip over the superclass (the AFJSONRPCClient) to the super-superclass (ie the AFHTTPRequestOperationManager) to call this...
//        var granny = self.superclass.superclass
//        var grannyImp = class_getMethodImplementation(granny, #function)
//        return grannyImp(self, #function, urlRequest, wrappedSuccessBlock, failure)
//    }
//
//}
////
////  TRNJSONRPCClient.m
////  Transmote
////
////  Created by Sam Easterby-Smith on 08/02/2014.
////  Copyright (c) 2014 Spotlight Kid. All rights reserved.
////
//import ObjectiveC
//func AFJSONRPCLocalizedErrorMessageForCode(code: Int) -> String {
//    switch code {
//        case -32700:
//            return "Parse Error"
//        case -32600:
//            return "Invalid Request"
//        case -32601:
//            return "Method Not Found"
//        case -32602:
//            return "Invalid Params"
//        case -32603:
//            return "Internal Error"
//        default:
//            return "Server Error"
//    }
//
//}
