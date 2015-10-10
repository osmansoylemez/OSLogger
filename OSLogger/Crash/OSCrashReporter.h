//
//  CrashReporter.h
//  VeriBranch
//
//  Created by Veripark (SYLMZ) on 7/2/14.
//
//

#import <Foundation/Foundation.h>

@interface CrashReporter : NSObject

+ (BOOL) controlObject:(NSString *)body toWriteArray:(NSMutableArray *) array;
+ (void) pushData;
+ (void) handleCrashReport;
+ (void) pushLogString;

@end
