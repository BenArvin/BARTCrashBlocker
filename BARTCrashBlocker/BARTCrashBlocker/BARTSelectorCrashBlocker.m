//
//  BARTSelectorCrashBlocker.m
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/9.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BARTSelectorCrashBlocker.h"
#import <objc/runtime.h>
#import <pthread.h>
#import "BALogger.h"

@interface NSObject(BARTSelectorCrashBlockerCategory)
@end

@interface BARTSelectorCrashBlockerScapegoat : NSObject
@end

@interface BARTSelectorCrashBlocker () {
    pthread_mutex_t _mutexLock;
    BOOL _mutexLockValid;
    BOOL _blockerLoaded;
}

@property (nonatomic) BARTSelectorCrashBlockerScapegoat *scapegoat;

- (id)scapegoatWithSelector:(SEL)selector;

@end

@implementation NSObject(BARTSelectorCrashBlockerCategory)

- (id)BARTCB_forwardingTargetForSelector:(SEL)aSelector
{
    id result = [self BARTCB_forwardingTargetForSelector:aSelector];
    if (result) {
        return result;
    } else {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"unrecognized selector crash, receiver calss = %@, selector = %@", [self class], NSStringFromSelector(aSelector)]];
        return [[BARTSelectorCrashBlocker sharedBlocker] scapegoatWithSelector:aSelector];
    }
}

@end

@implementation BARTSelectorCrashBlockerScapegoat

@end

@implementation BARTSelectorCrashBlocker

- (void)dealloc
{
    if (_mutexLockValid) {
        pthread_mutex_destroy(&_mutexLock);
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _blockerLoaded = NO;
        _mutexLockValid = pthread_mutex_init(&_mutexLock, NULL);
    }
    return self;
}

#pragma mark - public method
+ (instancetype)sharedBlocker
{
    static BARTSelectorCrashBlocker *selectorCrashBlocker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        selectorCrashBlocker = [[BARTSelectorCrashBlocker alloc] init];
    });
    return selectorCrashBlocker;
}

- (void)load
{
    pthread_mutex_lock(&_mutexLock);
    if (!_blockerLoaded) {
        [self replaceMethods];
        _blockerLoaded = YES;
        [[BALogger sharedLogger] log:@"unrecognized selector crash blocker loaded"];
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (void)unload
{
    pthread_mutex_lock(&_mutexLock);
    if (_blockerLoaded) {
        [self replaceMethods];
        _blockerLoaded = NO;
        [[BALogger sharedLogger] log:@"unrecognized selector crash blocker unloaded"];
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (BOOL)working
{
    BOOL result = NO;
    pthread_mutex_lock(&_mutexLock);
    result = _blockerLoaded;
    pthread_mutex_unlock(&_mutexLock);
    return result;
}

- (id)scapegoatWithSelector:(SEL)selector
{
    if (![self.scapegoat respondsToSelector:selector]) {
        class_addMethod([BARTSelectorCrashBlockerScapegoat class], selector, imp_implementationWithBlock(^(){return nil;}), nil);
    }
    return self.scapegoat;
}

#pragma mark - property method
- (BARTSelectorCrashBlockerScapegoat *)scapegoat
{
    if (!_scapegoat) {
        _scapegoat = [[BARTSelectorCrashBlockerScapegoat alloc] init];
    }
    return _scapegoat;
}

#pragma mark - private method
- (void)replaceMethods
{
    method_exchangeImplementations(class_getInstanceMethod([NSObject class], @selector(forwardingTargetForSelector:)), class_getInstanceMethod([NSObject class], @selector(BARTCB_forwardingTargetForSelector:)));
}

@end
