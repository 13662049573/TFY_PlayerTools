//
//  TFY_PlayerPictureInPictureManager.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2024/01/01.
//  Copyright © 2024 田风有. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TFY_PlayerController;
@class TFY_PlayerPictureInPictureManager;

// 画中画相关时间控制常量
extern const NSTimeInterval kPipDelay;            // 画中画延迟时间
extern const NSTimeInterval kPipCheckDelay;       // 画中画检查延迟
extern const NSTimeInterval kPipRetryDelay;       // 画中画重试延迟
extern const NSTimeInterval kPipRestartDelay;     // 画中画重启延迟
extern const NSTimeInterval kObserverTimeout;     // 观察者超时时间

// 重试配置常量
extern const NSInteger kMaxPipRetryCount;         // 最大画中画重试次数
extern const NSInteger kMaxGeneralRetryCount;     // 最大通用重试次数

// UI相关常量
extern const CGFloat kDefaultPlayerDisapperaPercent;   // 默认播放器消失百分比
extern const CGFloat kDefaultPlayerApperaPercent;      // 默认播放器出现百分比
extern const CGFloat kSmallFloatViewWidth;             // 小浮窗宽度
extern const CGFloat kSmallFloatViewHeight;            // 小浮窗高度

// Volume Slider Class Name
extern NSString *const kVolumeSliderClassName;

// KVO上下文常量
extern void * const kPipItemContextVar;
extern void * const kPlayerItemContextVar;
extern void * const kPlayerContextVar;

// KVO上下文宏定义，便于外部统一使用
#define TFYPlayerPipItemContext   kPipItemContextVar
#define TFYPlayerItemContext      kPlayerItemContextVar
#define TFYPlayerContext          kPlayerContextVar

// 值范围限制函数
static inline CGFloat TFYPlayerClampValue(CGFloat value, CGFloat min, CGFloat max) {
    return value < min ? min : (value > max ? max : value);
}

/// 画中画状态枚举
typedef NS_ENUM(NSInteger, TFYPipState) {
    TFYPipStateInactive = 0,    // 未激活
    TFYPipStateStarting,        // 正在启动
    TFYPipStateActive,          // 已激活
    TFYPipStateStopping,        // 正在停止
    TFYPipStateFailed           // 启动失败
};

/// 画中画错误代码
typedef NS_ENUM(NSInteger, TFYPipErrorCode) {
    TFYPipErrorCodeUnsupported = 1000,      // 不支持画中画
    TFYPipErrorCodeNotEnabled,              // 画中画未启用
    TFYPipErrorCodePlayerNotReady,          // 播放器未准备好
    TFYPipErrorCodeLayerNotFound,           // AVPlayerLayer未找到
    TFYPipErrorCodeWindowNotAttached,       // 未关联到window
    TFYPipErrorCodeAlreadyActive,           // 已经在活动状态
    TFYPipErrorCodeSystemRestriction,       // 系统限制
    TFYPipErrorCodeContentUnsupported,      // 内容不支持
    TFYPipErrorCodeRetryLimitExceeded      // 重试次数超限
};

/// 画中画回调协议
@protocol TFYPictureInPictureManagerDelegate <NSObject>

@optional
/// 画中画即将开始
- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager willStartPictureInPicture:(AVPictureInPictureController *)pipController;

/// 画中画已经开始
- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager didStartPictureInPicture:(AVPictureInPictureController *)pipController;

/// 画中画即将停止
- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager willStopPictureInPicture:(AVPictureInPictureController *)pipController;

/// 画中画已经停止
- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager didStopPictureInPicture:(AVPictureInPictureController *)pipController;

/// 画中画启动失败
- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager failedToStartWithError:(NSError *)error;

/// 画中画需要恢复用户界面
- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager 
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL restored))completionHandler;

/// 画中画状态变化
- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager didChangeState:(TFYPipState)state;

/// 画中画连续播放需要下一个资源
- (NSURL * _Nullable)pictureInPictureManagerRequestNextAssetURL:(TFY_PlayerPictureInPictureManager *)manager;

/// 画中画连续播放完成
- (void)pictureInPictureManagerDidCompleteContinuousPlayback:(TFY_PlayerPictureInPictureManager *)manager;

@end

/// 画中画管理器
@interface TFY_PlayerPictureInPictureManager : NSObject

/// 代理
@property (nonatomic, weak) id<TFYPictureInPictureManagerDelegate> delegate;

/// 是否启用画中画
@property (nonatomic, assign) BOOL enablePictureInPicture;

/// 是否启用连续播放
@property (nonatomic, assign) BOOL enableContinuousPlayback;

/// 当前画中画状态
@property (nonatomic, assign, readonly) TFYPipState currentState;

/// 是否支持画中画
@property (nonatomic, assign, readonly) BOOL isPictureInPictureSupported;

/// 画中画是否处于活动状态
@property (nonatomic, assign, readonly) BOOL isPictureInPictureActive;

/// 画中画是否可以启动
@property (nonatomic, assign, readonly) BOOL isPictureInPicturePossible;

/// 最大重试次数
@property (nonatomic, assign) NSInteger maxRetryCount;

/// 重试间隔时间
@property (nonatomic, assign) NSTimeInterval retryInterval;

/// 防抖时间间隔
@property (nonatomic, assign) NSTimeInterval debounceInterval;

/// 初始化方法
- (instancetype)initWithPlayerController:(TFY_PlayerController *)playerController;

/// 启动画中画
/// @return 是否成功启动
- (BOOL)startPictureInPicture;

/// 停止画中画
- (void)stopPictureInPicture;

/// 重置画中画控制器
- (void)resetPictureInPictureController;

/// 检查画中画支持状态
- (BOOL)checkPictureInPictureSupport;

/// 获取详细的错误信息
- (NSString *)getDetailedErrorDescription;

/// 强制清理资源
- (void)cleanup;

/// 配置Audio Session以支持画中画
- (void)configureAudioSessionForPiP;

@end

NS_ASSUME_NONNULL_END 
