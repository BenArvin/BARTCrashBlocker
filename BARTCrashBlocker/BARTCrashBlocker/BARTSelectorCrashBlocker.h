//
//  BARTSelectorCrashBlocker.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/9.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

/**
 unrecognized selector crash blocker
 */
@interface BARTSelectorCrashBlocker : NSObject

+ (instancetype)sharedBlocker;

/**
 load crash blocker
 
 @param classPrefixs the class prefixs that blocker need block, so blocker can only check specific classes
 (⚠️ATTENTION: blocker will not work if classPrefixs is null)
 */
- (void)load:(NSArray <NSString *> *)classPrefixs;

- (void)unload;

- (BOOL)working;

@end
