//
//  NSData+util.h
//  VeriBranch
//
//  Created by Veripark (SYLMZ) on 5/7/14.
//
//

#import <Foundation/Foundation.h>

void *NewBase64Decode(
                      const char *inputBuffer,
                      size_t length,
                      size_t *outputLength);

char *NewBase64Encode(
                      const void *inputBuffer,
                      size_t length,
                      bool separateLines,
                      size_t *outputLength);

@interface NSData (util)

+ (NSData *) dataFromBase64String:(NSString *)aString;
- (NSString *) base64EncodedString;
- (NSData *) AES256DecryptWithKey:(NSString*)key AndIV:(NSString *) iv;

@end
