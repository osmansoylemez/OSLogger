//
//  CrashReporter.m
//  VeriBranch
//
//  Created by Veripark (SYLMZ) on 7/2/14.
//
//
#define unsuccessfullDataPath @"unsuccessfullData.plist"
#define crashReportFile @"crash.plist"

#import "CrashReporter.h"
#import <CrashReporter/CrashReporter.h>
#import "AsyncRequest.h"
#import "NSString+Crypto.h"

@implementation CrashReporter

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
    
    NSString *path = [[GeneralMethods getCacheFileDirectoryPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.crash",filePath]];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:report.exceptionInfo.exceptionName forKeyPath:@"exceptionName"];
    [dict setValue:report.exceptionInfo.exceptionReason forKeyPath:@"exceptionReason"];
    [dict setValue:path forKeyPath:@"path"];
    
    [reportSTR writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [CrashReporter sendCrashReportFilePath:dict];
    
    [crashReporter purgePendingCrashReport];
    return;
}

+ (void) sendCrashReportFilePath:(NSDictionary *) body{
    
    NSMutableDictionary *exceptionMessage = [NSMutableDictionary dictionaryWithDictionary:body];
    [exceptionMessage setValue:[[NSString alloc] initWithContentsOfFile:[body objectForKey:@"path"] encoding:NSUTF8StringEncoding error:nil] forKey:@"staketrace"];
    
    NSMutableDictionary *crashReport = [GeneralMethods getDefaultLogDictionary];
    [crashReport setValue:[GeneralMethods convertDictionaryToJSONString:exceptionMessage] forKey:@"ExceptionMessage"];

    
    NSDictionary *logDictionary = [NSDictionary dictionaryWithObject:[NSArray arrayWithObjects:crashReport, nil] forKey:listTitle];
    NSString *logJSON = [GeneralMethods convertDictionaryToJSONString:logDictionary];
    NSLog(@"%@",logJSON);
    AsyncRequest *req = [[AsyncRequest alloc] init];
    NSString *responseString = [req sendJSONPostRequest:[NSString stringWithFormat:@"%@logging/MobileLoggingTransaction",serviceURL] body:logJSON];
    NSLog(@"responseString %@",responseString);
    NSDictionary *responseDict = [GeneralMethods convertStringToDictionary:responseString];
    if (![[responseDict objectForKey:@"isSuccess"] boolValue]) {
        NSString *path = [[GeneralMethods getCacheFileDirectoryPath] stringByAppendingPathComponent:crashReportFile];
        NSMutableDictionary *dictionary = [GeneralMethods getDictionaryFromPlist:path];
        NSMutableArray *array = [dictionary objectForKey:listTitle];
        if (array == nil) {
            array = [[NSMutableArray alloc] init];
        }
        if ([CrashReporter controlObject:[body objectForKey:@"path"] toWriteArray:array]) {
            [array addObject:body];
            [dictionary setValue:array forKey:listTitle];
            [dictionary writeToFile:path atomically:YES];
        }
    }
}

+ (void) pushData{
    NSString *path = [[GeneralMethods getCacheFileDirectoryPath] stringByAppendingPathComponent:crashReportFile];
    NSMutableDictionary *dictionary = [GeneralMethods getDictionaryFromPlist:path];
    NSMutableArray *array = [dictionary objectForKey:@"dataList"];
    if (array == nil) {
        array = [[NSMutableArray alloc] init];
    }
    
    for (int i = 0; i < array.count; i++) {
        NSLog(@"%@",[array objectAtIndex:i]);
        
        NSString *filePath = [[array objectAtIndex:i] objectForKey:@"path"];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        if ([fileManager fileExistsAtPath:filePath]) {
            NSFileManager *man = [NSFileManager defaultManager];
            NSDictionary *attrs = [man attributesOfItemAtPath:filePath error: NULL];
            UInt32 result = [attrs fileSize];
            NSLog(@"dosya %@ boyutu %i",filePath,(int)result);
        }else{
            NSLog(@"dosya yok");
        }
    }
}

+ (void) pushLogString{
    NSString *path = [GeneralMethods getLogFilePath];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithDictionary:[GeneralMethods getDictionaryFromPlist:path]];
    NSMutableArray *eventList = [[NSMutableArray alloc] initWithArray:[dictionary objectForKey:listTitle]];
    
    if (eventList.count > 0) {
        int maxIndex = 10;
        if (maxIndex > eventList.count) {
            maxIndex = eventList.count;
        }
        
        NSMutableArray *postArray = [NSMutableArray new];
        for (int i = 0; i < maxIndex; i++) {
            NSString *jsonString = [[eventList objectAtIndex:i] decodeBase64String];
            NSDictionary *dict = [GeneralMethods convertStringToDictionary:jsonString];
            [postArray addObject:dict];
        }
        
        NSDictionary *logDictionary = [NSDictionary dictionaryWithObject:postArray forKey:listTitle];
        NSString *logJSON = [GeneralMethods convertDictionaryToJSONString:logDictionary];
        AsyncRequest *req = [[AsyncRequest alloc] init];
        NSString *responseString = [req sendJSONPostRequest:[NSString stringWithFormat:@"%@logging/MobileLoggingTransaction",serviceURL] body:logJSON];
        NSLog(@"responseString %@",responseString);
        NSDictionary *responseDict = [GeneralMethods convertStringToDictionary:responseString];
        if ([[responseDict objectForKey:@"isSuccess"] boolValue]) {
            
            if (maxIndex < eventList.count) {
                [CrashReporter performSelector:@selector(pushLogString) withObject:nil afterDelay:4.0];
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
