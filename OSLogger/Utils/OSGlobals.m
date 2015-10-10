//
//  OSGlobals.m
//  OSLogger
//
//  Created by Osman Söylemez on 14.01.2015.
//  Copyright (c) 2015 Osman Söylemez. All rights reserved.
//

#import "OSGlobals.h"

@implementation OSGlobals

+ (NSString *) getCacheFileDirectoryPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSMutableDictionary *) getDictionaryFromPlist:(NSString *) filePath{
    NSMutableDictionary *dictionary = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:filePath]) {
        dictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    }else{
        dictionary = [[NSMutableDictionary alloc] init];
    }
    return dictionary;
}

+ (NSString *) getLogFilePath{
    return [[OSGlobals getCacheFileDirectoryPath] stringByAppendingPathComponent:@"LogFile.plist"];
}

@end
