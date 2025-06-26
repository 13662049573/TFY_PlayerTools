//
//  TFY_PlayerPictureInPictureManager.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2024/01/01.
//  Copyright © 2024 田风有. All rights reserved.
//

#import "TFY_PlayerPictureInPictureManager.h"
#import "TFY_PlayerController.h"
#import <objc/runtime.h>

// 错误域
NSString *const TFYPipErrorDomain = @"com.tfy.player.pip";

// 画中画相关时间控制常量
const NSTimeInterval kPipDelay = 0.5;
const NSTimeInterval kPipCheckDelay = 1.0;
const NSTimeInterval kPipRetryDelay = 2.0;
const NSTimeInterval kPipRestartDelay = 0.3;
const NSTimeInterval kObserverTimeout = 10.0;

// 重试配置常量
const NSInteger kMaxPipRetryCount = 3;
const NSInteger kMaxGeneralRetryCount = 5;

// UI相关常量
const CGFloat kDefaultPlayerDisapperaPercent = 0.5;
const CGFloat kDefaultPlayerApperaPercent = 0.0;
const CGFloat kSmallFloatViewWidth = 150.0;
const CGFloat kSmallFloatViewHeight = 84.0;

// Volume Slider Class Name
NSString *const kVolumeSliderClassName = @"MPVolumeSlider";

// KVO上下文常量
void * const kPipItemContextVar = (void *)&kPipItemContextVar;
void * const kPlayerItemContextVar = (void *)&kPlayerItemContextVar;
void * const kPlayerContextVar = (void *)&kPlayerContextVar;

// 私有属性键
static NSString *const kPipControllerKey = @"pipController";
static NSString *const kRetryCountKey = @"retryCount";
static NSString *const kLastStartTimeKey = @"lastStartTime";
static NSString *const kIsProcessingKey = @"isProcessing";
static NSString *const kLastErrorKey = @"lastError";

@interface TFY_PlayerPictureInPictureManager () <AVPictureInPictureControllerDelegate>

/// 播放器控制器弱引用
@property (nonatomic, weak) TFY_PlayerController *playerController;

/// 画中画控制器
@property (nonatomic, strong) AVPictureInPictureController *pipController;

/// 当前状态
@property (nonatomic, assign) TFYPipState currentState;

/// 当前重试次数
@property (nonatomic, assign) NSInteger currentRetryCount;

/// 上次启动时间
@property (nonatomic, assign) NSTimeInterval lastStartTime;

/// 是否正在处理
@property (nonatomic, assign) BOOL isProcessing;

/// 最后的错误
@property (nonatomic, strong) NSError *lastError;

/// 是否在连续播放模式
@property (nonatomic, assign) BOOL isContinuousPlaybackMode;

/// 播放结束观察者
@property (nonatomic, strong) id playbackEndObserver;

@end

@implementation TFY_PlayerPictureInPictureManager

#pragma mark - Lifecycle

- (instancetype)initWithPlayerController:(TFY_PlayerController *)playerController {
    self = [super init];
    if (self) {
        _playerController = playerController;
        _currentState = TFYPipStateInactive;
        _enablePictureInPicture = YES;
        _enableContinuousPlayback = NO;
        _maxRetryCount = 3;
        _retryInterval = 1.0;
        _debounceInterval = 2.0;
        _currentRetryCount = 0;
        _isProcessing = NO;
        _isContinuousPlaybackMode = NO;
        
        [self setupNotifications];
    }
    return self;
}

- (void)dealloc {
    [self cleanup];
}

#pragma mark - Public Methods

