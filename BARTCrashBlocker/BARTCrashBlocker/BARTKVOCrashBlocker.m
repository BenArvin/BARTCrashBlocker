//
//  BARTKVOCrashBlocker.m
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/10.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BARTKVOCrashBlocker.h"
#import <objc/runtime.h>
#import <pthread.h>
#import "BARTAssociateCategory.h"
#import "BARTDeallocObserver.h"
#import "BALogger.h"

static char ba_keyAssociatedRelationshipInfo;
static char ba_keyAssociatedOwnerInfo;

@interface BARTKVOOwnerItem : NSObject

@property (nonatomic, weak) id owner;
@property (nonatomic, copy) NSString *ownerClass;
@property (nonatomic, copy) NSString *ownerAddress;

@end

@interface BARTKVOOwnerInfo : NSObject

@property (nonatomic, strong) NSMutableDictionary *ownersDic;//key: ownerAddress, value: <BARTKVOOwnerItem *>ownerItem

@end

@interface BARTKVOObserverInfo : NSObject

@property (nonatomic, weak) id observer;
@property (nonatomic, copy) NSString *observerClass;
@property (nonatomic, copy) NSString *observerAddress;

@property (nonatomic, assign) NSUInteger options;

@property (nonatomic) void * context;

@end

@interface BARTKVORelationInfo : NSObject

@property (nonatomic, strong) NSMutableDictionary *relationsDic;//key: keyPath, value: <NSMutableArray <BARTKVOObserverInfo *> *>observers

- (BOOL)isRelationRegistered:(id)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;
- (BOOL)isRelationRegistered:(id)observer keyPath:(NSString *)keyPath context:(nullable void *)context;
- (BOOL)isRelationRegistered:(id)observer keyPath:(NSString *)keyPath;

- (void)registerRelation:(id)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;

- (void)unregisterRelation:(id)observer keyPath:(NSString *)keyPath context:(nullable void *)context;
- (void)unregisterRelation:(id)observer keyPath:(NSString *)keyPath;

@end

@interface NSObject(BARTKVOCrashBlockerCategory)
@end

@interface BARTKVOCrashBlocker () {
    pthread_mutex_t _mutexLock;
    BOOL _mutexLockValid;
    BOOL _blockerLoaded;
}

@end

@implementation BARTKVOOwnerItem
@end

