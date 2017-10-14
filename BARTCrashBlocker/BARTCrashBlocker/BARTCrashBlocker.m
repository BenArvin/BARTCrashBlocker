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
    [[self sharedCrashBlocker] loadContainerCrashBlocker];
}

+ (void)unloadContainerCrashBlocker
{
    [[self sharedCrashBlocker] unloadContainerCrashBlocker];
}

+ (void)loadSelectorCrashBlocker:(NSArray <NSString *> *)classPrefixs
{
    [[self sharedCrashBlocker] loadSelectorCrashBlocker:classPrefixs];
}

+ (void)unloadSelectorCrashBlocker
{
    [[self sharedCrashBlocker] unloadSelectorCrashBlocker];
}

+ (void)loadKVOCrashBlocker
{
    [[self sharedCrashBlocker] loadKVOCrashBlocker];
}

+ (void)unloadKVOCrashBlocker
{
    [[self sharedCrashBlocker] unloadKVOCrashBlocker];
}

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

- (void)loadContainerCrashBlocker
{
    [[BARTContainerCrashBlocker sharedBlocker] load];
}

- (void)unloadContainerCrashBlocker
{
    [[BARTContainerCrashBlocker sharedBlocker] unload];
}

- (void)loadSelectorCrashBlocker:(NSArray <NSString *> *)classPrefixs
{
    [[BARTSelectorCrashBlocker sharedBlocker] load:classPrefixs];
}

- (void)unloadSelectorCrashBlocker
{
    [[BARTSelectorCrashBlocker sharedBlocker] unload];
}

- (void)loadKVOCrashBlocker
{
    [[BARTKVOCrashBlocker sharedBlocker] load];
}

- (void)unloadKVOCrashBlocker
{
    [[BARTKVOCrashBlocker sharedBlocker] unload];
}

@end