- (BOOL)startPictureInPicture {
    if (@available(iOS 15.0, *)) {
        NSLog(@"TFY_PipManager: 开始启动画中画流程");
        
        // 检查是否正在处理
        if (self.isProcessing) {
            NSLog(@"TFY_PipManager: 正在处理中，避免重复调用");
            return NO;
        }
        
        // 检查重试次数
        if (self.currentRetryCount >= self.maxRetryCount) {
            NSLog(@"TFY_PipManager: 重试次数超限(%ld)，停止尝试", (long)self.currentRetryCount);
            [self createErrorWithCode:TFYPipErrorCodeRetryLimitExceeded description:@"重试次数超过限制"];
            [self setState:TFYPipStateFailed];
            return NO;
        }
        
        // 防抖检查
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        if (currentTime - self.lastStartTime < self.debounceInterval) {
            NSLog(@"TFY_PipManager: 启动过于频繁，忽略调用");
            return NO;
        }
        
        // 设置处理状态
        self.isProcessing = YES;
        self.lastStartTime = currentTime;
        [self setState:TFYPipStateStarting];
        
        // 执行启动检查
        NSError *error = nil;
        BOOL canStart = [self performStartupChecks:&error];
        
        if (!canStart) {
            self.isProcessing = NO;
            self.lastError = error;
            
            // 检查是否需要重试
            if ([self shouldRetryForError:error]) {
                self.currentRetryCount++;
                NSLog(@"TFY_PipManager: 第%ld次重试 (错误: %@)", (long)self.currentRetryCount, error.localizedDescription);
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self startPictureInPicture];
                });
                return NO;
            } else {
                [self setState:TFYPipStateFailed];
                [self notifyDelegateFailedWithError:error];
                return NO;
            }
        }
        
        // 启动画中画
        [self.pipController startPictureInPicture];
        
        // 重置状态
        self.isProcessing = NO;
        self.currentRetryCount = 0;
        self.lastError = nil;
        
        return YES;
    }
    
    [self createErrorWithCode:TFYPipErrorCodeUnsupported description:@"系统版本不支持画中画"];
    [self setState:TFYPipStateFailed];
    return NO;
}

- (void)stopPictureInPicture {
    if (@available(iOS 15.0, *)) {
        if (self.pipController && self.pipController.isPictureInPictureActive) {
            [self setState:TFYPipStateStopping];
            [self.pipController stopPictureInPicture];
            
            // 清理连续播放状态
            [self cleanupContinuousPlayback];
        }
    }
}

- (void)resetPictureInPictureController {
    [self cleanup];
    self.pipController = nil;
    [self setState:TFYPipStateInactive];
    NSLog(@"TFY_PipManager: 画中画控制器已重置");
}

- (BOOL)checkPictureInPictureSupport {
    if (@available(iOS 15.0, *)) {
        return [AVPictureInPictureController isPictureInPictureSupported];
    }
    return NO;
}

- (NSString *)getDetailedErrorDescription {
    if (self.lastError) {
        return [NSString stringWithFormat:@"错误代码: %ld, 描述: %@", 
                self.lastError.code, self.lastError.localizedDescription];
    }
    return @"无错误信息";
}

- (void)cleanup {
    // 移除通知观察者
    if (self.playbackEndObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.playbackEndObserver];
        self.playbackEndObserver = nil;
    }
    
    // 清理画中画控制器
    if (self.pipController) {
        @try {
            [self.pipController removeObserver:self forKeyPath:@"pictureInPicturePossible"];
        } @catch (NSException *exception) {
            NSLog(@"TFY_PipManager: 移除KVO观察者时出错: %@", exception.reason);
        }
        
        self.pipController.delegate = nil;
        self.pipController = nil;
    }
    
    // 重置状态
    self.isProcessing = NO;
    self.currentRetryCount = 0;
    self.isContinuousPlaybackMode = NO;
    [self setState:TFYPipStateInactive];
    
    NSLog(@"TFY_PipManager: 资源清理完成");
}

#pragma mark - Private Methods

