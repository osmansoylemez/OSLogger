//
//  AsyncRequest.m
//  VeriBranch
//
//  Created by Veripark (SYLMZ) on 2/6/14.
//
//

#import "AsyncRequest.h"
#import "NSString+Crypto.h"
#import "LanguageManager.h"
#import "NSData+util.h"

@implementation AsyncRequest

@synthesize requestId;

- (void) setRequestId:(NSString *)tRequestId{
    requestId = tRequestId;
    if (![requestId isEqualToString:@""]) {
        [[VPShared sharedInstance] sendLog:[NSString stringWithFormat:@"%@ %@",transactionCalled,requestId]];
    }
}

// Sends an asynchronous HTTP POST request
- (NSString *) sendJSONPostRequest:(NSString*)url body:(NSString*)body{
    synchronizeResponse = FALSE;
    //NSLog(@"url %@ %@",url,body);
    
    NSString *encryptedBody = (body == nil ? @"" : body);
    
    if ([[[VPShared sharedInstance] rSA] publicKeyDict] != nil) {
        
        if (![[[[VPShared sharedInstance] dataEngine] getAESKeyWithRSA] isEqualToString:@""]) {
            
            NSData *encrytedStr = [encryptedBody AES256EncryptWithKey:[[[VPShared sharedInstance] dataEngine] getAESKey] AndIV:[[[VPShared sharedInstance] dataEngine] getAESIV]];
            
            encryptedBody = [encrytedStr base64EncodedString];
            
        }
    }
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithString:url]]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    NSString* requestBodyString = [NSString stringWithString:encryptedBody];
    NSData *requestData = [requestBodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setHTTPMethod: @"POST"];
    [request setValue:@"application/json;utf-8" forHTTPHeaderField:@"content-type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"accept"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPBody: requestData];
    
    if (![[[[VPShared sharedInstance] dataEngine] getAESKeyWithRSA] isEqualToString:@""]) {
        [request setValue:@"AES" forHTTPHeaderField:@"VeriBranch-SymmetricAlgorithm"];
        [request setValue:[[[VPShared sharedInstance] dataEngine] getAESKeyWithRSA] forHTTPHeaderField:@"VeriBranch-SymmetricKey"];
        [request setValue:[[[VPShared sharedInstance] dataEngine] getAESIVWithRSA] forHTTPHeaderField:@"VeriBranch-SymmetricIV"];
        [request setValue:[[[VPShared sharedInstance] dataEngine] getRSAPublicKeyID] forHTTPHeaderField:@"VeriBranch-AsymmetricKey"];
        
    }
    
    if ([[[VPShared sharedInstance] dataEngine] cookie] != NULL) {
        [request setValue:[[[VPShared sharedInstance] dataEngine] cookie] forHTTPHeaderField:@"Cookie"];
    }
    
    if ([[LanguageManager sharedInstance] getLanguageTitle] != nil) {
        [request setValue:[[LanguageManager sharedInstance] getLanguageTitle] forHTTPHeaderField:@"Accept-Language"];
    }
    
    receivedData = [NSMutableData new];
    
    NSURLConnection* con = [NSURLConnection connectionWithRequest:request delegate:self];
    [con start];
    CFRunLoopRun();
    
    if ([requestId isEqualToString:@"handshake"]) {
        NSString * cookie = [NSString stringWithFormat:@"%@",
                             [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Set-Cookie"]];
        NSDictionary *userinfo = [NSDictionary dictionaryWithObject:cookie forKey:@"cookie"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"saveCookie" object:nil userInfo:userinfo];
    }
    
    responseString = [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] copy];
    if (error != nil) {
        responseString = @"";
        [[VPShared sharedInstance] sendLog:[NSString stringWithFormat:@"%@ : %@ - %@",transactionCallUnSuccesfully,requestId,error.description]];
    }else{
        if (![[[[VPShared sharedInstance] dataEngine] getAESKeyWithRSA] isEqualToString:@""]) {
            NSData *decodedData = [NSData dataFromBase64String:responseString];

            NSData *decryptedData = [decodedData AES256DecryptWithKey:[[[VPShared sharedInstance] dataEngine] getAESKey] AndIV:[[[VPShared sharedInstance] dataEngine] getAESIV]];
            responseString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
        }
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

@end