@implementation BARTKVOOwnerInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        _ownersDic = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - public method
- (BOOL)isOwnerRegistered:(id)object
{
    if ([[self.ownersDic allKeys] containsObject:[NSString stringWithFormat:@"%p", object]]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)registerOwner:(id)object
{
    if (!object) {
        return;
    }
    
    NSString *objectAddress = [NSString stringWithFormat:@"%p", object];
    if ([[self.ownersDic allKeys] containsObject:objectAddress]) {
        return;
    }
    BARTKVOOwnerItem *newItem = [[BARTKVOOwnerItem alloc] init];
    newItem.owner = object;
    newItem.ownerClass = NSStringFromClass([object class]);
    newItem.ownerAddress = objectAddress;
    [self.ownersDic setObject:newItem forKey:objectAddress];
}

- (void)unregisterOwner:(id)object
{
    if (!object) {
        return;
    }
    NSString *objectAddress = [NSString stringWithFormat:@"%p", object];
    if ([[self.ownersDic allKeys] containsObject:objectAddress]) {
        [self.ownersDic removeObjectForKey:objectAddress];
    }
}

@end

@implementation BARTKVOObserverInfo

- (void)setObserver:(id)observer
{
    if (_observer != observer) {
        _observer = observer;
        _observerClass = NSStringFromClass([_observer class]);
        _observerAddress = [NSString stringWithFormat:@"%p", observer];
    }
}

@end

@implementation BARTKVORelationInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        _relationsDic = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - public method
- (BOOL)isRelationRegistered:(id)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context
{
    if (!observer || !keyPath || keyPath.length == 0) {
        return NO;
    }
    NSString *observerAddress = [NSString stringWithFormat:@"%p", observer];
    NSMutableArray *observersArray = [self.relationsDic objectForKey:keyPath];
    if (observersArray) {
        for (BARTKVOObserverInfo *observerInfo in observersArray) {
            if ([observerInfo.observerAddress isEqualToString:observerAddress] && context == observerInfo.context && options == observerInfo.options) {
                return YES;
            }
        }
        return NO;
    } else {
        return NO;
    }
}

- (BOOL)isRelationRegistered:(id)observer keyPath:(NSString *)keyPath context:(nullable void *)context
{
    if (!observer || !keyPath || keyPath.length == 0) {
        return NO;
    }
    NSString *observerAddress = [NSString stringWithFormat:@"%p", observer];
    NSMutableArray *observersArray = [self.relationsDic objectForKey:keyPath];
    if (observersArray) {
        for (BARTKVOObserverInfo *observerInfo in observersArray) {
            if ([observerInfo.observerAddress isEqualToString:observerAddress] && context == observerInfo.context) {
                return YES;
            }
        }
        return NO;
    } else {
        return NO;
    }
}

- (BOOL)isRelationRegistered:(id)observer keyPath:(NSString *)keyPath
{
    if (!observer || !keyPath || keyPath.length == 0) {
        return NO;
    }
    NSString *observerAddress = [NSString stringWithFormat:@"%p", observer];
    NSMutableArray *observersArray = [self.relationsDic objectForKey:keyPath];
    if (observersArray) {
        for (BARTKVOObserverInfo *observerInfo in observersArray) {
            if ([observerInfo.observerAddress isEqualToString:observerAddress]) {
                return YES;
            }
        }
        return NO;
    } else {
        return NO;
    }
}

- (void)registerRelation:(id)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context
{
    if (!observer || !keyPath || keyPath.length == 0) {
        return;
    }
    NSMutableArray *observersArray = [self.relationsDic objectForKey:keyPath];
    if (!observersArray) {
        observersArray = [[NSMutableArray alloc] init];
    }
    BARTKVOObserverInfo *newObserverInfo = [[BARTKVOObserverInfo alloc] init];
    newObserverInfo.observer = observer;
    newObserverInfo.options = options;
    newObserverInfo.context = context;
    [observersArray addObject:newObserverInfo];
    [self.relationsDic setObject:observersArray forKey:keyPath];
}

- (void)unregisterRelation:(id)observer keyPath:(NSString *)keyPath context:(nullable void *)context
{
    if (!observer || !keyPath || keyPath.length == 0) {
        return;
    }
    NSString *observerAddress = [NSString stringWithFormat:@"%p", observer];
    NSMutableArray *observersArray = [self.relationsDic objectForKey:keyPath];
    if (observersArray) {
        BARTKVOObserverInfo *observerInfoNeedDelete = nil;
        for (BARTKVOObserverInfo *item in observersArray) {
            if ([item.observerAddress isEqualToString:observerAddress] && context == item.context) {
                observerInfoNeedDelete = item;
                break;
            }
        }
        
        if (observerInfoNeedDelete) {
            [observersArray removeObject:observerInfoNeedDelete];
            if (observersArray.count > 0) {
                [self.relationsDic setObject:observersArray forKey:keyPath];
            } else {
                [self.relationsDic removeObjectForKey:keyPath];
            }
        }
    }
}

- (void)unregisterRelation:(id)observer keyPath:(NSString *)keyPath
{
    if (!observer || !keyPath || keyPath.length == 0) {
        return;
    }
    NSString *observerAddress = [NSString stringWithFormat:@"%p", observer];
    NSMutableArray *observersArray = [self.relationsDic objectForKey:keyPath];
    if (observersArray) {
        BARTKVOObserverInfo *observerInfoNeedDelete = nil;
        for (BARTKVOObserverInfo *item in observersArray) {
            if ([item.observerAddress isEqualToString:observerAddress]) {
                observerInfoNeedDelete = item;
                break;
            }
        }
        
        if (observerInfoNeedDelete) {
            [observersArray removeObject:observerInfoNeedDelete];
            if (observersArray.count > 0) {
                [self.relationsDic setObject:observersArray forKey:keyPath];
            } else {
                [self.relationsDic removeObjectForKey:keyPath];
            }
        }
    }
}

@end

@implementation NSObject(BARTKVOCrashBlockerCategory)

#pragma mark - exchanged method
- (void)BARTCB_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context
{
    if (!observer) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, addObserver:forKeyPath:options:context:, observer = nil, observed target class = %@", [self class]]];
        return;
    }
    if (!keyPath || keyPath.length == 0) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, addObserver:forKeyPath:options:context:, keyPath invalid, keyPath = %@, observed target class = %@", keyPath, [self class]]];
        return;
    }
    [self registerKVORelation:observer forKeyPath:keyPath options:options context:context];
}

