//
//  GeneralObject.m
//  EnglishGame
//
//  Created by Osman Söylemez on 17.10.2012.
//  Copyright (c) 2012 Osman Söylemez. All rights reserved.
//

#import "Crypto.h"
#import "NSData+util.h"
#import "NSUserDefaults+MPSecureUserDefaults.h"

@implementation Crypto

+ (NSString *) getDateNow{
    NSDate *today = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:today];
    return dateString ;
}

+ (NSString *) getDate{
    NSDate *today = [[NSDate alloc] init] ;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH-mm-ss"];
    NSString *dateString = [dateFormatter stringFromDate:today];
    return dateString ;
}

+ (NSString *) iCodedStringWithDate:(NSString *)str{
    NSString *codedValue = [self base64Encode:str];
    NSString *codedDateValue = [[self base64Encode:[self getDate]] substringToIndex:10];
    NSString *encodeValue = [NSString stringWithFormat:@"%@%@%@",[codedValue substringWithRange:NSMakeRange(0,2)],codedDateValue,[codedValue substringFromIndex:2]];
    return encodeValue;
}

+ (NSString *) iDecodeString:(NSString *)str{
    NSString *decodeValue = [NSString stringWithFormat:@"%@%@",[str substringWithRange:NSMakeRange(0,2)],[str substringFromIndex:12]];
    return decodeValue;
}

+ (void) saveData:(NSString *)value withKey:(NSString *)key{
    NSString *encodeValue = value;
    [NSUserDefaults setSecret:@"Bu uygulama Veripark tarafından yazılmıştır."];
    if (![value isEqualToString:@""]) {
        encodeValue = [self iCodedStringWithDate:value];
    }
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setSecureObject:encodeValue forKey:key];
    [prefs synchronize];
}

+ (NSString *) getDataWithKey:(NSString *)key{
    [NSUserDefaults setSecret:@"Bu uygulama Veripark tarafından yazılmıştır."];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    BOOL valid = NO;
    NSString *value = [prefs secureObjectForKey:key valid:&valid];
    NSString *decodeValue = [self iDecodeString:value];
    return [self base64Decode:decodeValue];
}

+ (NSString *)base64Encode:(NSString *)plainText{
    NSData *plainTextData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainTextData base64EncodedString];
    return base64String;
}

+ (NSString *)base64Decode:(NSString *)base64String{
    NSData *plainTextData = [NSData dataFromBase64String:base64String];
    NSString *plainText = [[NSString alloc] initWithData:plainTextData encoding:NSUTF8StringEncoding];
    return plainText;
}



@end