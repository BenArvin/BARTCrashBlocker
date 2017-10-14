//
//  BARTCrashBlocker.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/9.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BARTCrashBlocker : NSObject

/**
 load container crash blockers
 */
+ (void)loadContainerCrashBlocker;

/**
 unload container crash blockers
 */
+ (void)unloadContainerCrashBlocker;

/**
 load unrecognized selector crash blockers

 @param classPrefixs the class prefixs that blocker need block, so blocker can only check specific classes
 (⚠️ATTENTION: blocker will not work if classPrefixs is null)
 */
+ (void)loadSelectorCrashBlocker:(NSArray <NSString *> *)classPrefixs;

/**
 unload unrecognized selector crash blockers
 */
+ (void)unloadSelectorCrashBlocker;

/**
 load KVO crash blockers(⚠️ATTENTION: should remove all KVO relation before load blocker)
 */
+ (void)loadKVOCrashBlocker;

/**
 unload KVO crash blockers
 */
+ (void)unloadKVOCrashBlocker;

@end