- (BOOL)performStartupChecks:(NSError **)error {
    NSLog(@"[PIP] 启动前检查: enablePictureInPicture=%@, 支持PIP=%@", self.enablePictureInPicture ? @"YES" : @"NO", [self checkPictureInPictureSupport] ? @"YES" : @"NO");
    if (!self.enablePictureInPicture) {
        NSLog(@"[PIP] 画中画功能未启用");
        *error = [self createErrorWithCode:TFYPipErrorCodeNotEnabled description:@"画中画功能未启用"];
        return NO;
    }
    if (![self checkPictureInPictureSupport]) {
        NSLog(@"[PIP] 设备不支持画中画");
        *error = [self createErrorWithCode:TFYPipErrorCodeUnsupported description:@"设备不支持画中画"];
        return NO;
    }
    if (!self.playerController || !self.playerController.currentPlayerManager) {
        NSLog(@"[PIP] 播放器控制器为空");
        *error = [self createErrorWithCode:TFYPipErrorCodePlayerNotReady description:@"播放器控制器为空"];
        return NO;
    }
    if (!self.playerController.currentPlayerManager.isPreparedToPlay) {
        NSLog(@"[PIP] 播放器未准备好");
        *error = [self createErrorWithCode:TFYPipErrorCodePlayerNotReady description:@"播放器未准备好"];
        return NO;
    }
    AVPlayer *player = [self getAVPlayer];
    AVPlayerLayer *playerLayer = [self getAVPlayerLayer];
    NSLog(@"[PIP] AVPlayer=%@, AVPlayerLayer=%@", player, playerLayer);
    if (!player) {
        NSLog(@"[PIP] AVPlayer为空");
        *error = [self createErrorWithCode:TFYPipErrorCodePlayerNotReady description:@"AVPlayer为空"];
        return NO;
    }
    if (!player.currentItem) {
        NSLog(@"[PIP] AVPlayerItem为空");
        *error = [self createErrorWithCode:TFYPipErrorCodePlayerNotReady description:@"AVPlayerItem为空"];
        return NO;
    }
    if (player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
        NSLog(@"[PIP] AVPlayerItem未准备好, status=%ld", (long)player.currentItem.status);
        *error = [self createErrorWithCode:TFYPipErrorCodePlayerNotReady description:@"AVPlayerItem未准备好"];
        return NO;
    }
    if (!playerLayer) {
        NSLog(@"[PIP] AVPlayerLayer为空");
        *error = [self createErrorWithCode:TFYPipErrorCodeLayerNotFound description:@"AVPlayerLayer为空"];
        return NO;
    }
    NSArray *videoTracks = [player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo];
    NSLog(@"[PIP] 视频轨道数: %lu", (unsigned long)videoTracks.count);
    if (videoTracks.count == 0) {
        NSLog(@"[PIP] 没有视频轨道");
        *error = [self createErrorWithCode:TFYPipErrorCodeContentUnsupported description:@"没有视频轨道"];
        return NO;
    }
    NSLog(@"[PIP] PlayerLayer.bounds=%@, superlayer=%@", NSStringFromCGRect(playerLayer.bounds), playerLayer.superlayer);
    if (CGRectIsEmpty(playerLayer.bounds) || CGRectEqualToRect(playerLayer.bounds, CGRectZero)) {
        NSLog(@"[PIP] AVPlayerLayer bounds无效");
        *error = [self createErrorWithCode:TFYPipErrorCodeLayerNotFound description:@"AVPlayerLayer bounds无效"];
        return NO;
    }
    if (!playerLayer.superlayer) {
        NSLog(@"[PIP] AVPlayerLayer未添加到视图层级");
        *error = [self createErrorWithCode:TFYPipErrorCodeLayerNotFound description:@"AVPlayerLayer未添加到视图层级"];
        return NO;
    }
    UIView *hostView = [self findHostViewForLayer:playerLayer];
    NSLog(@"[PIP] hostView=%@, window=%@", hostView, hostView ? hostView.window : nil);
    if (!hostView || !hostView.window) {
        NSLog(@"[PIP] AVPlayerLayer未关联到window");
        *error = [self createErrorWithCode:TFYPipErrorCodeWindowNotAttached description:@"AVPlayerLayer未关联到window"];
        return NO;
    }
    if (playerLayer.player != player) {
        NSLog(@"[PIP] 修复PlayerLayer的player引用");
        playerLayer.player = player;
    }
    if (![self ensurePipController:error]) {
        NSLog(@"[PIP] ensurePipController失败: %@", *error ? (*error).localizedDescription : @"未知错误");
        return NO;
    }
    if (self.pipController.isPictureInPictureActive) {
        NSLog(@"[PIP] 画中画已在活动状态");
        *error = [self createErrorWithCode:TFYPipErrorCodeAlreadyActive description:@"画中画已在活动状态"];
        return NO;
    }
    NSLog(@"[PIP] isPictureInPicturePossible=%@", self.pipController.isPictureInPicturePossible ? @"YES" : @"NO");
    if (!self.pipController.isPictureInPicturePossible) {
        NSLog(@"[PIP] 当前无法启动画中画，尝试等待和重试");
        
        // 如果这是第一次检查，等待一段时间再重试
        if (self.currentRetryCount == 0) {
            self.currentRetryCount++;
            NSLog(@"[PIP] 等待1秒后重试画中画启动");
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"[PIP] 重新检查isPictureInPicturePossible: %@", self.pipController.isPictureInPicturePossible ? @"YES" : @"NO");
                if (self.pipController.isPictureInPicturePossible) {
                    NSLog(@"[PIP] 等待后画中画变为可用，重新启动");
                    [self.pipController startPictureInPicture];
                } else {
                    NSLog(@"[PIP] 等待后画中画仍不可用");
                    [self performDiagnostics];
                }
            });
            
            return YES; // 返回YES，因为我们会在延迟后重试
        } else {
            NSLog(@"[PIP] 重试后仍无法启动画中画");
            [self performDiagnostics];
            *error = [self createErrorWithCode:TFYPipErrorCodeSystemRestriction description:@"系统限制，无法启动画中画"];
            return NO;
        }
    }
    NSLog(@"[PIP] 启动前检查全部通过");
    return YES;
}

