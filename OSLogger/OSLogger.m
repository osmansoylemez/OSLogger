//
//  OSLogger.m
//
//  Created by Matt Coneybeare on 09/1/13.
//  Copyright (c) 2013 Urban Apps, LLC. All rights reserved.
//

#import "OSLogger.h"
#import "OSCrashReporter.h"
#import <CrashReporter/CrashReporter.h>
#import <asl.h>

static BOOL				shouldLogInProduction	= NO;
static BOOL				shouldLogInDebug		= YES;
static NSString			*appBundleName			= nil;
static OSLogger_LogLevel	minimumLogLevel		= OSLogger_LogLevelUnset;


@implementation OSLogger

#pragma mark - Setup

+ (void) initialize {
    [super initialize];
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSError *error;
    
    // Check if we previously crashed
    if ([crashReporter hasPendingCrashReport]){
        [OSCrashReporter handleCrashReport];
    }
    // Enable the Crash Reporter
    if (![crashReporter enableCrashReporterAndReturnError: &error]){
        NSLog(@"Warning: Could not enable crash reporter: %@", error);
    }
    [OSCrashReporter pushLogString];
}

+ (void)setMinimumLogLevel:(OSLogger_LogLevel)LogLevel {
    minimumLogLevel = LogLevel;
}

+ (OSLogger_LogLevel)minimumLogLevel {
    return minimumLogLevel;
}

+ (NSString *)labelForLogLevel:(OSLogger_LogLevel)LogLevel {
    switch (LogLevel) {
        case OSLogger_LogLevelDebug: return @"DEBUG";
        case OSLogger_LogLevelInfo:  return @"INFO";
        case OSLogger_LogLevelWarn:	return @"WARN";
        case OSLogger_LogLevelError:	return @"ERROR";
        case OSLogger_LogLevelFatal:	return @"FATAL";
        default: return @"";
    }
}

+ (BOOL)usingLogLevelFiltering {
    return OSLogger_LogLevelUnset != [OSLogger minimumLogLevel];
}

+ (BOOL)meetsMinimumLogLevel:(OSLogger_LogLevel)LogLevel {
    return LogLevel >= [OSLogger minimumLogLevel];
}

+ (BOOL)shouldLogInProduction {
    return shouldLogInProduction;
}

+ (void)setShouldLogInProduction:(BOOL)shouldLogInProduction {
    shouldLogInProduction = shouldLogInProduction;
}

+ (BOOL)shouldLogInDebug {
    return shouldLogInDebug;
}

+ (void)setShouldLogInDebug:(BOOL)shouldLogInDebug {
    shouldLogInDebug = shouldLogInDebug;
}

#pragma mark - Logging

+ (BOOL)isProduction {
#ifdef DEBUG // Only log on the app store if the debug setting is enabled in settings
    return NO;
#else
    return YES;
#endif
}

+ (BOOL)loggingEnabled {
    return ([OSLogger usingLogLevelFiltering]) || (![OSLogger isProduction] && [OSLogger shouldLogInDebug]) || ([OSLogger isProduction] && [OSLogger shouldLogInProduction]);
}


+ (void)logWithLogLevel:(OSLogger_LogLevel)LogLevel formatArgs:(NSArray *)args{
    NSString *logFormat = @"<%@:%@> %@";
    
    if ([OSLogger usingLogLevelFiltering]) {
        
        if (![OSLogger meetsMinimumLogLevel:LogLevel])
            return;
        
        NSString *label = [OSLogger labelForLogLevel:LogLevel];
        logFormat = [NSString stringWithFormat:@"[%@]\t%@", label, logFormat];
    }
    
    [OSLogger log:logFormat,
     [args count] >= 1 ? [args objectAtIndex:0] : nil,
     [args count] >= 2 ? [args objectAtIndex:1] : nil,
     [args count] >= 3 ? [args objectAtIndex:2] : nil,
     [args count] >= 4 ? [args objectAtIndex:3] : nil,
     [args count] >= 5 ? [args objectAtIndex:4] : nil,
     [args count] >= 6 ? [args objectAtIndex:5] : nil,
     [args count] >= 7 ? [args objectAtIndex:6] : nil,
     [args count] >= 8 ? [args objectAtIndex:7] : nil,
     [args count] >= 9 ? [args objectAtIndex:8] : nil
     ];
}

+ (void)log:(NSString *)format, ... {
    
    @try {
        if ([OSLogger loggingEnabled]) {
            if (format != nil) {
                va_list args;
                va_start(args, format);
                NSLogv(format, args);
                va_end(args);
            }
        }
    } @catch (...) {
        NSLogv(@"Caught an exception in OSLogger", nil);
    }
    
}


#pragma mark - Application Log Collection

+ (NSString *)bundleName {
    if (!appBundleName)
        appBundleName = (NSString *)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    
    return appBundleName;
}

+ (void)setBundleName:(NSString *)bundleName {
    appBundleName = bundleName;
}

+ (NSArray *)getConsoleLogEntriesForBundleName:(NSString *)bundleName {
    NSMutableArray *logs = [NSMutableArray array];
    
    aslmsg q, m;
    int i;
    const char *key, *val;
    
    NSString *queryTerm = bundleName;
    
    q = asl_new(ASL_TYPE_QUERY);
    asl_set_query(q, ASL_KEY_SENDER, [queryTerm UTF8String], ASL_QUERY_OP_EQUAL);
    
    aslresponse r = asl_search(NULL, q);
    while (NULL != (m = aslresponse_next(r))) {
        NSMutableDictionary *tmpDict = [NSMutableDictionary dictionary];
        
        for (i = 0; (NULL != (key = asl_key(m, i))); i++) {
            NSString *keyString = [NSString stringWithUTF8String:(char *)key];
            
            val = asl_get(m, key);
            
            NSString *string = [NSString stringWithUTF8String:val];
            [tmpDict setObject:string forKey:keyString];
        }
        
        NSString *message = [tmpDict objectForKey:@"Message"];
        if (message)
            [logs addObject:message];
        
    }
    aslresponse_free(r);
    
    return logs;
}

+ (void)getApplicationLog:(void (^)(NSArray *logs))onComplete {
    dispatch_queue_t backgroundQueue = dispatch_queue_create("com.inspiringlab.oslogger", 0);
    dispatch_async(backgroundQueue, ^{
        NSArray *logs = [OSLogger getConsoleLogEntriesForBundleName:[self bundleName]];
        onComplete(logs);
    });
}

+ (NSString *)applicationLog {
    NSArray *logs = [OSLogger getConsoleLogEntriesForBundleName:[self bundleName]];
    return [logs componentsJoinedByString:@"\n"];
}


@end
