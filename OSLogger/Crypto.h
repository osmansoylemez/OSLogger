//
//  Crypto.h
//  SOAPTest
//
//  Created by Veripark (SYLMZ) on 6/27/13.
//  Copyright (c) 2013 Veripark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Crypto : NSObject

+ (NSString *) iDecodeString:(NSString *)str;
+ (NSString *) iCodedStringWithDate:(NSString *)str;
+ (NSString *) getDate;
+ (NSString *) getDateNow;
+ (void) saveData:(NSString *)value withKey:(NSString *)key;
+ (NSString *) getDataWithKey:(NSString *)key;
+ (NSString *)base64Encode:(NSString *)plainText;
+ (NSString *)base64Decode:(NSString *)base64String;
@end
