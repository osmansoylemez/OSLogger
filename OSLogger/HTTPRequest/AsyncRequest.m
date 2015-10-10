//
//  AsyncRequest.m
//  VeriBranch
//
//  Created by Veripark (SYLMZ) on 2/6/14.
//
//

#import "AsyncRequest.h"
#import "NSString+util.h"
#import "NSData+util.h"

@implementation AsyncRequest

// Sends an asynchronous HTTP POST request
- (NSString *) sendJSONPostRequest:(NSString*)url body:(NSString*)body{

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithString:url]]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    NSString* requestBodyString = [NSString stringWithString:body];
    NSData *requestData = [requestBodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setHTTPMethod: @"POST"];
    [request setValue:@"application/json;utf-8" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPBody: requestData];
    
    receivedData = [NSMutableData new];
    
    NSURLConnection* con = [NSURLConnection connectionWithRequest:request delegate:self];
    [con start];
    CFRunLoopRun();
    
    responseString = [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] copy];
    if (error != nil) {
        responseString = @"";
        //[[VPShared sharedInstance] sendLog:[NSString stringWithFormat:@"%@ : %@ - %@",transactionCallUnSuccesfully,requestId,error.description]];
    }
    return responseString ? responseString : @"";
}

#pragma mark Delegate Methods

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *) tResponse{
    response = tResponse;
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *) data{
    [receivedData appendData:data];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *) tError{
    error = tError;
    NSLog(@"%@",error.description);
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection{
    CFRunLoopStop(CFRunLoopGetCurrent());
}

/*
- (void) connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURL* baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@",serviceURL]];
        if ([challenge.protectionSpace.host isEqualToString:baseURL.host]) {
            NSLog(@"trusting connection to host %@", challenge.protectionSpace.host);
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        } else
            NSLog(@"Not trusting connection to host %@", challenge.protectionSpace.host);
    }
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}
*/

@end
