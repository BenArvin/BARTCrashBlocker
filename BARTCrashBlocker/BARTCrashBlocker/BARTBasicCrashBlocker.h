//
//  BARTBasicCrashBlocker.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/11.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

@interface BARTBasicCrashBlocker : NSObject

+ (instancetype)sharedBlocker;
- (void)load;
- (void)unload;

@end
