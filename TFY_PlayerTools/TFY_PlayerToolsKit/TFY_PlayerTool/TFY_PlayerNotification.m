//
//  TFY_PlayerNotification.m
//  TFY_PlayerView
//
//  Created by 田风有 on 2019/6/30.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "TFY_PlayerNotification.h"

/**
 * TFY_PlayerNotification - 播放器通知管理类实现
 * 
 * 功能说明：
 * 1. 管理播放器相关的系统通知监听
 * 2. 处理音频会话路由变化（如耳机插拔）
 * 3. 处理应用前后台切换
 * 4. 处理系统音量变化
 * 5. 处理音频中断事件
 * 
 * 使用场景：
 * - 播放器需要响应系统音频变化
 * - 应用进入后台时需要暂停播放
 * - 耳机插拔时需要调整音频输出
 * - 系统音量变化时需要同步UI
 */
@interface TFY_PlayerNotification ()
/// 应用后台状态 - 用于跟踪应用当前是否在后台运行
@property (nonatomic, assign) PlayerBackgroundState backgroundState;
@end

@implementation TFY_PlayerNotification

#pragma mark - 通知管理

/**
 * 添加所有系统通知监听
 * 
 * 监听的通知类型：
 * 1. AVAudioSessionRouteChangeNotification - 音频路由变化（耳机插拔等）
 * 2. UIApplicationWillResignActiveNotification - 应用即将进入后台
 * 3. UIApplicationDidBecomeActiveNotification - 应用即将进入前台
 * 4. AVSystemController_SystemVolumeDidChangeNotification - 系统音量变化
 * 5. AVAudioSessionInterruptionNotification - 音频中断（来电、闹钟等）
 */
- (void)addNotification {
    // 监听音频路由变化（耳机插拔、蓝牙设备连接等）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionRouteChangeNotification:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    
    // 监听应用即将进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActiveNotification)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    // 监听应用即将进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActiveNotification)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    // 监听系统音量变化
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(volumeDidChangeNotification:)
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                               object:nil];
    
    // 监听音频中断事件（来电、闹钟、Siri等）
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionInterruptionNotification:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
}

/**
 * 移除所有系统通知监听
 * 
 * 在对象销毁前调用，避免内存泄漏
 * 移除所有已注册的通知监听器
 */
- (void)removeNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
}

/**
 * 对象销毁时自动移除通知监听
 * 
 * 确保在对象销毁时清理所有通知监听，防止内存泄漏
 */
- (void)dealloc {
    [self removeNotification];
}

#pragma mark - 通知响应方法

/**
 * 音频路由变化通知响应
 * 
 * @param notification 音频路由变化通知对象
 * 
 * 处理场景：
 * 1. 新设备可用（插入耳机、连接蓝牙设备）
 * 2. 旧设备不可用（拔出耳机、断开蓝牙设备）
 * 3. 音频类别变化
 * 
 * 在主线程中处理UI更新，确保线程安全
 */
- (void)audioSessionRouteChangeNotification:(NSNotification*)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *interuptionDict = notification.userInfo;
        NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
        
        switch (routeChangeReason) {
            case AVAudioSessionRouteChangeReasonNewDeviceAvailable: {
                // 新设备可用（如插入耳机、连接蓝牙设备）
                if (self.newDeviceAvailable) self.newDeviceAvailable(self);
            }
                break;
                
            case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
                // 旧设备不可用（如拔出耳机、断开蓝牙设备）
                if (self.oldDeviceUnavailable) self.oldDeviceUnavailable(self);
            }
                break;
                
            case AVAudioSessionRouteChangeReasonCategoryChange: {
                // 音频类别变化
                if (self.categoryChange) self.categoryChange(self);
            }
                break;
        }
    });
}

/**
 * 系统音量变化通知响应
 * 
 * @param notification 音量变化通知对象
 * 
 * 功能：
 * - 获取新的系统音量值
 * - 通过回调通知播放器更新音量UI
 * 
 * 音量值范围：0.0 - 1.0
 */
- (void)volumeDidChangeNotification:(NSNotification *)notification {
    // 从通知中获取新的音量值
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    
    // 通过回调通知播放器音量变化
    if (self.volumeChanged) {
        self.volumeChanged(volume);
    }
}

/**
 * 应用即将进入后台通知响应
 * 
 * 功能：
 * - 更新后台状态标记
 * - 通知播放器应用即将进入后台
 * 
 * 使用场景：
 * - 播放器需要暂停播放
 * - 保存播放进度
 * - 启动画中画模式
 */
- (void)applicationWillResignActiveNotification {
    // 标记应用进入后台状态
    self.backgroundState = PlayerBackgroundStateBackground;
    
    // 通知播放器应用即将进入后台
    if (self.willResignActive) {
        self.willResignActive(self);
    }
}

/**
 * 应用即将进入前台通知响应
 * 
 * 功能：
 * - 更新前台状态标记
 * - 通知播放器应用即将进入前台
 * 
 * 使用场景：
 * - 恢复播放
 * - 更新UI状态
 * - 停止画中画模式
 */
- (void)applicationDidBecomeActiveNotification {
    // 标记应用进入前台状态
    self.backgroundState = PlayerBackgroundStateForeground;
    
    // 通知播放器应用即将进入前台
    if (self.didBecomeActive) {
        self.didBecomeActive(self);
    }
}

/**
 * 音频中断通知响应
 * 
 * @param notification 音频中断通知对象
 * 
 * 处理场景：
 * 1. 来电中断
 * 2. 闹钟中断
 * 3. Siri激活
 * 4. 其他应用抢占音频会话
 * 
 * 中断类型：
 * - AVAudioSessionInterruptionTypeBegan: 中断开始
 * - AVAudioSessionInterruptionTypeEnded: 中断结束
 * 
 * 通过回调通知播放器处理音频中断事件
 */
- (void)audioSessionInterruptionNotification:(NSNotification *)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    AVAudioSessionInterruptionType interruptionType = [[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    
    // 通过回调通知播放器音频中断事件
    if (self.audioInterruptionCallback) {
        self.audioInterruptionCallback(interruptionType);
    }
}

@end