- (BOOL)ensurePipController:(NSError **)error {
    if (!self.pipController) {
        AVPlayerLayer *playerLayer = [self getAVPlayerLayer];
        if (!playerLayer) {
            *error = [self createErrorWithCode:TFYPipErrorCodeLayerNotFound description:@"无法获取AVPlayerLayer创建PiP控制器"];
            return NO;
        }
        
        // 确保Audio Session配置正确
        [self configureAudioSessionForPiP];
        
        @try {
            self.pipController = [[AVPictureInPictureController alloc] initWithPlayerLayer:playerLayer];
            self.pipController.delegate = self;
            NSLog(@"TFY_PipManager: 成功创建画中画控制器");
            
            // 添加isPictureInPicturePossible的KVO监听
            [self.pipController addObserver:self 
                                 forKeyPath:@"pictureInPicturePossible" 
                                    options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial 
                                    context:nil];
            
            // 立即检查一次状态，有时需要触发内部更新
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"TFY_PipManager: 创建后立即检查 isPictureInPicturePossible: %@", 
                      self.pipController.isPictureInPicturePossible ? @"YES" : @"NO");
            });
        } @catch (NSException *exception) {
            *error = [self createErrorWithCode:TFYPipErrorCodeUnsupported 
                                   description:[NSString stringWithFormat:@"创建PiP控制器异常: %@", exception.reason]];
            return NO;
        }
    }
    
    return self.pipController != nil;
}

- (BOOL)shouldRetryForError:(NSError *)error {
    // 某些错误可以重试
    switch (error.code) {
        case TFYPipErrorCodePlayerNotReady:
        case TFYPipErrorCodeLayerNotFound:
        case TFYPipErrorCodeWindowNotAttached:
            return YES;
        default:
            return NO;
    }
}

- (AVPlayer *)getAVPlayer {
    if ([self.playerController.currentPlayerManager respondsToSelector:@selector(player)]) {
        return [self.playerController.currentPlayerManager performSelector:@selector(player)];
    }
    return nil;
}

- (AVPlayerLayer *)getAVPlayerLayer {
    if ([self.playerController.currentPlayerManager respondsToSelector:NSSelectorFromString(@"avPlayerLayer")]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return (AVPlayerLayer *)[self.playerController.currentPlayerManager performSelector:NSSelectorFromString(@"avPlayerLayer")];
        #pragma clang diagnostic pop
    }
    return nil;
}

