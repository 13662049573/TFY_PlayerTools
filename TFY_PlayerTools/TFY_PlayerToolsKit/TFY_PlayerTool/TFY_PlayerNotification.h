//
//  TFY_PlayerNotification.h
//  TFY_PlayerView
//
//  Created by 田风有 on 2019/6/30.
//  Copyright © 2019 田风有. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

/**
 * 播放器后台状态枚举
 * 
 * 用于标识应用当前的前后台状态
 */
typedef NS_ENUM(NSUInteger, PlayerBackgroundState) {
    PlayerBackgroundStateForeground,  // 应用处于前台状态
    PlayerBackgroundStateBackground,  // 应用处于后台状态
};

NS_ASSUME_NONNULL_BEGIN

/**
 * TFY_PlayerNotification - 播放器通知管理类
 * 
 * 功能说明：
 * 负责监听和管理播放器相关的系统通知，包括：
 * - 应用前后台切换
 * - 音频设备变化（耳机插拔、蓝牙连接等）
 * - 系统音量变化
 * - 音频中断事件（来电、闹钟等）
 * 
 * 使用方式：
 * 1. 创建实例并设置相应的回调
 * 2. 调用 addNotification 开始监听
 * 3. 在不需要时调用 removeNotification 停止监听
 */
@interface TFY_PlayerNotification : NSObject

#pragma mark - 属性

/// 当前应用的后台状态
@property (nonatomic, readonly) PlayerBackgroundState backgroundState;

#pragma mark - 应用状态回调

/**
 * 应用即将进入后台时的回调
 * 
 * 触发时机：
 * - 用户按下Home键
 * - 用户切换到其他应用
 * - 系统锁屏
 * 
 * 使用场景：
 * - 暂停播放
 * - 保存播放进度
 * - 启动画中画模式
 */
@property (nonatomic, copy, nullable) void(^willResignActive)(TFY_PlayerNotification *registrar);

/**
 * 应用即将进入前台时的回调
 * 
 * 触发时机：
 * - 用户从后台切换回应用
 * - 用户解锁屏幕
 * 
 * 使用场景：
 * - 恢复播放
 * - 更新UI状态
 * - 停止画中画模式
 */
@property (nonatomic, copy, nullable) void(^didBecomeActive)(TFY_PlayerNotification *registrar);

#pragma mark - 音频设备回调

/**
 * 新音频设备可用时的回调
 * 
 * 触发时机：
 * - 插入耳机
 * - 连接蓝牙耳机
 * - 连接AirPods
 * 
 * 使用场景：
 * - 调整音频输出设置
 * - 更新音量控制
 * - 显示设备连接提示
 */
@property (nonatomic, copy, nullable) void(^newDeviceAvailable)(TFY_PlayerNotification *registrar);

/**
 * 音频设备不可用时的回调
 * 
 * 触发时机：
 * - 拔出耳机
 * - 断开蓝牙耳机
 * - 断开AirPods
 * 
 * 使用场景：
 * - 切换到扬声器输出
 * - 更新音量控制
 * - 显示设备断开提示
 */
@property (nonatomic, copy, nullable) void(^oldDeviceUnavailable)(TFY_PlayerNotification *registrar);

/**
 * 音频类别变化时的回调
 * 
 * 触发时机：
 * - 音频会话类别发生变化
 * - 系统音频设置改变
 * 
 * 使用场景：
 * - 重新配置音频会话
 * - 更新播放设置
 */
@property (nonatomic, copy, nullable) void(^categoryChange)(TFY_PlayerNotification *registrar);
/**
 * 锁屏触发通知
 */
@property (nonatomic, copy, nullable) void(^protectedDataWill)(TFY_PlayerNotification *registrar);
#pragma mark - 音量控制回调

/**
 * 系统音量变化时的回调
 * 
 * @param volume 新的系统音量值（0.0 - 1.0）
 * 
 * 触发时机：
 * - 用户调节系统音量
 * - 通过音量按钮调节
 * 
 * 使用场景：
 * - 同步播放器音量UI
 * - 更新音量滑块位置
 * - 显示音量变化提示
 */
@property (nonatomic, copy, nullable) void(^volumeChanged)(float volume);

#pragma mark - 音频中断回调

/**
 * 音频中断事件回调
 * 
 * @param interruptionType 中断类型
 *   - AVAudioSessionInterruptionTypeBegan: 中断开始
 *   - AVAudioSessionInterruptionTypeEnded: 中断结束
 * 
 * 触发时机：
 * - 来电
 * - 闹钟响起
 * - Siri激活
 * - 其他应用抢占音频会话
 * 
 * 使用场景：
 * - 中断开始时暂停播放
 * - 中断结束时恢复播放
 * - 显示中断提示
 */
@property (nonatomic, copy, nullable) void(^audioInterruptionCallback)(AVAudioSessionInterruptionType interruptionType);

#pragma mark - 公共方法

/**
 * 添加所有系统通知监听
 * 
 * 开始监听以下通知：
 * - 音频路由变化
 * - 应用前后台切换
 * - 系统音量变化
 * - 音频中断事件
 * 
 * 注意：调用此方法后，相应的回调会在事件发生时被触发
 */
- (void)addNotification;

/**
 * 移除所有系统通知监听
 * 
 * 停止监听所有通知，避免内存泄漏
 * 
 * 注意：在对象销毁前必须调用此方法
 */
- (void)removeNotification;

@end

NS_ASSUME_NONNULL_END
