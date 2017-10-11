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
#import "BALogger.h"

#define KEY_ASSOCIATED_PROXY "BARTObjectAssociatedProxy"

@interface BARTKVOProxyContainer : NSObject

@property (nonatomic, weak) id context;
@property (nonatomic, copy) NSString *contextClass;

@end

@interface BARTKVOProxy : NSObject

@property (nonatomic, weak) id target;//the object be observed
@property (nonatomic, copy) NSString *targetClass;//class of the object be observed
@property (nonatomic, strong) NSMutableDictionary *KVORelationsDic;//key: keyPath, value: <NSArray *>observers

- (BOOL)isKVORelationRegistered:(id)observer keyPath:(NSString *)keyPath;
- (void)registerKVORelation:(id)observer keyPath:(NSString *)keyPath;
- (void)unregisterKVORelation:(id)observer keyPath:(NSString *)keyPath;

@end

@interface NSObject(BARTKVOCrashBlockerCategory)
@end

@interface BARTKVOCrashBlocker () {
    pthread_mutex_t _mutexLock;
    BOOL _mutexLockValid;
    BOOL _blockerLoaded;
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
    [self unregisterKVORelation:observer forKeyPath:keyPath context:context];
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

#pragma mark - private method
- (BARTKVOProxy *)KVOProxy
{
    BARTKVOProxy *result = [self getAssociatedAttribute:KEY_ASSOCIATED_PROXY];
    if (!result) {
        result = [[BARTKVOProxy alloc] init];
        result.target = self;
        result.targetClass = NSStringFromClass([self class]);
        [self setAssociatedAttribute:result withKey:KEY_ASSOCIATED_PROXY];
    }
    return result;
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

- (void)registerKVORelation:(id)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context
{
    dispatch_semaphore_wait([self KVOCrashBlockerSemaphore], DISPATCH_TIME_FOREVER);
    
    BARTKVOProxy *KVOProxy = [self KVOProxy];
    BOOL KVORelationRegistered = [KVOProxy isKVORelationRegistered:observer keyPath:keyPath];
    if (!KVORelationRegistered) {
        [self BARTCB_addObserver:KVOProxy forKeyPath:keyPath options:options context:context];
        [KVOProxy registerKVORelation:observer keyPath:keyPath];
    }
    
    dispatch_semaphore_signal([self KVOCrashBlockerSemaphore]);
    
    if (KVORelationRegistered) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, duplicate addObserver, observer class = %@, keyPath = %@, observed target class = %@", [observer class], keyPath, [self class]]];
    }
}

- (void)unregisterKVORelation:(id)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context
{
    dispatch_semaphore_wait([self KVOCrashBlockerSemaphore], DISPATCH_TIME_FOREVER);
    
    BARTKVOProxy *KVOProxy = [self KVOProxy];
    BOOL KVORelationRegistered = [KVOProxy isKVORelationRegistered:observer keyPath:keyPath];
    if (KVORelationRegistered) {
        [self BARTCB_removeObserver:KVOProxy forKeyPath:keyPath context:context];
        [KVOProxy unregisterKVORelation:observer keyPath:keyPath];
    }
    
    dispatch_semaphore_signal([self KVOCrashBlockerSemaphore]);
    
    if (!KVORelationRegistered) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, remove unregistered observer, observer class = %@, keyPath = %@, observed target class = %@", [observer class], keyPath, [self class]]];
    }
}

- (void)unregisterKVORelation:(id)observer forKeyPath:(NSString *)keyPath
{
    dispatch_semaphore_wait([self KVOCrashBlockerSemaphore], DISPATCH_TIME_FOREVER);
    
    BARTKVOProxy *KVOProxy = [self KVOProxy];
    BOOL KVORelationRegistered = [KVOProxy isKVORelationRegistered:observer keyPath:keyPath];
    if (KVORelationRegistered) {
        [self BARTCB_removeObserver:KVOProxy forKeyPath:keyPath];
        [KVOProxy unregisterKVORelation:observer keyPath:keyPath];
    }
    
    dispatch_semaphore_signal([self KVOCrashBlockerSemaphore]);
    
    if (!KVORelationRegistered) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, remove unregistered observer, observer class = %@, keyPath = %@, observed target class = %@", [observer class], keyPath, [self class]]];
    }
}