- (UIView *)findHostViewForLayer:(CALayer *)layer {
    CALayer *currentLayer = layer.superlayer;
    while (currentLayer) {
        if ([currentLayer.delegate isKindOfClass:[UIView class]]) {
            return (UIView *)currentLayer.delegate;
        }
        currentLayer = currentLayer.superlayer;
    }
    return nil;
}

- (NSError *)createErrorWithCode:(TFYPipErrorCode)code description:(NSString *)description {
    return [NSError errorWithDomain:TFYPipErrorDomain 
                               code:code 
                           userInfo:@{NSLocalizedDescriptionKey: description}];
}

- (void)setState:(TFYPipState)state {
    if (_currentState != state) {
        _currentState = state;
        NSLog(@"TFY_PipManager: 状态变更为 %ld", (long)state);
        
        if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:didChangeState:)]) {
            [self.delegate pictureInPictureManager:self didChangeState:state];
        }
    }
}

#pragma mark - Continuous Playback

- (void)setupNotifications {
    // 监听播放结束通知
    __weak typeof(self) weakSelf = self;
    self.playbackEndObserver = [[NSNotificationCenter defaultCenter] 
        addObserverForName:AVPlayerItemDidPlayToEndTimeNotification 
                    object:nil 
                     queue:[NSOperationQueue mainQueue] 
                usingBlock:^(NSNotification *note) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf handlePlaybackEnd:note];
                }];
}

- (void)handlePlaybackEnd:(NSNotification *)notification {
    if (self.isPictureInPictureActive && self.enableContinuousPlayback) {
        NSLog(@"TFY_PipManager: 画中画模式下播放结束，尝试连续播放");
        
        if ([self.delegate respondsToSelector:@selector(pictureInPictureManagerRequestNextAssetURL:)]) {
            NSURL *nextURL = [self.delegate pictureInPictureManagerRequestNextAssetURL:self];
            
            if (nextURL) {
                [self startContinuousPlaybackWithURL:nextURL];
            } else {
                NSLog(@"TFY_PipManager: 没有下一个资源，结束连续播放");
                [self completeContinuousPlayback];
            }
        }
    }
}

- (void)startContinuousPlaybackWithURL:(NSURL *)url {
    self.isContinuousPlaybackMode = YES;
    NSLog(@"TFY_PipManager: 开始连续播放，切换到: %@", url.absoluteString);
    
    AVPlayer *player = [self getAVPlayer];
    if (player) {
        // 创建新的PlayerItem
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        AVPlayerItem *newItem = [AVPlayerItem playerItemWithAsset:asset];
        
        // 替换当前item
        [player replaceCurrentItemWithPlayerItem:newItem];
        
        // 等待准备完成后开始播放
        [self observeNewPlayerItem:newItem];
    }
}

- (void)observeNewPlayerItem:(AVPlayerItem *)item {
    [item addObserver:self 
           forKeyPath:@"status" 
              options:NSKeyValueObservingOptionNew 
              context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"] && [object isKindOfClass:[AVPlayerItem class]]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        
        if (item.status == AVPlayerItemStatusReadyToPlay) {
            // 移除观察者
            [item removeObserver:self forKeyPath:@"status"];
            
            // 开始播放
            AVPlayer *player = [self getAVPlayer];
            if (player) {
                [player play];
                NSLog(@"TFY_PipManager: 连续播放新视频开始");
            }
        } else if (item.status == AVPlayerItemStatusFailed) {
            [item removeObserver:self forKeyPath:@"status"];
            NSLog(@"TFY_PipManager: 连续播放新视频失败: %@", item.error.localizedDescription);
            [self completeContinuousPlayback];
        }
    } else if ([keyPath isEqualToString:@"pictureInPicturePossible"] && object == self.pipController) {
        BOOL isPossible = [change[NSKeyValueChangeNewKey] boolValue];
        NSLog(@"TFY_PipManager: isPictureInPicturePossible 变更为: %@", isPossible ? @"YES" : @"NO");
        
        if (isPossible) {
            NSLog(@"TFY_PipManager: 画中画现在可用！");
            // 通知代理画中画状态可用
            if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:didChangeState:)]) {
                [self.delegate pictureInPictureManager:self didChangeState:TFYPipStateInactive];
            }
        } else {
            NSLog(@"TFY_PipManager: 画中画当前不可用，可能的原因:");
            NSLog(@"1. 正在使用FaceTime或其他应用");
            NSLog(@"2. 设备不支持画中画");
            NSLog(@"3. Audio Session配置不正确");
            NSLog(@"4. AVPlayerLayer配置问题");
            
            // 尝试重新配置Audio Session
            [self configureAudioSessionForPiP];
        }
    }
}

