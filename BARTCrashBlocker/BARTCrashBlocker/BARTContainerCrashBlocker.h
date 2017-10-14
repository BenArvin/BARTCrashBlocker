//
//  BARTContainerCrashBlocker.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/9.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

/**
 container crash blocker:
 
 1.NSArray/NSMutableArray
 
 2.NSDictionary/NSMutableDictionary
 
 3.NSString/NSMutableString
 */
@interface BARTContainerCrashBlocker : NSObject

+ (instancetype)sharedBlocker;

- (void)load;

- (void)unload;

- (BOOL)working;

@end
