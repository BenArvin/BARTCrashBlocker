//
//  BARTContainerCrashBlocker.m
//  BARTCrashBlocker
//
//  Created by BenArvin on 2017/10/9.
//  Copyright © 2017年 cn.BenArvin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BARTContainerCrashBlocker.h"
#import <objc/runtime.h>
#import <pthread.h>
#import "BALogger.h"

@interface NSArray(BARTContainerCrashBlockerNSArrayCategory)
@end

@implementation NSArray(BARTContainerCrashBlockerNSArrayCategory)

- (id)BARTCB_objectAtIndex:(NSUInteger)index
{
    if (index >= self.count) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"container crash, NSArray count = %ld, index = %lu", self.count, (unsigned long)index]];
        return nil;
    } else {
        return [self BARTCB_objectAtIndex:index];
    }
}

@end

@interface NSMutableArray(BARTContainerCrashBlockerNSMutableArrayCategory)
@end

@implementation NSMutableArray(BARTContainerCrashBlockerNSMutableArrayCategory)

- (id)BARTCB_objectAtIndex:(NSUInteger)index
{
    if (index >= self.count) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"container crash, NSMutableArray objectAtIndex:, count = %ld, index = %lu", self.count, (unsigned long)index]];
        return nil;
    } else {
        return [self BARTCB_objectAtIndex:index];
    }
}

- (void)BARTCB_addObject:(id)anObject
{
    if (!anObject) {
        [[BALogger sharedLogger] log:@"container crash, NSMutableArray addObject:, object = nil"];
        return;
    } else {
        [self BARTCB_addObject:anObject];
    }
}

- (void)BARTCB_insertObject:(id)anObject atIndex:(NSUInteger)index
{
    if (!anObject) {
        [[BALogger sharedLogger] log:@"container crash, NSMutableArray insertObject:atIndex:, object = nil"];
        return;
    } else {
        if (index > self.count) {
            [[BALogger sharedLogger] log:[NSString stringWithFormat:@"container crash, NSMutableArray insertObject:atIndex:, count = %ld, index = %lu", self.count, (unsigned long)index]];
            [self addObject:anObject];
        } else {
            [self BARTCB_insertObject:anObject atIndex:index];
        }
    }
}

- (void)BARTCB_removeObjectAtIndex:(NSUInteger)index;
{
    if (index >= self.count) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"container crash, NSMutableArray removeObjectAtIndex:, count = %ld, index = %lu", self.count, (unsigned long)index]];
        return;
    } else {
        [self BARTCB_removeObjectAtIndex:index];
    }
}

- (void)BARTCB_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    if (index >= self.count) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"container crash, NSMutableArray replaceObjectAtIndex:withObject:, count = %ld, index = %lu", self.count, (unsigned long)index]];
        return;
    } else if (!anObject) {
        [[BALogger sharedLogger] log:@"container crash, NSMutableArray replaceObjectAtIndex:withObject:, object = nil"];
        [self removeObjectAtIndex:index];
    } else {
        [self BARTCB_replaceObjectAtIndex:index withObject:anObject];
    }
}

@end

@interface NSMutableDictionary(BARTContainerCrashBlockerNSMutableDictionaryCategory)
@end

@implementation NSMutableDictionary(BARTContainerCrashBlockerNSMutableDictionaryCategory)

- (void)BARTCB_removeObjectForKey:(id <NSCopying>)aKey
{
    if (!aKey) {
        [[BALogger sharedLogger] log:@"container crash, NSMutableDictionary removeObjectForKey:, key = nil"];
        return;
    } else {
        [self BARTCB_removeObjectForKey:aKey];
    }
}

- (void)BARTCB_setObject:(id)anObject forKey:(id <NSCopying>)aKey
{
    if (!aKey) {
        [[BALogger sharedLogger] log:@"container crash, NSMutableDictionary setObject:forKey:, key = nil"];
        return;
    } else if (!anObject) {
        [[BALogger sharedLogger] log:@"container crash, NSMutableDictionary setObject:forKey:, object = nil"];
        [self removeObjectForKey:aKey];
        return;
    } else {
        [self BARTCB_setObject:anObject forKey:aKey];
    }
}

@end

@interface NSString(BARTContainerCrashBlockerNSStringCategory)
@end

@implementation NSString(BARTContainerCrashBlockerNSStringCategory)

- (NSRange)BARTCB_rangeOfString:(NSString *)searchString options:(NSStringCompareOptions)mask range:(NSRange)rangeOfReceiverToSearch locale:(nullable NSLocale *)locale
{
    if (!searchString) {
        [[BALogger sharedLogger] log:@"container crash, NSString rangeOfString:options:range:locale:, searchString = nil"];
        return NSMakeRange(NSNotFound, 0);
    } else if (rangeOfReceiverToSearch.location > self.length || rangeOfReceiverToSearch.location + rangeOfReceiverToSearch.length > self.length) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"container crash, NSString rangeOfString:options:range:locale:, self length = %ld, rangeOfReceiverToSearch = %@", self.length, NSStringFromRange(rangeOfReceiverToSearch)]];
        if (rangeOfReceiverToSearch.location > self.length) {
            return NSMakeRange(NSNotFound, 0);
        } else {
            return [self BARTCB_rangeOfString:searchString options:mask range:NSMakeRange(rangeOfReceiverToSearch.location, self.length - rangeOfReceiverToSearch.location) locale:locale];
        }
    } else {
        return [self BARTCB_rangeOfString:searchString options:mask range:rangeOfReceiverToSearch locale:locale];
    }
}