- (void)completeContinuousPlayback {
    self.isContinuousPlaybackMode = NO;
    
    if ([self.delegate respondsToSelector:@selector(pictureInPictureManagerDidCompleteContinuousPlayback:)]) {
        [self.delegate pictureInPictureManagerDidCompleteContinuousPlayback:self];
    }
    
    NSLog(@"TFY_PipManager: 连续播放完成");
}

- (void)cleanupContinuousPlayback {
    self.isContinuousPlaybackMode = NO;
}

- (void)configureAudioSessionForPiP {
    NSLog(@"TFY_PipManager: 配置Audio Session以支持画中画");
    
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // 配置支持画中画的Audio Session选项
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionAllowBluetooth | 
                                           AVAudioSessionCategoryOptionAllowBluetoothA2DP |
                                           AVAudioSessionCategoryOptionAllowAirPlay |
                                           AVAudioSessionCategoryOptionMixWithOthers;
    
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback 
                                 withOptions:options 
                                       error:&error];
    
    if (!success) {
        NSLog(@"TFY_PipManager: Audio Session category配置失败: %@", error.localizedDescription);
        return;
    }
    
    success = [audioSession setActive:YES error:&error];
    if (!success) {
        NSLog(@"TFY_PipManager: Audio Session激活失败: %@", error.localizedDescription);
        return;
    }
    
    NSLog(@"TFY_PipManager: Audio Session配置成功");
    NSLog(@"- Category: %@", audioSession.category);
    NSLog(@"- Mode: %@", audioSession.mode);
    NSLog(@"- Options: %lu", (unsigned long)audioSession.categoryOptions);
    NSLog(@"- Available inputs: %lu", (unsigned long)audioSession.availableInputs.count);
}

- (void)performDiagnostics {
    NSLog(@"=== TFY_PipManager 画中画诊断 ===");
    
    // 1. 基础支持检查
    NSLog(@"1. 基础支持:");
    NSLog(@"   - iOS版本: %@", [[UIDevice currentDevice] systemVersion]);
    NSLog(@"   - 设备型号: %@", [[UIDevice currentDevice] model]);
    NSLog(@"   - 画中画支持: %@", [AVPictureInPictureController isPictureInPictureSupported] ? @"YES" : @"NO");
    
    // 2. Audio Session检查
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSLog(@"2. Audio Session:");
    NSLog(@"   - Category: %@", audioSession.category);
    NSLog(@"   - Mode: %@", audioSession.mode);
    NSLog(@"   - Options: %lu", (unsigned long)audioSession.categoryOptions);
    NSLog(@"   - Active: %@", audioSession.isOtherAudioPlaying ? @"YES" : @"NO");
    
    // 3. 播放器状态检查
    AVPlayer *player = [self getAVPlayer];
    AVPlayerLayer *playerLayer = [self getAVPlayerLayer];
    NSLog(@"3. 播放器状态:");
    NSLog(@"   - AVPlayer: %@", player ? @"存在" : @"不存在");
    NSLog(@"   - AVPlayerLayer: %@", playerLayer ? @"存在" : @"不存在");
    if (player && player.currentItem) {
        NSLog(@"   - PlayerItem状态: %ld", (long)player.currentItem.status);
        NSLog(@"   - PlayerItem错误: %@", player.currentItem.error ? player.currentItem.error.localizedDescription : @"无");
        NSLog(@"   - 播放速率: %.2f", player.rate);
    }
    
    // 4. 视图层级检查
    if (playerLayer) {
        NSLog(@"4. 视图层级:");
        NSLog(@"   - PlayerLayer bounds: %@", NSStringFromCGRect(playerLayer.bounds));
        NSLog(@"   - PlayerLayer superlayer: %@", playerLayer.superlayer ? @"存在" : @"不存在");
        UIView *hostView = [self findHostViewForLayer:playerLayer];
        NSLog(@"   - Host view: %@", hostView ? NSStringFromClass([hostView class]) : @"未找到");
        NSLog(@"   - Host view window: %@", hostView.window ? @"存在" : @"不存在");
    }
    
    // 5. PiP控制器检查
    if (self.pipController) {
        NSLog(@"5. PiP控制器:");
        NSLog(@"   - isPictureInPicturePossible: %@", self.pipController.isPictureInPicturePossible ? @"YES" : @"NO");
        NSLog(@"   - isPictureInPictureActive: %@", self.pipController.isPictureInPictureActive ? @"YES" : @"NO");
        NSLog(@"   - PlayerLayer引用: %@", self.pipController.playerLayer ? @"存在" : @"不存在");
    }
    
    // 6. 系统状态检查
    NSLog(@"6. 系统状态:");
    NSLog(@"   - 应用状态: %ld", (long)[UIApplication sharedApplication].applicationState);
    NSLog(@"   - 多任务支持: %@", [[UIDevice currentDevice] isMultitaskingSupported] ? @"YES" : @"NO");
    
    NSLog(@"=== 诊断完成 ===");
}

