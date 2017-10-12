//
//  BARTDeallocObserver.m
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/12.
//  Copyright © 2017年 cn.ZAKER. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BARTDeallocObserver.h"
#import <objc/runtime.h>
#import <pthread.h>
#import "BARTAssociateCategory.h"
#import "BALogger.h"

#define KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO  "BARTObjectAssociatedDeallocObserveInfo"

@interface BARTDeallocObserveInfo : NSObject

@property (nonatomic, copy) BARTDeallocObserverBlock willDeallocBlock;
@property (nonatomic, copy) BARTDeallocObserverBlock didDeallocBlock;

@end

@interface BARTDeallocObserver : NSObject {
    pthread_mutex_t _mutexLock;
    BOOL _mutexLockValid;
    BOOL _blockerLoaded;
    
    NSUInteger _observingCount;
}

+ (instancetype)sharedObserver;
- (void)addObservingCount;
- (void)reduceObservingCount;

@end

@implementation BARTDeallocObserveInfo
@end

@implementation NSObject(BARTDeallocObserverCategory)

#pragma mark - exchanged method
- (void)BARTCB_dealloc
{
    NSString *selfAddressString = nil;
    NSString *selfClassString = nil;
    BARTDeallocObserveInfo *observeInfo = objc_getAssociatedObject(self, KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO);
    if (observeInfo) {
        selfAddressString = [NSString stringWithFormat:@"%p", self];
        selfClassString = NSStringFromClass([self class]);
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"(%@ *)%@ will dealloc", selfClassString, selfAddressString]];
        if (observeInfo.willDeallocBlock) {
            observeInfo.willDeallocBlock();
        }
    }
    [self BARTCB_dealloc];
    if (observeInfo) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"(%@ *)%@ did dealloc", selfClassString, selfAddressString]];
        [[BARTDeallocObserver sharedObserver] reduceObservingCount];
        if (observeInfo.didDeallocBlock) {
            observeInfo.didDeallocBlock();
        }
    }
}

- (void)startDeallocObserving:(BARTDeallocObserverBlock)willDeallocBlock didDeallocBlock:(BARTDeallocObserverBlock)didDeallocBlock
{
    if (![NSObject getAssociatedAttribute:KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO from:self]) {
        BARTDeallocObserveInfo *observeInfo = [[BARTDeallocObserveInfo alloc] init];
        observeInfo.willDeallocBlock = willDeallocBlock;
        observeInfo.didDeallocBlock = didDeallocBlock;
        [NSObject setAssociatedAttribute:observeInfo withKey:KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC to:self];
        [[BARTDeallocObserver sharedObserver] addObservingCount];
    }
}

- (void)stopDeallocObserving
{
    if ([NSObject getAssociatedAttribute:KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO from:self]) {
        [NSObject removeAssociatedAttribute:KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO from:self];
        [[BARTDeallocObserver sharedObserver] reduceObservingCount];
    }
}

@end

@implementation BARTDeallocObserver

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
        _observingCount = 0;
        _blockerLoaded = NO;
        _mutexLockValid = pthread_mutex_init(&_mutexLock, NULL);
    }
    return self;
}

#pragma mark - public method
+ (instancetype)sharedObserver
{
    static BARTDeallocObserver *sharedObserver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObserver = [[BARTDeallocObserver alloc] init];
    });
    return sharedObserver;
}

- (void)addObservingCount
{
    _observingCount++;
    if (_observingCount > 0) {
        [self load];
    }
}

- (void)reduceObservingCount
{
    if (_observingCount > 0) {
        _observingCount--;
        if (_observingCount == 0) {
            [self unload];
        }
    }
}

#pragma mark - private method
- (void)load
{
    pthread_mutex_lock(&_mutexLock);
    if (!_blockerLoaded) {
        [self replaceMethods];
        _blockerLoaded = YES;
        [[BALogger sharedLogger] log:@"dealloc observer loaded"];
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (void)unload
{
    pthread_mutex_lock(&_mutexLock);
    if (_blockerLoaded) {
        [self replaceMethods];
        _blockerLoaded = NO;
        [[BALogger sharedLogger] log:@"dealloc observer unloaded"];
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (void)replaceMethods
{
    method_exchangeImplementations(class_getInstanceMethod([NSObject class], NSSelectorFromString(@"dealloc")), class_getInstanceMethod([NSObject class], NSSelectorFromString(@"BARTCB_dealloc")));
}

@end
