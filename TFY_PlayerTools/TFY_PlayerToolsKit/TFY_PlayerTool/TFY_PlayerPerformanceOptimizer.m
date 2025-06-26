//
//  TFY_PlayerPerformanceOptimizer.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFY_PlayerPerformanceOptimizer.h"
#import <mach/mach.h>
#import <sys/sysctl.h>

@interface TFY_PlayerPerformanceOptimizer ()

@property (nonatomic, strong) NSCache *globalCache;
@property (nonatomic, strong) NSTimer *performanceTimer;
@property (nonatomic, strong) NSMutableDictionary *performanceStats;
@property (nonatomic, assign) CFTimeInterval startTime;

@end

@implementation TFY_PlayerPerformanceOptimizer

+ (instancetype)sharedOptimizer {
    static TFY_PlayerPerformanceOptimizer *optimizer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        optimizer = [[self alloc] init];
    });
    return optimizer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupDefaultConfiguration];
        [self setupGlobalCache];
    }
    return self;
}

- (void)dealloc {
    [self stopPerformanceMonitoring];
}

#pragma mark - 默认配置

- (void)setupDefaultConfiguration {
    self.animationOptimizationEnabled = YES;
    self.imageCacheOptimizationEnabled = YES;
    self.scrollPerformanceOptimizationEnabled = YES;
    
    // 根据设备内存动态设置缓存限制
    NSUInteger totalMemory = [self getTotalMemory];
    self.memoryCacheLimit = totalMemory * 0.1; // 10% 的总内存
    self.diskCacheLimit = 100 * 1024 * 1024; // 100MB
}

- (void)setupGlobalCache {
    self.globalCache = [[NSCache alloc] init];
    self.globalCache.totalCostLimit = self.memoryCacheLimit;
    self.globalCache.countLimit = 200;
    
    // 监听内存警告
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMemoryWarning)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
}

#pragma mark - 缓存管理

- (void)clearAllCaches {
    [self clearMemoryCache];
    // 清理图片缓存等其他缓存
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // 清理磁盘缓存的实现
        [self clearDiskCache];
    });
}

- (void)clearMemoryCache {
    [self.globalCache removeAllObjects];
    
    // 移除对私有API的调用，避免警告
    // 私有API在生产环境中不应该使用
}

- (void)clearDiskCache {
    // 清理磁盘缓存的具体实现
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths firstObject];
    NSString *playerCacheDir = [cacheDirectory stringByAppendingPathComponent:@"TFYPlayerCache"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:playerCacheDir]) {
        [fileManager removeItemAtPath:playerCacheDir error:nil];
    }
}

- (NSUInteger)currentMemoryUsage {
    struct mach_task_basic_info info;
    mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
    kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0;
}

#pragma mark - 性能监控

- (void)startPerformanceMonitoring {
    if (self.performanceTimer) {
        [self stopPerformanceMonitoring];
    }
    
    self.startTime = CACurrentMediaTime();
    self.performanceStats = [NSMutableDictionary dictionary];
    
    self.performanceTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(collectPerformanceData) userInfo:nil repeats:YES];
}

- (void)stopPerformanceMonitoring {
    if (self.performanceTimer) {
        [self.performanceTimer invalidate];
        self.performanceTimer = nil;
    }
}

- (void)collectPerformanceData {
    NSUInteger memoryUsage = [self currentMemoryUsage];
    CFTimeInterval currentTime = CACurrentMediaTime();
    
    self.performanceStats[@"memoryUsage"] = @(memoryUsage);
    self.performanceStats[@"uptime"] = @(currentTime - self.startTime);
    self.performanceStats[@"cacheHitRate"] = [self calculateCacheHitRate];
}

- (NSDictionary *)getPerformanceStats {
    NSMutableDictionary *stats = [self.performanceStats mutableCopy];
    stats[@"currentMemoryUsage"] = @([self currentMemoryUsage]);
    stats[@"totalMemory"] = @([self getTotalMemory]);
    stats[@"cacheCount"] = @(self.globalCache.countLimit);
    return [stats copy];
}

#pragma mark - 优化建议

- (NSDictionary *)getOptimizationRecommendations {
    NSMutableDictionary *recommendations = [NSMutableDictionary dictionary];
    
    NSUInteger currentMemory = [self currentMemoryUsage];
    NSUInteger totalMemory = [self getTotalMemory];
    CGFloat memoryUsagePercent = (CGFloat)currentMemory / totalMemory;
    
    if (memoryUsagePercent > 0.8) {
        recommendations[@"memoryOptimization"] = @"建议减少缓存大小，清理不必要的对象";
        recommendations[@"suggestedMemoryCacheLimit"] = @(self.memoryCacheLimit * 0.7);
    }
    
    // 根据设备性能给出建议
    NSString *deviceModel = [self getDeviceModel];
    if ([deviceModel containsString:@"iPhone6"] || [deviceModel containsString:@"iPhone5"]) {
        recommendations[@"animationOptimization"] = @"建议禁用复杂动画以提升性能";
        recommendations[@"suggestedAnimationEnabled"] = @NO;
    }
    
    return [recommendations copy];
}

- (void)applyRecommendedOptimizations {
    NSDictionary *recommendations = [self getOptimizationRecommendations];
    
    NSNumber *suggestedMemoryLimit = recommendations[@"suggestedMemoryCacheLimit"];
    if (suggestedMemoryLimit) {
        self.memoryCacheLimit = suggestedMemoryLimit.unsignedIntegerValue;
        self.globalCache.totalCostLimit = self.memoryCacheLimit;
    }
    
    NSNumber *suggestedAnimation = recommendations[@"suggestedAnimationEnabled"];
    if (suggestedAnimation) {
        self.animationOptimizationEnabled = suggestedAnimation.boolValue;
    }
}

#pragma mark - 内存警告处理

- (void)handleMemoryWarning {
    // 清理一半的缓存
    self.globalCache.totalCostLimit = self.globalCache.totalCostLimit / 2;
    [self.globalCache removeAllObjects];
    
    // 恢复原始限制
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.globalCache.totalCostLimit = self.memoryCacheLimit;
    });
}

#pragma mark - 私有方法

- (NSUInteger)getTotalMemory {
    size_t size = sizeof(int);
    int results;
    sysctlbyname("hw.memsize", &results, &size, NULL, 0);
    return (NSUInteger)results;
}

- (NSString *)getDeviceModel {
    size_t size = 0;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *model = [NSString stringWithUTF8String:machine];
    free(machine);
    return model;
}

- (NSNumber *)calculateCacheHitRate {
    // 简化的缓存命中率计算
    // 实际项目中需要根据具体的缓存使用情况来实现
    return @(0.85); // 示例值
}

@end 