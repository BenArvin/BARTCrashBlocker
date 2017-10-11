//
//  BARTCrashBlocker.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/9.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BARTCrashBlockerModes) {
    BARTCrashBlockerModesContainer = 1 << 0,//container crash(NSString, NSArray, NSDictionary...)
    BARTCrashBlockerModesKVO       = 1 << 1,//KVO crash
    BARTCrashBlockerModesSelector  = 1 << 2,//unrecognized selector crash
};

@interface BARTCrashBlocker : NSObject

+ (void)loadBlocker:(BARTCrashBlockerModes)modes;
+ (void)unloadBlocker:(BARTCrashBlockerModes)modes;

@end