- (void)BARTCB_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context
{
    if (!observer) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, removeObserver:forKeyPath:context:, observer = nil, observed target class = %@", [self class]]];
        return;
    }
    if (!keyPath || keyPath.length == 0) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, removeObserver:forKeyPath:context:, keyPath invalid, keyPath = %@, observed target class = %@", keyPath, [self class]]];
        return;
    }
    [self unregisterKVORelation:observer forKeyPath:keyPath];
}

- (void)BARTCB_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    if (!observer) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, removeObserver:forKeyPath:context:, observer = nil, observed target class = %@", [self class]]];
        return;
    }
    if (!keyPath || keyPath.length == 0) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, removeObserver:forKeyPath:context:, keyPath invalid, keyPath = %@, observed target class = %@", keyPath, [self class]]];
        return;
    }
    [self unregisterKVORelation:observer forKeyPath:keyPath];
}

#pragma mark - public method
- (void)removeSpecificKVORelation:(id)observer
{
    if (!observer) {
        return;
    }
    
    BARTKVORelationInfo *info = [self getRelationInfo];
    if (info) {
        NSMutableArray *invalidKeyPaths = nil;
        for (NSString *keyPath in [info.relationsDic allKeys]) {
            NSMutableArray *observerInfos = [info.relationsDic objectForKey:keyPath];
            BARTKVOObserverInfo *invalidObserverInfo = nil;
            for (BARTKVOObserverInfo *observerInfo in observerInfos) {
                if (observerInfo.observer == observer || [observerInfo.observerAddress isEqualToString:[NSString stringWithFormat:@"%p", observer]]) {
                    [self BARTCB_removeObserver:observer forKeyPath:keyPath];
                    invalidObserverInfo = observerInfo;
                    break;
                }
            }
            if (invalidObserverInfo) {
                [observerInfos removeObject:invalidObserverInfo];
                if (observerInfos.count == 0) {
                    if (!invalidKeyPaths) {
                        invalidKeyPaths = [[NSMutableArray alloc] init];
                    }
                    [invalidKeyPaths addObject:keyPath];
                }
            }
        }
        if (invalidKeyPaths && invalidKeyPaths.count > 0) {
            [info.relationsDic removeObjectsForKeys:invalidKeyPaths];
        }
    }
}

#pragma mark - private method
#pragma mark owner info method
- (BARTKVOOwnerInfo *)getKVOOwnerInfo
{
    return [NSObject ba_getAssociatedAttribute:&ba_keyAssociatedOwnerInfo from:self];
}

- (void)setKVOOwnerInfo:(BARTKVOOwnerInfo *)info
{
    if (info) {
        [NSObject ba_setAssociatedAttribute:info withKey:&ba_keyAssociatedOwnerInfo policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC to:self];
    }
}

#pragma mark relation info method
- (BARTKVORelationInfo *)getRelationInfo
{
    return [NSObject ba_getAssociatedAttribute:&ba_keyAssociatedRelationshipInfo from:self];
}

- (void)setRelationInfo:(BARTKVORelationInfo *)info
{
    if (info) {
        [NSObject ba_setAssociatedAttribute:info withKey:&ba_keyAssociatedRelationshipInfo policy:OBJC_ASSOCIATION_RETAIN_NONATOMIC to:self];
    }
}

