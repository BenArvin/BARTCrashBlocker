//
//  BALogger.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/9.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

extern NSString *const BALoggerNewLogNotification;

/**
 BALogger
 */
@interface BALogger : NSObject

+ (BALogger *)sharedLogger;
- (void)log:(NSString *)log;

@end
