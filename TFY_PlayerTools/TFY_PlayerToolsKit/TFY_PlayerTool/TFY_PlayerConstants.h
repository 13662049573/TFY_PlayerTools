//
//  TFY_PlayerConstants.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#ifndef TFY_PlayerConstants_h
#define TFY_PlayerConstants_h

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const TFYPlayerLogPrefix;

// MARK: - Timing Constants (时间相关常量)
typedef struct {
    NSTimeInterval pipDelay;              // 画中画延迟时间
    NSTimeInterval pipCheckDelay;         // 画中画检查延迟
    NSTimeInterval pipRetryDelay;         // 画中画重试延迟
    NSTimeInterval pipRestartDelay;       // 画中画重启延迟
    NSTimeInterval observerTimeout;       // 观察者超时时间
} TFYPlayerTimingConstants;

FOUNDATION_EXPORT const TFYPlayerTimingConstants TFYPlayerTiming;

// MARK: - Retry Constants (重试相关常量)
typedef struct {
    NSInteger maxPipRetryCount;           // 画中画最大重试次数
    NSInteger maxObserverRetryCount;      // 观察者最大重试次数
} TFYPlayerRetryConstants;

FOUNDATION_EXPORT const TFYPlayerRetryConstants TFYPlayerRetry;

// MARK: - UI Constants (UI相关常量)
typedef struct {
    CGFloat defaultPlayerApperaPercent;   // 默认播放器出现百分比
    CGFloat defaultPlayerDisapperaPercent;// 默认播放器消失百分比
    NSTimeInterval defaultAutoHiddenTimeInterval; // 默认自动隐藏时间间隔
    NSTimeInterval defaultAutoFadeTimeInterval;   // 默认自动淡出时间间隔
} TFYPlayerUIConstants;

FOUNDATION_EXPORT const TFYPlayerUIConstants TFYPlayerUI;

// MARK: - Volume Slider Class Name (音量滑块类名)
FOUNDATION_EXPORT NSString *const TFYPlayerVolumeSliderClassName;

// MARK: - KVO Context (KVO上下文)
FOUNDATION_EXPORT void *const TFYPlayerPipItemContext;

// MARK: - Logging Macros (日志宏定义)
#ifdef DEBUG
    #define TFYPlayerLog(format, ...) NSLog(@"%@ " format, TFYPlayerLogPrefix, ##__VA_ARGS__)
#else
    #define TFYPlayerLog(format, ...)
#endif

#define TFYPlayerLogInfo(format, ...) TFYPlayerLog(@"[INFO] " format, ##__VA_ARGS__)
#define TFYPlayerLogWarning(format, ...) TFYPlayerLog(@"[WARNING] " format, ##__VA_ARGS__)
#define TFYPlayerLogError(format, ...) TFYPlayerLog(@"[ERROR] " format, ##__VA_ARGS__)

// MARK: - Helper Macros (辅助宏定义)
#define TFYPlayerClampValue(value, min, max) MIN(MAX((value), (min)), (max))
#define TFYPlayerIsValidFloat(value) (!isnan(value))

#endif /* TFY_PlayerConstants_h */ 