- (void)registerKVORelation:(id)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context
{
    dispatch_semaphore_wait([self KVOCrashBlockerSemaphore], DISPATCH_TIME_FOREVER);
    
    BOOL KVORelationRegistered = NO;
    BARTKVORelationInfo *relationInfo = [self getRelationInfo];
    if (relationInfo) {
        KVORelationRegistered = [relationInfo isRelationRegistered:observer keyPath:keyPath options:options context:context];
    } else {
        relationInfo = [[BARTKVORelationInfo alloc] init];
        [self setRelationInfo:relationInfo];
    }
    if (!KVORelationRegistered) {
        //register KVO relation
        [relationInfo registerRelation:observer keyPath:keyPath options:options context:context];
        
        //register KVO owner
        BARTKVOOwnerInfo *ownerInfo = [observer getKVOOwnerInfo];
        if (!ownerInfo) {
            ownerInfo = [[BARTKVOOwnerInfo alloc] init];
            [observer setKVOOwnerInfo:ownerInfo];
        }
        [ownerInfo registerOwner:self];
        
        //start dealloc observer
        [self ba_startDeallocObserving:@selector(selfWillDeallocAction) didDeallocBlock:nil];
        [observer ba_startDeallocObserving:@selector(selfWillDeallocAction) didDeallocBlock:nil];
        
        //real start KVO action
        [self BARTCB_addObserver:observer forKeyPath:keyPath options:options context:context];
    }
    
    dispatch_semaphore_signal([self KVOCrashBlockerSemaphore]);
    
    if (KVORelationRegistered) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, duplicate addObserver, observer class = %@, keyPath = %@, observed target class = %@", [observer class], keyPath, [self class]]];
    }
}

- (void)unregisterKVORelation:(id)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context
{
    dispatch_semaphore_wait([self KVOCrashBlockerSemaphore], DISPATCH_TIME_FOREVER);
    
    BOOL KVORelationRegistered = NO;
    BARTKVORelationInfo *relationInfo = [self getRelationInfo];
    if (relationInfo) {
        KVORelationRegistered = [relationInfo isRelationRegistered:observer keyPath:keyPath context:context];
    } else {
        [self ba_stopDeallocObserving];
    }
    if (KVORelationRegistered) {
        //unregister KVO relation
        [relationInfo unregisterRelation:observer keyPath:keyPath context:context];
        
        //unregister KVO owner
        BARTKVOOwnerInfo *ownerInfo = [observer getKVOOwnerInfo];
        if (ownerInfo) {
            [ownerInfo unregisterOwner:self];
            if (ownerInfo.ownersDic.count == 0) {
                [observer ba_stopDeallocObserving];
            }
        } else {
            [observer ba_stopDeallocObserving];
        }
        
        //stop dealloc observing if need
        if (relationInfo.relationsDic.count == 0) {
            [self ba_stopDeallocObserving];
        }
        
        //real start KVO action
        [self BARTCB_removeObserver:observer forKeyPath:keyPath context:context];
    }
    
    dispatch_semaphore_signal([self KVOCrashBlockerSemaphore]);
    
    if (!KVORelationRegistered) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, remove unregistered observer, observer class = %@, keyPath = %@, observed target class = %@", [observer class], keyPath, [self class]]];
    }
}

