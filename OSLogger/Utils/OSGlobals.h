//
//  OSGlobals.h
//  OSLogger
//
//  Created by Osman Söylemez on 14.01.2015.
//  Copyright (c) 2015 Osman Söylemez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OSGlobals : NSObject

+ (NSString *) getCacheFileDirectoryPath;
+ (NSMutableDictionary *) getDictionaryFromPlist:(NSString *) filePath;
+ (NSString *) getLogFilePath;

@end
