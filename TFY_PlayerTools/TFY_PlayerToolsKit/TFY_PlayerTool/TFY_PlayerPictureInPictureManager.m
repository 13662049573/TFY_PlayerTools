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
        // 检查是否正在处理
        if (self.isProcessing) {
            return NO;
        }
        
        // 检查重试次数
        if (self.currentRetryCount >= self.maxRetryCount) {
            [self createErrorWithCode:TFYPipErrorCodeRetryLimitExceeded description:@"重试次数超过限制"];
            [self setState:TFYPipStateFailed];
            return NO;
        }
        
        // 防抖检查
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        if (currentTime - self.lastStartTime < self.debounceInterval) {
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
}

#pragma mark - Private Methods

- (BOOL)performStartupChecks:(NSError **)error {
    if (!self.enablePictureInPicture) {
        *error = [self createErrorWithCode:TFYPipErrorCodeNotEnabled description:@"画中画功能未启用"];
        return NO;
    }
    if (![self checkPictureInPictureSupport]) {
        *error = [self createErrorWithCode:TFYPipErrorCodeUnsupported description:@"设备不支持画中画"];
        return NO;
    }
    if (!self.playerController || !self.playerController.currentPlayerManager) {
        *error = [self createErrorWithCode:TFYPipErrorCodePlayerNotReady description:@"播放器控制器为空"];
        return NO;
    }
    if (!self.playerController.currentPlayerManager.isPreparedToPlay) {
        *error = [self createErrorWithCode:TFYPipErrorCodePlayerNotReady description:@"播放器未准备好"];
        return NO;
    }
    AVPlayer *player = [self getAVPlayer];
    AVPlayerLayer *playerLayer = [self getAVPlayerLayer];
    if (!player) {
        *error = [self createErrorWithCode:TFYPipErrorCodePlayerNotReady description:@"AVPlayer为空"];
        return NO;
    }
    if (!player.currentItem) {
        *error = [self createErrorWithCode:TFYPipErrorCodePlayerNotReady description:@"AVPlayerItem为空"];
        return NO;
    }
    if (player.currentItem.status != AVPlayerItemStatusReadyToPlay) {
        *error = [self createErrorWithCode:TFYPipErrorCodePlayerNotReady description:@"AVPlayerItem未准备好"];
        return NO;
    }
    if (!playerLayer) {
        *error = [self createErrorWithCode:TFYPipErrorCodeLayerNotFound description:@"AVPlayerLayer为空"];
        return NO;
    }
    NSArray *videoTracks = [player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count == 0) {
        *error = [self createErrorWithCode:TFYPipErrorCodeContentUnsupported description:@"没有视频轨道"];
        return NO;
    }
    
    if (CGRectIsEmpty(playerLayer.bounds) || CGRectEqualToRect(playerLayer.bounds, CGRectZero)) {
        *error = [self createErrorWithCode:TFYPipErrorCodeLayerNotFound description:@"AVPlayerLayer bounds无效"];
        return NO;
    }
    if (!playerLayer.superlayer) {
        *error = [self createErrorWithCode:TFYPipErrorCodeLayerNotFound description:@"AVPlayerLayer未添加到视图层级"];
        return NO;
    }
    UIView *hostView = [self findHostViewForLayer:playerLayer];
    if (!hostView || !hostView.window) {
        *error = [self createErrorWithCode:TFYPipErrorCodeWindowNotAttached description:@"AVPlayerLayer未关联到window"];
        return NO;
    }
    if (playerLayer.player != player) {
        playerLayer.player = player;
    }
    if (![self ensurePipController:error]) {
        NSLog(@"[PIP] ensurePipController失败: %@", *error ? (*error).localizedDescription : @"未知错误");
        return NO;
    }
    if (self.pipController.isPictureInPictureActive) {
        *error = [self createErrorWithCode:TFYPipErrorCodeAlreadyActive description:@"画中画已在活动状态"];
        return NO;
    }
    
    if (!self.pipController.isPictureInPicturePossible) {

        // 如果这是第一次检查，等待一段时间再重试
        if (self.currentRetryCount == 0) {
            self.currentRetryCount++;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.pipController.isPictureInPicturePossible) {
                    [self.pipController startPictureInPicture];
                }
            });
            
            return YES; // 返回YES，因为我们会在延迟后重试
        } else {
            *error = [self createErrorWithCode:TFYPipErrorCodeSystemRestriction description:@"系统限制，无法启动画中画"];
            return NO;
        }
    }
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
        if ([self.delegate respondsToSelector:@selector(pictureInPictureManagerRequestNextAssetURL:)]) {
            NSURL *nextURL = [self.delegate pictureInPictureManagerRequestNextAssetURL:self];
            
            if (nextURL) {
                [self startContinuousPlaybackWithURL:nextURL];
            } else {
                [self completeContinuousPlayback];
            }
        }
    }
}

- (void)startContinuousPlaybackWithURL:(NSURL *)url {
    self.isContinuousPlaybackMode = YES;
    
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
            }
        } else if (item.status == AVPlayerItemStatusFailed) {
            [item removeObserver:self forKeyPath:@"status"];
            [self completeContinuousPlayback];
        }
    } else if ([keyPath isEqualToString:@"pictureInPicturePossible"] && object == self.pipController) {
        BOOL isPossible = [change[NSKeyValueChangeNewKey] boolValue];
        if (isPossible) {
            // 通知代理画中画状态可用
            if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:didChangeState:)]) {
                [self.delegate pictureInPictureManager:self didChangeState:TFYPipStateInactive];
            }
        } else {
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
}

- (void)cleanupContinuousPlayback {
    self.isContinuousPlaybackMode = NO;
}

- (void)configureAudioSessionForPiP {
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

    if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:willStartPictureInPicture:)]) {
        [self.delegate pictureInPictureManager:self willStartPictureInPicture:pictureInPictureController];
    }
}

- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    
    [self setState:TFYPipStateActive];
    
    if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:didStartPictureInPicture:)]) {
        [self.delegate pictureInPictureManager:self didStartPictureInPicture:pictureInPictureController];
    }
}

- (void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
   
    if ([self.delegate respondsToSelector:@selector(pictureInPictureManager:willStopPictureInPicture:)]) {
        [self.delegate pictureInPictureManager:self willStopPictureInPicture:pictureInPictureController];
    }
}

- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
   
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
    
    [self setState:TFYPipStateFailed];
    self.lastError = error;
    self.isProcessing = NO;
    
    [self notifyDelegateFailedWithError:error];
}

- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController 
restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler {
    
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