- (void)unregisterKVORelation:(id)observer forKeyPath:(NSString *)keyPath
{
    dispatch_semaphore_wait([self KVOCrashBlockerSemaphore], DISPATCH_TIME_FOREVER);
    
    BOOL KVORelationRegistered = NO;
    BARTKVORelationInfo *relationInfo = [self getRelationInfo];
    if (relationInfo) {
        KVORelationRegistered = [relationInfo isRelationRegistered:observer keyPath:keyPath];
    } else {
        [self ba_stopDeallocObserving];
    }
    if (KVORelationRegistered) {
        //unregister KVO relation
        [relationInfo unregisterRelation:observer keyPath:keyPath];
        
        //unregister KVO owner
        BARTKVOOwnerInfo *ownerInfo = [observer getKVOOwnerInfo];
        if (ownerInfo) {
            [ownerInfo unregisterOwner:self];
            if (ownerInfo.ownersDic.count == 0) {
                [observer ba_stopDeallocObserving];
            }
        } else {
            [observer ba_stopDeallocObserving];
        }
        
        //stop dealloc observing if need
        if (relationInfo.relationsDic.count == 0) {
            [self ba_stopDeallocObserving];
        }
        
        //real start KVO action
        [self BARTCB_removeObserver:observer forKeyPath:keyPath];
    }
    
    dispatch_semaphore_signal([self KVOCrashBlockerSemaphore]);
    
    if (!KVORelationRegistered) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, remove unregistered observer, observer class = %@, keyPath = %@, observed target class = %@", [observer class], keyPath, [self class]]];
    }
}

#pragma mark others
- (void)selfWillDeallocAction
{
    dispatch_semaphore_wait([self KVOCrashBlockerSemaphore], DISPATCH_TIME_FOREVER);
    
    BARTKVORelationInfo *relationInfo = objc_getAssociatedObject(self, &ba_keyAssociatedRelationshipInfo);
    if (relationInfo.relationsDic && relationInfo.relationsDic.count > 0) {
        for (NSString *keyPath in [relationInfo.relationsDic allKeys]) {
            NSArray *observerInfos = [relationInfo.relationsDic objectForKey:keyPath];
            for (BARTKVOObserverInfo *observerInfo in observerInfos) {
                if (observerInfo.observer) {
                    [self BARTCB_removeObserver:observerInfo.observer forKeyPath:keyPath];
                }
            }
        }
        [relationInfo.relationsDic removeAllObjects];
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, be observed object released, be observed object class = %@", [self class]]];
    }
    
    BARTKVOOwnerInfo *ownerInfo = objc_getAssociatedObject(self, &ba_keyAssociatedOwnerInfo);
    if (ownerInfo.ownersDic && ownerInfo.ownersDic.count > 0) {
        for (NSString *ownerAddress in [ownerInfo.ownersDic allKeys]) {
            BARTKVOOwnerItem *item = [ownerInfo.ownersDic objectForKey:ownerAddress];
            if (item.owner) {
                [item.owner removeSpecificKVORelation:self];
            }
        }
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, observer released, observer object class = %@", [self class]]];
    }
    
    dispatch_semaphore_signal([self KVOCrashBlockerSemaphore]);
}

- (dispatch_semaphore_t)KVOCrashBlockerSemaphore
{
    static dispatch_semaphore_t KVOCrashBlockerSemaphore;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KVOCrashBlockerSemaphore = dispatch_semaphore_create(1);
    });
    return KVOCrashBlockerSemaphore;
}

@end

@implementation BARTKVOCrashBlocker

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
    static BARTKVOCrashBlocker *KVOCrashBlocker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KVOCrashBlocker = [[BARTKVOCrashBlocker alloc] init];
    });
    return KVOCrashBlocker;
}

- (void)load
{
    pthread_mutex_lock(&_mutexLock);
    if (!_blockerLoaded) {
        [self replaceMethods];
        _blockerLoaded = YES;
        [[BALogger sharedLogger] log:@"KVO crash blocker loaded"];
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (void)unload
{
    pthread_mutex_lock(&_mutexLock);
    if (_blockerLoaded) {
        [self replaceMethods];
        _blockerLoaded = NO;
        [[BALogger sharedLogger] log:@"KVO crash blocker unloaded"];
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

#pragma mark - private method
- (void)replaceMethods
{
    method_exchangeImplementations(class_getInstanceMethod([NSObject class], @selector(addObserver:forKeyPath:options:context:)), class_getInstanceMethod([NSObject class], @selector(BARTCB_addObserver:forKeyPath:options:context:)));
    method_exchangeImplementations(class_getInstanceMethod([NSObject class], @selector(removeObserver:forKeyPath:)), class_getInstanceMethod([NSObject class], @selector(BARTCB_removeObserver:forKeyPath:)));
}

@end
