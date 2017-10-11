//
//  BALogger.m
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/9.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BALogger.h"

NSString *const BALoggerNewLogNotification = @"BALoggerNewLogNotification";

@implementation BALogger

+ (BALogger *)sharedLogger
{
    static BALogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[BALogger alloc] init];
    });
    return logger;
}

- (void)log:(NSString *)log
{
    NSString *newLog = [NSString stringWithFormat:@"BARTCrashBlocker: %@", log];
    NSLog(@"%@", newLog);
    [[NSNotificationCenter defaultCenter] postNotificationName:BALoggerNewLogNotification object:newLog];
}

@end
