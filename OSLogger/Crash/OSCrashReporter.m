//
//  CrashReporter.m
//  VeriBranch
//
//  Created by Veripark (SYLMZ) on 7/2/14.
//
//
#define crashReportFile @"crash.plist"
#define listTitle @"List"
#define serviceURL @"http://osmansoylemez.com"
#define maxLogCount 10

#import "OSCrashReporter.h"
#import <CrashReporter/CrashReporter.h>
#import "AsyncRequest.h"
#import "NSDictionary+util.h"
#import "NSString+util.h"
#import "OSGlobals.h"

@implementation OSCrashReporter

// kaydetme işlemi cihazın üzerine olduğu için kullanılan fonksiyonla

+ (BOOL) controlObject:(NSString *)path toWriteArray:(NSMutableArray *) array{
    for (int i = 0 ; i < array.count; i++) {
        NSDictionary *dict = [array objectAtIndex:i];
        if ([[dict objectForKey:@"path"] isEqualToString:path]) {
            return FALSE;
        }
    }
    return TRUE;
}

+ (void) handleCrashReport {
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSData *crashData;
    NSError *error;
    
    // Try loading the crash report
    crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
    if (crashData == nil) {
        NSLog(@"Could not load crash report: %@", error);
    }
    
    // We could send the report from here, but we'll just print out
    // some debugging info instead
    PLCrashReport *report = [[PLCrashReport alloc] initWithData:crashData error: &error];
    if (report == nil) {
        NSLog(@"Could not parse crash report");
    }
    PLCrashReportTextFormat textFormat = PLCrashReportTextFormatiOS;
    
    NSString* reportSTR = [PLCrashReportTextFormatter stringValueForCrashReport: report withTextFormat: textFormat];
    NSLog(@"Crash log \n\n\n%@ \n\n\n", reportSTR);
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
    
    NSString *filePath = [formatter stringFromDate:report.systemInfo.timestamp];
    
    NSString *path = [[OSGlobals getCacheFileDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.crash",filePath]];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:report.exceptionInfo.exceptionName forKeyPath:@"exceptionName"];
    [dict setValue:report.exceptionInfo.exceptionReason forKeyPath:@"exceptionReason"];
    [dict setValue:path forKeyPath:@"path"];
    
    [reportSTR writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [OSCrashReporter sendCrashReportFilePath:dict];
    
    [crashReporter purgePendingCrashReport];
    return;
}

+ (void) sendCrashReportFilePath:(NSDictionary *) body{
    
    NSMutableDictionary *exceptionMessage = [NSMutableDictionary dictionaryWithDictionary:body];
    [exceptionMessage setValue:[[NSString alloc] initWithContentsOfFile:[body objectForKey:@"path"] encoding:NSUTF8StringEncoding error:nil] forKey:@"staketrace"];
    
    NSMutableDictionary *crashReport = [NSMutableDictionary dictionary];
    [crashReport setValue:[exceptionMessage JSONString] forKey:@"ExceptionMessage"];

    
    NSDictionary *logDictionary = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:crashReport, nil] forKey:listTitle];
    NSString *logJSON = [logDictionary JSONString];
    NSLog(@"%@",logJSON);
    AsyncRequest *req = [[AsyncRequest alloc] init];
    NSString *responseString = [req sendJSONPostRequest:[NSString stringWithFormat:@"%@logging/MobileLoggingTransaction",serviceURL] body:logJSON];
    NSLog(@"responseString %@",responseString);
    NSDictionary *responseDict = [responseString dictionary];
    if (![[responseDict objectForKey:@"isSuccess"] boolValue]) {
        NSString *path = [[OSGlobals getCacheFileDirectoryPath] stringByAppendingPathComponent:crashReportFile];
        NSMutableDictionary *dictionary = [OSGlobals getDictionaryFromPlist:path];
        NSMutableArray *array = [dictionary objectForKey:listTitle];
        if (array == nil) {
            array = [[NSMutableArray alloc] init];
        }
        if ([OSCrashReporter controlObject:[body objectForKey:@"path"] toWriteArray:array]) {
            [array addObject:body];
            [dictionary setValue:array forKey:listTitle];
            [dictionary writeToFile:path atomically:YES];
        }
    }
}

+ (void) pushLogString{
    NSString *path = [OSGlobals getLogFilePath];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithDictionary:[OSGlobals getDictionaryFromPlist:path]];
    NSMutableArray *eventList = [[NSMutableArray alloc] initWithArray:[dictionary objectForKey:listTitle]];
    
    if (eventList.count > 0) {
        int maxIndex = maxLogCount;
        if (maxIndex > eventList.count) {
            maxIndex = (int)eventList.count;
        }
        
        NSMutableArray *postArray = [NSMutableArray new];
        for (int i = 0; i < maxIndex; i++) {
            NSString *jsonString = [eventList objectAtIndex:i];
            NSDictionary *dict = [jsonString dictionary];
            [postArray addObject:dict];
        }
        
        NSDictionary *logDictionary = [NSDictionary dictionaryWithObject:postArray forKey:listTitle];
        NSString *logJSON = [logDictionary JSONString];
        AsyncRequest *req = [[AsyncRequest alloc] init];
        NSString *responseString = [req sendJSONPostRequest:[NSString stringWithFormat:@"%@logging/MobileLoggingTransaction",serviceURL] body:logJSON];
        NSLog(@"responseString %@",responseString);
        NSDictionary *responseDict = [responseString dictionary];
        if ([[responseDict objectForKey:@"isSuccess"] boolValue]) {
            
            if (maxIndex < eventList.count) {
                [OSCrashReporter performSelector:@selector(pushLogString) withObject:nil afterDelay:4.0];
            }
            
            for (int i = 0; i < maxIndex; i++) {
                [eventList removeObjectAtIndex:0];
            }
            [dictionary setValue:eventList forKey:listTitle];
            [dictionary writeToFile:path atomically:YES];
        }
    }
}

@end
