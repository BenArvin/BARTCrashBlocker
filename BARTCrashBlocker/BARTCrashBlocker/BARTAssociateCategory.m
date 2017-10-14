//
//  BARTAssociateCategory.m
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/12.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BARTAssociateCategory.h"

@implementation NSObject(BARTAssociateCategory)

+ (void)setAssociatedAttribute:(id)value withKey:(void *)key policy:(objc_AssociationPolicy)policy to:(id)object
{
    objc_setAssociatedObject(object, key, value, policy);
}

+ (id)getAssociatedAttribute:(void *)key from:(id)object
{
    return objc_getAssociatedObject(object, key);
}

+ (void)removeAssociatedAttribute:(void *)key from:(id)object
{
    objc_setAssociatedObject(object, key, nil, OBJC_ASSOCIATION_ASSIGN);
}

@end
