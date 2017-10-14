//
//  BARTKVOCrashBlocker.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/10.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

/**
 KVO crash blocker(⚠️ATTENTION: should remove all KVO relation before load blocker)
 
 1.observer/keyPath invalid
 
 2.duplicate add/remove observer
 
 3.observer/observed target released
 */
@interface BARTKVOCrashBlocker : NSObject

+ (instancetype)sharedBlocker;

- (void)load;

- (void)unload;

- (BOOL)working;

@end
