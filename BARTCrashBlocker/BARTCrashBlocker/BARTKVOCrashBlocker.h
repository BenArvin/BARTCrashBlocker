//
//  BARTKVOCrashBlocker.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/10.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import "BARTBasicCrashBlocker.h"

/**
 KVO crash blocker: need remove all KVO relation before load blocker
 
 1.observer/keyPath invalid
 
 2.duplicate add/remove observer
 
 3.observer/observed target released
 */
@interface BARTKVOCrashBlocker : BARTBasicCrashBlocker

@end
