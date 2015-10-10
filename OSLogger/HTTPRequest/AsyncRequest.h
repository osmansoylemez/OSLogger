//
//  AsyncRequest.h
//  VeriBranch
//
//  Created by Veripark (SYLMZ) on 2/6/14.
//
//

#import <Foundation/Foundation.h>

@interface AsyncRequest : NSObject<UIWebViewDelegate>{
    NSMutableData* httpResponse;
    NSString *rUrl;
    NSString *rBody;
    NSString *responseString;
    BOOL synchronizeResponse;
    
    NSURLResponse *response;
    NSMutableData *receivedData;
    NSError *error;
    
    NSData* salt;
    NSData *key;

}

@property (nonatomic) int index;
@property (nonatomic,assign) NSString *requestId;

- (NSString *) sendJSONPostRequest:(NSString*)url body:(NSString*)body;

@end