- (void)setAssociatedAttribute:(id)value withKey:(void *)key
{
    objc_setAssociatedObject(self, key, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)getAssociatedAttribute:(void *)key
{
    return objc_getAssociatedObject(self, key);
}

- (void)removeAssociatedAttribute:(void *)key
{
    objc_setAssociatedObject(self, key, nil, OBJC_ASSOCIATION_ASSIGN);
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

#pragma mark - private method
- (void)replaceMethods
{
    method_exchangeImplementations(class_getInstanceMethod([NSObject class], @selector(addObserver:forKeyPath:options:context:)), class_getInstanceMethod([NSObject class], @selector(BARTCB_addObserver:forKeyPath:options:context:)));
    method_exchangeImplementations(class_getInstanceMethod([NSObject class], @selector(removeObserver:forKeyPath:context:)), class_getInstanceMethod([NSObject class], @selector(BARTCB_removeObserver:forKeyPath:context:)));
    method_exchangeImplementations(class_getInstanceMethod([NSObject class], @selector(removeObserver:forKeyPath:)), class_getInstanceMethod([NSObject class], @selector(BARTCB_removeObserver:forKeyPath:)));
}

@end

@implementation BARTKVOProxyContainer
@end

@implementation BARTKVOProxy

- (void)dealloc
{
    if (self.KVORelationsDic.count > 0) {
        [self.KVORelationsDic removeAllObjects];
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, observered target released, observed target class = %@", self.targetClass]];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _KVORelationsDic = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - public method
- (BOOL)isKVORelationRegistered:(id)observer keyPath:(NSString *)keyPath
{
    if (!observer || !keyPath || keyPath.length == 0) {
        return NO;
    }
    NSMutableArray *observersArray = [self.KVORelationsDic objectForKey:keyPath];
    if (observersArray) {
        for (BARTKVOProxyContainer *container in observersArray) {
            if (container.context == observer) {
                return YES;
            }
        }
        return NO;
    } else {
        return NO;
    }
}

- (void)registerKVORelation:(id)observer keyPath:(NSString *)keyPath
{
    if (!observer || !keyPath || keyPath.length == 0) {
        return;
    }
    NSMutableArray *observersArray = [self.KVORelationsDic objectForKey:keyPath];
    if (observersArray) {
        for (BARTKVOProxyContainer *container in observersArray) {
            if (container.context == observer) {
                return;
            }
        }
    } else {
        observersArray = [[NSMutableArray alloc] init];
    }
    BARTKVOProxyContainer *newContainer = [[BARTKVOProxyContainer alloc] init];
    newContainer.context = observer;
    newContainer.contextClass = NSStringFromClass([observer class]);
    [observersArray addObject:newContainer];
    [self.KVORelationsDic setObject:observersArray forKey:keyPath];
}

- (void)unregisterKVORelation:(id)observer keyPath:(NSString *)keyPath
{
    if (!observer || !keyPath || keyPath.length == 0) {
        return;
    }
    NSMutableArray *observersArray = [self.KVORelationsDic objectForKey:keyPath];
    if (observersArray) {
        BARTKVOProxyContainer *containerNeedDelete = nil;
        for (BARTKVOProxyContainer *container in observersArray) {
            if (container.context == observer) {
                containerNeedDelete = container;
                break;
            }
        }
        if (containerNeedDelete) {
            [observersArray removeObject:containerNeedDelete];
            if (observersArray.count > 0) {
                [self.KVORelationsDic setObject:observersArray forKey:keyPath];
            } else {
                [self.KVORelationsDic removeObjectForKey:keyPath];
            }
        }
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context
{
    if (object != self.target || ![[self.KVORelationsDic allKeys] containsObject:keyPath]) {
        return;
    }
    if (!self.target) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, observered target released, keyPath = %@, observed target class = %@", keyPath, self.targetClass]];
        return;
    }
    NSMutableArray *observersArray = [self.KVORelationsDic objectForKey:keyPath];
    if (observersArray) {
        NSMutableArray *invalidContainer = nil;
        for (BARTKVOProxyContainer *container in observersArray) {
            if (container.context) {
                if ([container.context respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
                    [container.context observeValueForKeyPath:keyPath ofObject:object change:change context:context];
                }
            } else {
                if (!invalidContainer) {
                    invalidContainer = [[NSMutableArray alloc] init];
                }
                [invalidContainer addObject:container];
                [[BALogger sharedLogger] log:[NSString stringWithFormat:@"KVO crash, observer released, observer class = %@, keyPath = %@, observed target class = %@", container.contextClass, keyPath, self.targetClass]];
            }
        }
        if (invalidContainer && invalidContainer.count > 0) {
            [observersArray removeObjectsInArray:invalidContainer];
            if (observersArray.count > 0) {
                [self.KVORelationsDic setObject:keyPath forKey:observersArray];
            } else {
                [self.KVORelationsDic removeObjectForKey:keyPath];
            }
        }
        
    }
}

@end