#pragma mark - Delegate Notifications

- (void)notifyDelegateFailedWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:failedToStartWithError:)]) {
        [self.delegate pictureInPictureManager:self failedToStartWithError:error];
    }
}

#pragma mark - Properties

- (BOOL)isPictureInPictureSupported {
    return [self checkPictureInPictureSupport];
}

- (BOOL)isPictureInPictureActive {
    if (@available(iOS 15.0, *)) {
        return self.pipController.isPictureInPictureActive;
    }
    return NO;
}

- (BOOL)isPictureInPicturePossible {
    if (@available(iOS 15.0, *)) {
        return self.pipController.isPictureInPicturePossible;
    }
    return NO;
}

#pragma mark - AVPictureInPictureControllerDelegate

- (void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"TFY_PipManager: 画中画即将开始");
    
    if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:willStartPictureInPicture:)]) {
        [self.delegate pictureInPictureManager:self willStartPictureInPicture:pictureInPictureController];
    }
}

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"TFY_PipManager: 画中画已开始");
    [self setState:TFYPipStateActive];
    
    if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:didStartPictureInPicture:)]) {
        [self.delegate pictureInPictureManager:self didStartPictureInPicture:pictureInPictureController];
    }
}

- (void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"TFY_PipManager: 画中画即将停止");
    
    if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:willStopPictureInPicture:)]) {
        [self.delegate pictureInPictureManager:self willStopPictureInPicture:pictureInPictureController];
    }
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    NSLog(@"TFY_PipManager: 画中画已停止");
    [self setState:TFYPipStateInactive];
    
    // 如果不是连续播放模式，清理资源
    if (!self.isContinuousPlaybackMode) {
        [self resetPictureInPictureController];
    }
    
    if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:didStopPictureInPicture:)]) {
        [self.delegate pictureInPictureManager:self didStopPictureInPicture:pictureInPictureController];
    }
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController 
           failedToStartPictureInPictureWithError:(NSError *)error {
    NSLog(@"TFY_PipManager: 画中画启动失败: %@", error.localizedDescription);
    
    [self setState:TFYPipStateFailed];
    self.lastError = error;
    self.isProcessing = NO;
    
    [self notifyDelegateFailedWithError:error];
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController 
restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler {
    NSLog(@"TFY_PipManager: 请求恢复用户界面");
    
    if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:)]) {
        [self.delegate pictureInPictureManager:self 
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(NO);
        }
    }
}

@end 
