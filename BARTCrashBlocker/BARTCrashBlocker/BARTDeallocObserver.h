//
//  BARTDeallocObserver.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/12.
//  Copyright © 2017年 cn.ZAKER. All rights reserved.
//

typedef void(^BARTDeallocObserverBlock)(void);

/**
 observe object dealloc function
 */
@interface NSObject(BARTDeallocObserverCategory)

/**
 start observe dealloc function

 @param willDeallocBlock block called before self dealloc
 @param didDeallocBlock block called after self did dealloc
 */
- (void)startDeallocObserving:(BARTDeallocObserverBlock)willDeallocBlock
              didDeallocBlock:(BARTDeallocObserverBlock)didDeallocBlock;

/**
 stop observe dealloc function
 */
- (void)stopDeallocObserving;

@end
