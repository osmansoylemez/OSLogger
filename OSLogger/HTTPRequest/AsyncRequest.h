//
//  AsyncRequest.h
//  VeriBranch
//
//  Created by Veripark (SYLMZ) on 2/6/14.
//
//

#import <Foundation/Foundation.h>

@interface AsyncRequest : NSObject{
    NSMutableData* httpResponse;
    NSString *responseString;
    
    NSURLResponse *response;
    NSMutableData *receivedData;
    NSError *error;
}

- (NSString *) sendJSONPostRequest:(NSString*)url body:(NSString*)body;

@end
