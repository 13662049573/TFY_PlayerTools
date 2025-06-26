//
//  TFY_KVOController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFY_KVOController.h"

// 调试日志控制宏
#ifdef DEBUG
    #define TFYKVOLog(fmt, ...) NSLog((@"[TFY_KVO] " fmt), ##__VA_ARGS__)
#else
    #define TFYKVOLog(fmt, ...)
#endif

@interface TFY_KVOEntry : NSObject
@property (nonatomic, weak) id observer;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, copy) void(^block)(id obj, NSDictionary *change);
@end

@implementation TFY_KVOEntry
@end

@interface TFY_KVOController ()
@property (nonatomic, strong) NSMutableArray<TFY_KVOEntry *> *entries;
@property (nonatomic, weak) NSObject *target;
@end

@implementation TFY_KVOController

- (instancetype)initWithTarget:(NSObject *)target {
    self = [self init];
    if (self) {
        _target = target;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _entries = [NSMutableArray array];
    }
    return self;
}

- (void)addObserver:(id)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(void(^)(id obj, NSDictionary *change))block {
    // 检查是否已经存在相同的观察者
    for (TFY_KVOEntry *entry in self.entries) {
        if (entry.observer == observer && [entry.keyPath isEqualToString:keyPath]) {
            TFYKVOLog(@"duplicated observer");
            return;
        }
    }
    
    TFY_KVOEntry *entry = [[TFY_KVOEntry alloc] init];
    entry.observer = observer;
    entry.keyPath = keyPath;
    entry.block = block;
    
    @try {
        [observer addObserver:self forKeyPath:keyPath options:options context:(__bridge void *)(entry)];
        [self.entries addObject:entry];
    } @catch (NSException *e) {
        TFYKVOLog(@"TFYKVO: failed to add observer for %@\n", keyPath);
    }
}

- (void)removeObserver:(id)observer forKeyPath:(NSString *)keyPath {
    // 检查是否已经存在相同的观察者
    for (TFY_KVOEntry *entry in self.entries) {
        if (entry.observer == observer && [entry.keyPath isEqualToString:keyPath]) {
            TFYKVOLog(@"duplicated observer");
            return;
        }
    }
    
    @try {
        [observer removeObserver:self forKeyPath:keyPath];
    } @catch (NSException *e) {
        TFYKVOLog(@"TFYKVO: failed to remove observer for %@\n", keyPath);
    }
}

- (void)removeAllObservers {
    for (TFY_KVOEntry *entry in self.entries) {
        if (entry.observer) {
            @try {
                [entry.observer removeObserver:self forKeyPath:entry.keyPath];
            } @catch (NSException *e) {
                TFYKVOLog(@"TFYKVO: failed to remove observer for %@\n", entry.keyPath);
            }
        }
    }
    [self.entries removeAllObjects];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    TFY_KVOEntry *entry = (__bridge TFY_KVOEntry *)(context);
    if (entry.block) {
        entry.block(object, change);
    }
}

- (void)safelyAddObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    @try {
        [observer addObserver:self forKeyPath:keyPath options:options context:context];
    } @catch (NSException *exception) {
        TFYKVOLog(@"Failed to safely add observer for %@: %@", keyPath, exception);
    }
}

- (void)safelyRemoveAllObservers {
    for (TFY_KVOEntry *entry in self.entries) {
        if (entry.observer) {
            @try {
                [entry.observer removeObserver:self forKeyPath:entry.keyPath];
            } @catch (NSException *e) {
                TFYKVOLog(@"Failed to safely remove observer for %@: %@", entry.keyPath, e);
            }
        }
    }
    [self.entries removeAllObjects];
}

- (void)safelyRemoveObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    @try {
        [observer removeObserver:self forKeyPath:keyPath];
    } @catch (NSException *e) {
        TFYKVOLog(@"Failed to safely remove observer for %@: %@", keyPath, e);
    }
}

- (void)dealloc {
    [self removeAllObservers];
}

@end
