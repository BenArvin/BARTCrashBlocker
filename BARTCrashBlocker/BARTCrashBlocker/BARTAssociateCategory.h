//
//  BARTAssociateCategory.h
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/12.
//  Copyright © 2017年 cn.ZAKER. All rights reserved.
//

#import <objc/runtime.h>

@interface NSObject(BARTAssociateCategory)

+ (void)setAssociatedAttribute:(id)value withKey:(void *)key policy:(objc_AssociationPolicy)policy to:(id)object;
+ (id)getAssociatedAttribute:(void *)key from:(id)object;
+ (void)removeAssociatedAttribute:(void *)key from:(id)object;

@end
