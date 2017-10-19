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
+ (void)loadContainerCrashBlocker
{
    [[BARTContainerCrashBlocker sharedBlocker] load];
}

+ (void)unloadContainerCrashBlocker
{
    [[BARTContainerCrashBlocker sharedBlocker] unload];
}

+ (void)loadSelectorCrashBlocker:(NSArray <NSString *> *)classPrefixs
{
    [[BARTSelectorCrashBlocker sharedBlocker] load:classPrefixs];
}

+ (void)unloadSelectorCrashBlocker
{
    [[BARTSelectorCrashBlocker sharedBlocker] unload];
}

+ (void)loadKVOCrashBlocker
{
    [[BARTKVOCrashBlocker sharedBlocker] load];
}

+ (void)unloadKVOCrashBlocker
{
    [[BARTKVOCrashBlocker sharedBlocker] unload];
}

@end
