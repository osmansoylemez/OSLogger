//
//  CrashReporter.h
//  VeriBranch
//
//  Created by Veripark (SYLMZ) on 7/2/14.
//
//

#import <Foundation/Foundation.h>

@interface OSCrashReporter : NSObject

+ (BOOL) controlObject:(NSString *)body toWriteArray:(NSMutableArray *) array;
+ (void) handleCrashReport;
+ (void) pushLogString;

@end
