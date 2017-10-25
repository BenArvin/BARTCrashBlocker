//
//  BARTAssociateCategory.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/12.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import <objc/runtime.h>

@interface NSObject(BARTAssociateCategory)

+ (void)ba_setAssociatedAttribute:(id)value withKey:(const void *)key policy:(objc_AssociationPolicy)policy to:(id)object;
+ (id)ba_getAssociatedAttribute:(const void *)key from:(id)object;
+ (void)ba_removeAssociatedAttribute:(const void *)key from:(id)object;

@end
