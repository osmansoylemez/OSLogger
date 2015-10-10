//
//  OSLogger.h
//
//  Created by Matt Coneybeare on 09/1/13.
//  Copyright (c) 2013 Urban Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    OSLogger_LogLevelUnset = 0,		// Unset means it is not factored in on the decision to log
    OSLogger_LogLevelDebug,			// Lowest log level
    OSLogger_LogLevelInfo,
    OSLogger_LogLevelWarn,
    OSLogger_LogLevelError,
    OSLogger_LogLevelFatal			// Highest log level
} OSLogger_LogLevel;

#define OSLog( format, ... )			OSLogWithLevel( OSLogger_LogLevelUnset, format, ##__VA_ARGS__ )

#define OSLogWithLevel( s, f, ... ) [OSLogger logWithLogLevel:s\
                                                formatArgs:@[\
                                                            [[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
                                                            [NSNumber numberWithInt:__LINE__],\
                                                            [NSString stringWithFormat:(f), ##__VA_ARGS__]\
                                                ]\
                                            ]

@interface OSLogger : NSObject

+ (void)setMinimumLogLevel:(OSLogger_LogLevel)LogLevel;
+ (OSLogger_LogLevel)minimumLogLevel;							// Defaults to OSLogger_LogLevelUnset (not used in determining whether or not to log)
+ (BOOL)usingLogLevelFiltering;									// Yes if minimumLogLevel has been set.
+ (BOOL)meetsMinimumLogLevel:(OSLogger_LogLevel)LogLevel;		// Yes if LogLevel is greater than or equal to minimumLogLevel

+ (BOOL)isProduction;											// Returns YES when DEBUG is not present in the Preprocessor Macros
+ (BOOL)shouldLogInProduction;									// Default is NO.
+ (BOOL)shouldLogInDebug;										// Default is YES.
+ (void)setShouldLogInProduction:(BOOL)shouldLogInProduction;
+ (void)setShouldLogInDebug:(BOOL)shouldLogInDebug;
+ (BOOL)loggingEnabled;											// returns true if (not production and shouldLogInDebug) OR (production build and shouldLogInProduction) or (userDefaultsOverride == YES)

+ (void)log:(NSString *)format, ...;							// Logs a format, and variables for the format.
+ (void)logWithLogLevel:(OSLogger_LogLevel)LogLevel formatArgs:(NSArray *)args;

+ (NSString *)bundleName;
+ (void) setBundleName:(NSString *)bundleName;
+ (void) getApplicationLog:(void (^)(NSArray *logs))onComplete;
+ (NSString *)applicationLog;
@end