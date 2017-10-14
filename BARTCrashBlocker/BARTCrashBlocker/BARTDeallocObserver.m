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
#import "BALogger.h"

#define KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO  "BARTObjectAssociatedDeallocObserveInfo"

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
    BARTDeallocObserveInfo *observeInfo = objc_getAssociatedObject(self, KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO);
    if (observeInfo) {
        observeInfo.needFeedback = NO;
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"(%@ *)%@ will dealloc", observeInfo.ownerClass, observeInfo.ownerAddress]];
        if (observeInfo.willDeallocSelector && [self respondsToSelector:observeInfo.willDeallocSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:observeInfo.willDeallocSelector];
#pragma clang diagnostic pop
        }
    }
    [self BARTCB_dealloc];
    if (observeInfo) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"(%@ *)%@ did dealloc", observeInfo.ownerClass, observeInfo.ownerAddress]];
        [[BARTDeallocObserver sharedObserver] reduceObservingCount];
        if (observeInfo.didDeallocBlock) {
            observeInfo.didDeallocBlock();
        }
    }
}

- (void)startDeallocObserving:(SEL)willDeallocSelector didDeallocBlock:(BARTDeallocObserverBlock)didDeallocBlock
{
    if (![NSObject getAssociatedAttribute:KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO from:self]) {
        BARTDeallocObserveInfo *observeInfo = [[BARTDeallocObserveInfo alloc] init];
        observeInfo.ownerAddress = [NSString stringWithFormat:@"%p", self];
        observeInfo.ownerClass = NSStringFromClass([self class]);
        observeInfo.willDeallocSelector = willDeallocSelector;
        observeInfo.didDeallocBlock = didDeallocBlock;
        [NSObject setAssociatedAttribute:observeInfo withKey:KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC to:self];
        [[BARTDeallocObserver sharedObserver] addObservingCount];
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"(%@ *)%@ start dealloc observing", observeInfo.ownerClass, observeInfo.ownerAddress]];
    }
}

- (void)stopDeallocObserving
{
    BARTDeallocObserveInfo *observeInfo = [NSObject getAssociatedAttribute:KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO from:self];
    if (observeInfo) {
        observeInfo.needFeedback = NO;
        [NSObject removeAssociatedAttribute:KEY_ASSOCIATED_DEALLOC_OBSERVE_INFO from:self];
        [[BARTDeallocObserver sharedObserver] reduceObservingCount];
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"(%@ *)%@ stop dealloc observing", observeInfo.ownerClass, observeInfo.ownerAddress]];
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
        [[BALogger sharedLogger] log:@"dealloc observer loaded"];
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (void)unload
{
    pthread_mutex_lock(&_mutexLock);
    if (_observerLoaded) {
        [self replaceMethods];
        _observerLoaded = NO;
        [[BALogger sharedLogger] log:@"dealloc observer unloaded"];
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (void)replaceMethods
{
    method_exchangeImplementations(class_getInstanceMethod([NSObject class], NSSelectorFromString(@"dealloc")), class_getInstanceMethod([NSObject class], NSSelectorFromString(@"BARTCB_dealloc")));
}

@end