@end

@interface NSMutableString(BARTContainerCrashBlockerNSMutableStringCategory)
@end

@implementation NSMutableString(BARTContainerCrashBlockerNSMutableStringCategory)

- (void)BARTCB_appendString:(NSString *)aString
{
    if (!aString) {
        [[BALogger sharedLogger] log:@"container crash, NSMutableString appendString:, string = nil"];
        return;
    } else {
        [self BARTCB_appendString:aString];
    }
}

- (void)BARTCB_replaceCharactersInRange:(NSRange)range withString:(NSString *)aString
{
    if (range.location > self.length || range.location + range.length > self.length) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"container crash, NSMutableString replaceCharactersInRange:withString:, self length = %ld, range = %@", self.length, NSStringFromRange(range)]];
        return;
    } else if (!aString) {
        [[BALogger sharedLogger] log:@"container crash, NSMutableString replaceCharactersInRange:withString:, string = nil"];
        [self deleteCharactersInRange:range];
        return;
    } else {
        [self BARTCB_replaceCharactersInRange:range withString:aString];
    }
}

- (void)BARTCB_insertString:(NSString *)aString atIndex:(NSUInteger)loc
{
    if (!aString) {
        [[BALogger sharedLogger] log:@"container crash, NSMutableString insertString:atIndex:, string = nil"];
        return;
    } else if (loc > self.length) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"container crash, NSMutableString insertString:atIndex:, self length = %ld, index = %lu", self.length, loc]];
        [self appendString:aString];
        return;
    } else {
        [self BARTCB_insertString:aString atIndex:loc];
    }
}

- (void)BARTCB_deleteCharactersInRange:(NSRange)range
{
    if (range.location > self.length || range.location + range.length > self.length) {
        [[BALogger sharedLogger] log:[NSString stringWithFormat:@"container crash, NSMutableString deleteCharactersInRange:, self length = %ld, range = %@", self.length, NSStringFromRange(range)]];
        if (range.location > self.length) {
            return;
        } else {
            [self BARTCB_deleteCharactersInRange:NSMakeRange(range.location, self.length - range.location)];
        }
    } else {
        [self BARTCB_deleteCharactersInRange:range];
    }
}

@end

@interface BARTContainerCrashBlocker () {
    pthread_mutex_t _mutexLock;
    BOOL _mutexLockValid;
    BOOL _blockerLoaded;
}

@end

@implementation BARTContainerCrashBlocker

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
    static BARTContainerCrashBlocker *containerCrashBlocker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        containerCrashBlocker = [[BARTContainerCrashBlocker alloc] init];
    });
    return containerCrashBlocker;
}

- (void)load
{
    pthread_mutex_lock(&_mutexLock);
    if (!_blockerLoaded) {
        [self replaceMethods];
        _blockerLoaded = YES;
        [[BALogger sharedLogger] log:@"container crash blocker loaded"];
    }
    pthread_mutex_unlock(&_mutexLock);
}

- (void)unload
{
    pthread_mutex_lock(&_mutexLock);
    if (_blockerLoaded) {
        [self replaceMethods];
        _blockerLoaded = NO;
        [[BALogger sharedLogger] log:@"container crash blocker unloaded"];
    }
    pthread_mutex_unlock(&_mutexLock);
}

#pragma mark - private method
- (void)replaceMethods
{
    //NSArray
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSArrayI"), @selector(objectAtIndex:)), class_getInstanceMethod(objc_getClass("__NSArrayI"), @selector(BARTCB_objectAtIndex:)));
    
    //NSMutableArray
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(objectAtIndex:)), class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(BARTCB_objectAtIndex:)));
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(addObject:)), class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(BARTCB_addObject:)));
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(insertObject:atIndex:)), class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(BARTCB_insertObject:atIndex:)));
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(removeObjectAtIndex:)), class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(BARTCB_removeObjectAtIndex:)));
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(replaceObjectAtIndex:withObject:)), class_getInstanceMethod(objc_getClass("__NSArrayM"), @selector(BARTCB_replaceObjectAtIndex:withObject:)));
    
    //NSMutableDictionary
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSDictionaryM"), @selector(removeObjectForKey:)), class_getInstanceMethod(objc_getClass("__NSDictionaryM"), @selector(BARTCB_removeObjectForKey:)));
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSDictionaryM"), @selector(setObject:forKey:)), class_getInstanceMethod(objc_getClass("__NSDictionaryM"), @selector(BARTCB_setObject:forKey:)));
    
    //NSString
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSCFString"), @selector(rangeOfString:options:range:locale:)), class_getInstanceMethod(objc_getClass("__NSCFString"), @selector(BARTCB_rangeOfString:options:range:locale:)));
    
    //NSMutableString
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSCFString"), @selector(appendString:)), class_getInstanceMethod(objc_getClass("__NSCFString"), @selector(BARTCB_appendString:)));
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSCFString"), @selector(replaceCharactersInRange:withString:)), class_getInstanceMethod(objc_getClass("__NSCFString"), @selector(BARTCB_replaceCharactersInRange:withString:)));
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSCFString"), @selector(insertString:atIndex:)), class_getInstanceMethod(objc_getClass("__NSCFString"), @selector(BARTCB_insertString:atIndex:)));
    method_exchangeImplementations(class_getInstanceMethod(objc_getClass("__NSCFString"), @selector(deleteCharactersInRange:)), class_getInstanceMethod(objc_getClass("__NSCFString"), @selector(BARTCB_deleteCharactersInRange:)));
}

@end
