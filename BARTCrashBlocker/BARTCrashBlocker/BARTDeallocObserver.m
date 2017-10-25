//
//  BARTDeallocObserver.m
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/12.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BARTDeallocObserver.h"
#import <objc/runtime.h>
#import <pthread.h>
#import "BARTAssociateCategory.h"

static char ba_keyAssociatedDeallocObserveInfo;

@interface BARTDeallocObserveInfo : NSObject

@property (nonatomic, assign) BOOL needFeedback;

@property (nonatomic, copy) NSString *ownerAddress;
@property (nonatomic, copy) NSString *ownerClass;
@property (nonatomic) SEL willDeallocSelector;
@property (nonatomic, copy) BARTDeallocObserverBlock didDeallocBlock;

@end

@interface BARTDeallocObserver : NSObject {
    pthread_mutex_t _mutexLock;
    BOOL _mutexLockValid;
    BOOL _observerLoaded;
    
    NSUInteger _observingCount;
}

+ (instancetype)sharedObserver;
- (void)addObservingCount;
- (void)reduceObservingCount;

@end

@implementation BARTDeallocObserveInfo

- (void)dealloc
{
    if (_needFeedback) {
        [[BARTDeallocObserver sharedObserver] reduceObservingCount];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _needFeedback = YES;
    }
    return self;
}
@end

@implementation NSObject(BARTDeallocObserverCategory)

#pragma mark - exchanged method
- (void)BARTCB_dealloc
{
    BARTDeallocObserveInfo *observeInfo = objc_getAssociatedObject(self, &ba_keyAssociatedDeallocObserveInfo);
    if (observeInfo) {
        observeInfo.needFeedback = NO;
        if (observeInfo.willDeallocSelector && [self respondsToSelector:observeInfo.willDeallocSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:observeInfo.willDeallocSelector];
#pragma clang diagnostic pop
        }
    }
    [self BARTCB_dealloc];
    if (observeInfo) {
        [[BARTDeallocObserver sharedObserver] reduceObservingCount];
        if (observeInfo.didDeallocBlock) {
            observeInfo.didDeallocBlock();
        }
    }
}

- (void)ba_startDeallocObserving:(SEL)willDeallocSelector didDeallocBlock:(BARTDeallocObserverBlock)didDeallocBlock
{
    if (![NSObject ba_getAssociatedAttribute:&ba_keyAssociatedDeallocObserveInfo from:self]) {
        BARTDeallocObserveInfo *observeInfo = [[BARTDeallocObserveInfo alloc] init];
        observeInfo.ownerAddress = [NSString stringWithFormat:@"%p", self];
        observeInfo.ownerClass = NSStringFromClass([self class]);
        observeInfo.willDeallocSelector = willDeallocSelector;
        observeInfo.didDeallocBlock = didDeallocBlock;
        [NSObject ba_setAssociatedAttribute:observeInfo withKey:&ba_keyAssociatedDeallocObserveInfo policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC to:self];
        [[BARTDeallocObserver sharedObserver] addObservingCount];
    }
}

- (void)ba_stopDeallocObserving
{
    BARTDeallocObserveInfo *observeInfo = [NSObject ba_getAssociatedAttribute:&ba_keyAssociatedDeallocObserveInfo from:self];
    if (observeInfo) {
        observeInfo.needFeedback = NO;
        [NSObject ba_removeAssociatedAttribute:&ba_keyAssociatedDeallocObserveInfo from:self];
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
        _observerLoaded = NO;
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
    if (!_observerLoaded) {
        [self replaceMethods];
        _observerLoaded = YES;
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (void)unload
{
    pthread_mutex_lock(&_mutexLock);
    if (_observerLoaded) {
        [self replaceMethods];
        _observerLoaded = NO;
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (void)replaceMethods
{
    method_exchangeImplementations(class_getInstanceMethod([NSObject class], NSSelectorFromString(@"dealloc")), class_getInstanceMethod([NSObject class], NSSelectorFromString(@"BARTCB_dealloc")));
}

@end

