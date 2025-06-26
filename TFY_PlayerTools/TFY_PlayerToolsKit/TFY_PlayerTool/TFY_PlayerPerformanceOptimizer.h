//
//  TFY_PlayerPerformanceOptimizer.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 性能优化管理器
@interface TFY_PlayerPerformanceOptimizer : NSObject

/// 单例实例
+ (instancetype)sharedOptimizer;

/// 启用/禁用动画优化
@property (nonatomic, assign) BOOL animationOptimizationEnabled;

/// 启用/禁用图片缓存优化
@property (nonatomic, assign) BOOL imageCacheOptimizationEnabled;

/// 启用/禁用滚动性能优化
@property (nonatomic, assign) BOOL scrollPerformanceOptimizationEnabled;

/// 内存缓存大小限制（字节）
@property (nonatomic, assign) NSUInteger memoryCacheLimit;

/// 磁盘缓存大小限制（字节）
@property (nonatomic, assign) NSUInteger diskCacheLimit;

/// 全局缓存对象（供其他组件使用）
@property (nonatomic, strong, readonly) NSCache *globalCache;

#pragma mark - 缓存管理

/// 清理所有缓存
- (void)clearAllCaches;

/// 清理内存缓存
- (void)clearMemoryCache;

/// 获取当前内存使用情况
- (NSUInteger)currentMemoryUsage;

#pragma mark - 性能监控

/// 开始性能监控
- (void)startPerformanceMonitoring;

/// 停止性能监控
- (void)stopPerformanceMonitoring;

/// 获取性能统计信息
- (NSDictionary *)getPerformanceStats;

#pragma mark - 优化建议

/// 获取基于当前设备的优化建议
- (NSDictionary *)getOptimizationRecommendations;

/// 应用推荐的优化设置
- (void)applyRecommendedOptimizations;

@end

NS_ASSUME_NONNULL_END 