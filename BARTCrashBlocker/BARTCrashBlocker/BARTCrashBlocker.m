//
//  BARTCrashBlocker.m
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/9.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import "BARTCrashBlocker.h"
#import "BARTSelectorCrashBlocker.h"
#import "BARTContainerCrashBlocker.h"
#import "BARTKVOCrashBlocker.h"

@implementation BARTCrashBlocker

#pragma mark - public method
+ (void)loadBlocker:(BARTCrashBlockerModes)modes
{
    [[self sharedCrashBlocker] loadBlockersWithModes:modes];
}

+ (void)unloadBlocker:(BARTCrashBlockerModes)modes
{
    [[self sharedCrashBlocker] unloadBlockersWithModes:modes];
}

#pragma mark - property method

#pragma mark - private method
+ (BARTCrashBlocker *)sharedCrashBlocker
{
    static BARTCrashBlocker *crashBlocker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        crashBlocker = [[BARTCrashBlocker alloc] init];
    });
    return crashBlocker;
}

- (void)loadBlockersWithModes:(BARTCrashBlockerModes)modes
{
    if ((modes & BARTCrashBlockerModesSelector) == BARTCrashBlockerModesSelector) {
        [[BARTSelectorCrashBlocker sharedBlocker] load];
    }
    if ((modes & BARTCrashBlockerModesContainer) == BARTCrashBlockerModesContainer) {
        [[BARTContainerCrashBlocker sharedBlocker] load];
    }
    if ((modes & BARTCrashBlockerModesKVO) == BARTCrashBlockerModesKVO) {
        [[BARTKVOCrashBlocker sharedBlocker] load];
    }
}

- (void)unloadBlockersWithModes:(BARTCrashBlockerModes)modes
{
    if ((modes & BARTCrashBlockerModesSelector) == BARTCrashBlockerModesSelector) {
        [[BARTSelectorCrashBlocker sharedBlocker] unload];
    }
    if ((modes & BARTCrashBlockerModesContainer) == BARTCrashBlockerModesContainer) {
        [[BARTContainerCrashBlocker sharedBlocker] unload];
    }
    if ((modes & BARTCrashBlockerModesKVO) == BARTCrashBlockerModesKVO) {
        [[BARTKVOCrashBlocker sharedBlocker] unload];
    }
}

@end
