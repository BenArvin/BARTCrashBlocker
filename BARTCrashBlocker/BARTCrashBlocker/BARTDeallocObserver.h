//
//  BARTDeallocObserver.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/12.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

typedef void(^BARTDeallocObserverBlock)(void);

/**
 observe object dealloc function
 */
@interface NSObject(BARTDeallocObserverCategory)

/**
 start observe dealloc function
 
 @param willDeallocSelector selector called before self dealloc, must be non parameter
 @param didDeallocBlock block called after self did dealloc
 */
- (void)ba_startDeallocObserving:(SEL)willDeallocSelector
                   didDeallocBlock:(BARTDeallocObserverBlock)didDeallocBlock;

/**
 stop observe dealloc function
 */
- (void)ba_stopDeallocObserving;

@end


