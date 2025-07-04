//
//  TFY_PlayerController.m
//  TFY_PlayerView
//
//  Created by 田风有 on 2019/6/30.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "TFY_PlayerController.h"
#import <objc/runtime.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "UIScrollView+TFY_Player.h"
#import "TFY_PlayerToolsHeader.h"
#import "TFY_ReachabilityManager.h"
#import "TFY_AVPlayerManager.h"
#import "TFY_PlayerPerformanceOptimizer.h"
#import "TFY_PlayerPictureInPictureManager.h"



// 缓存键定义
static NSString * const kPlayerStateCacheKey = @"player_state";
static NSString * const kPlayerConfigCacheKey = @"player_config";
static NSString * const kPlayerTimeCacheKey = @"player_time";

static NSMutableDictionary <NSString* ,NSNumber *> *_tfyPlayRecords;

@interface TFY_PlayerController () <TFYPictureInPictureManagerDelegate>

@property (nonatomic, strong) TFY_PlayerNotification *notification;
@property (nonatomic, strong) UISlider *volumeViewSlider;
@property (nonatomic, assign) NSInteger containerViewTag;
@property (nonatomic, assign) PlayerContainerType containerType;
/// The player's small container view.
@property (nonatomic, strong) TFY_FloatView *smallFloatView;
/// Whether the small window is displayed.
@property (nonatomic, assign) BOOL isSmallFloatViewShow;
/// The indexPath is playing.
@property (nonatomic, nullable) NSIndexPath *playingIndexPath;

/// 画中画管理器
@property (nonatomic, strong) TFY_PlayerPictureInPictureManager *pipManager;

// 性能优化相关属性
@property (nonatomic, strong) NSCache *playerCache;
@property (nonatomic, assign) BOOL isPlayerReady;
@property (nonatomic, strong) dispatch_queue_t backgroundQueue;

// 画中画连续播放相关属性
@property (nonatomic, assign) BOOL pipStoppedDueToPlaybackEnd;
@property (nonatomic, assign) BOOL isHandlingPipContinuousPlay;
@property (nonatomic, assign) NSInteger pipRetryCount;

@end

@implementation TFY_PlayerController

@dynamic containerViewTag;
@dynamic playingIndexPath;

- (instancetype)init {
    self = [super init];
    if (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _tfyPlayRecords = @{}.mutableCopy;
        });
        
        // 初始化性能优化相关属性
        self.playerCache = [[NSCache alloc] init];
        self.playerCache.countLimit = 50;
        self.playerCache.totalCostLimit = 10 * 1024 * 1024; // 10MB
        self.isPlayerReady = NO;
        self.backgroundQueue = dispatch_queue_create("com.tfy.player.background", DISPATCH_QUEUE_SERIAL);
        
        // 启用性能优化和监控
        TFY_PlayerPerformanceOptimizer *optimizer = [TFY_PlayerPerformanceOptimizer sharedOptimizer];
        [optimizer applyRecommendedOptimizations];
        [optimizer startPerformanceMonitoring];
        
        // 初始化画中画管理器
        self.pipManager = [[TFY_PlayerPictureInPictureManager alloc] initWithPlayerController:self];
        self.pipManager.delegate = self;
        
        @player_weakify(self)
        [[TFY_ReachabilityManager sharedManager] startMonitoring];
        [[TFY_ReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(ReachabilityStatus status) {
            @player_strongify(self)
            if ([self.controlView respondsToSelector:@selector(videoPlayer:reachabilityChanged:)]) {
                [self.controlView videoPlayer:self reachabilityChanged:status];
            }
        }];
        [self configureVolume];
        
        self.autoStartPiPWhenEnterBackground = YES;
    }
    return self;
}

/// Get system volume
- (void)configureVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    self.volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:kVolumeSliderClassName]){
            self.volumeViewSlider = (UISlider *)view;
            break;
        }
    }
}

- (void)dealloc {
    [self.currentPlayerManager stop];
    
    // 清理画中画管理器
    [self.pipManager cleanup];
    self.pipManager = nil;
    
    // 停止性能监控
    [[TFY_PlayerPerformanceOptimizer sharedOptimizer] stopPerformanceMonitoring];
    
    // 清理缓存
    [self.playerCache removeAllObjects];
    self.playerCache = nil;
    
    // 清理播放记录
    if (_tfyPlayRecords) {
        [_tfyPlayRecords removeAllObjects];
    }
}

+ (instancetype)playerWithPlayerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerView:(nonnull UIView *)containerView {
    TFY_PlayerController *player = [[self alloc] initWithPlayerManager:playerManager containerView:containerView];
    return player;
}

+ (instancetype)playerWithScrollView:(UIScrollView *)scrollView playerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag {
    TFY_PlayerController *player = [[self alloc] initWithScrollView:scrollView playerManager:playerManager containerViewTag:containerViewTag];
    return player;
}

+ (instancetype)playerWithScrollView:(UIScrollView *)scrollView playerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerView:(UIView *)containerView {
    TFY_PlayerController *player = [[self alloc] initWithScrollView:scrollView playerManager:playerManager containerView:containerView];
    return player;
}

- (instancetype)initWithPlayerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerView:(nonnull UIView *)containerView {
    TFY_PlayerController *player = [self init];
    player.containerView = containerView;
    player.currentPlayerManager = playerManager;
    player.containerType = PlayerContainerTypeView;
    return player;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView playerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag {
    TFY_PlayerController *player = [self init];
    player.scrollView = scrollView;
    player.containerViewTag = containerViewTag;
    player.currentPlayerManager = playerManager;
    player.containerType = PlayerContainerTypeCell;
    return player;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView playerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerView:(UIView *)containerView {
    TFY_PlayerController *player = [self init];
    player.scrollView = scrollView;
    player.containerView = containerView;
    player.currentPlayerManager = playerManager;
    player.containerType = PlayerContainerTypeView;
    return player;
}

- (void)playerManagerCallbcak {
    @player_weakify(self)
    self.currentPlayerManager.playerPrepareToPlay = ^(id<TFY_PlayerMediaPlayback>  _Nonnull asset, NSURL * _Nonnull assetURL) {
        @player_strongify(self)
        // 应用缓存的配置
        [self applyCachedPlayerConfig];
        
        if (self.resumePlayRecord && [_tfyPlayRecords valueForKey:assetURL.absoluteString]) {
            NSTimeInterval seekTime = [_tfyPlayRecords valueForKey:assetURL.absoluteString].doubleValue;
            self.currentPlayerManager.seekTime = seekTime;
        }
        [self.notification addNotification];
        [self addDeviceOrientationObserver];
        if (self.scrollView) {
            self.scrollView.tfy_stopPlay = NO;
        }
        [self layoutPlayerSubViews];
        if (self.playerPrepareToPlay) self.playerPrepareToPlay(asset,assetURL);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:prepareToPlay:)]) {
            [self.controlView videoPlayer:self prepareToPlay:assetURL];
        }
    };
    
    self.currentPlayerManager.playerReadyToPlay = ^(id<TFY_PlayerMediaPlayback>  _Nonnull asset, NSURL * _Nonnull assetURL) {
        @player_strongify(self)
        self.isPlayerReady = YES;
        // 缓存播放器状态
        [self cachePlayerState];
        
        if (self.playerReadyToPlay) self.playerReadyToPlay(asset,assetURL);
        if (!self.customAudioSession) {
            [self.pipManager configureAudioSessionForPiP];
        }
        if (self.viewControllerDisappear) self.pauseByEvent = YES;
    };
    
    self.currentPlayerManager.playerPlayTimeChanged = ^(id<TFY_PlayerMediaPlayback>  _Nonnull asset, NSTimeInterval currentTime, NSTimeInterval duration) {
        @player_strongify(self)
        if (self.playerPlayTimeChanged) self.playerPlayTimeChanged(asset,currentTime,duration);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:currentTime:totalTime:)]) {
            [self.controlView videoPlayer:self currentTime:currentTime totalTime:duration];
        }
        if (self.currentPlayerManager.assetURL.absoluteString) {
            [_tfyPlayRecords setValue:@(currentTime) forKey:self.currentPlayerManager.assetURL.absoluteString];
        }
        
        // 定期缓存播放器状态（每5秒）
        static NSTimeInterval lastCacheTime = 0;
        NSTimeInterval now = CACurrentMediaTime();
        if (now - lastCacheTime > 5.0) {
            [self cachePlayerState];
            lastCacheTime = now;
        }
    };
    
    self.currentPlayerManager.playerBufferTimeChanged = ^(id<TFY_PlayerMediaPlayback>  _Nonnull asset, NSTimeInterval bufferTime) {
        @player_strongify(self)
        if ([self.controlView respondsToSelector:@selector(videoPlayer:bufferTime:)]) {
            [self.controlView videoPlayer:self bufferTime:bufferTime];
        }
        if (self.playerBufferTimeChanged) self.playerBufferTimeChanged(asset,bufferTime);
    };
    
    self.currentPlayerManager.playerPlayStateChanged = ^(id  _Nonnull asset, PlayerPlaybackState playState) {
        @player_strongify(self)
        if (self.playerPlayStateChanged) self.playerPlayStateChanged(asset, playState);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:playStateChanged:)]) {
            [self.controlView videoPlayer:self playStateChanged:playState];
        }
    };
    
    self.currentPlayerManager.playerLoadStateChanged = ^(id  _Nonnull asset, PlayerLoadState loadState) {
        @player_strongify(self)
        if (loadState == PlayerLoadStatePrepare && CGSizeEqualToSize(CGSizeZero, self.currentPlayerManager.presentationSize)) {
            CGSize size = self.currentPlayerManager.view.frame.size;
            self.orientationObserver.presentationSize = size;
        }
        if (self.playerLoadStateChanged) self.playerLoadStateChanged(asset, loadState);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:loadStateChanged:)]) {
            [self.controlView videoPlayer:self loadStateChanged:loadState];
        }
    };
    
    self.currentPlayerManager.playerDidToEnd = ^(id  _Nonnull asset) {
        @player_strongify(self)
        if (self.currentPlayerManager.assetURL.absoluteString) {
            [_tfyPlayRecords setValue:@(0) forKey:self.currentPlayerManager.assetURL.absoluteString];
        }
        
        // 检查是否在画中画模式下播放结束
        BOOL isPipActive = [self isPictureInPictureActive];
        
        if (isPipActive) {
            // 检查是否需要处理画中画连续播放
            if (!self.isHandlingPipContinuousPlay) {
                // 第一次开始画中画连续播放
                self.isHandlingPipContinuousPlay = YES;
            }
            
            // 标记画中画是因为播放结束而停止的
            self.pipStoppedDueToPlaybackEnd = YES;
            self.pipRetryCount = 0;
            // 在画中画模式下，直接处理连续播放逻辑
            [self handlePipContinuousPlayback];
        }
        if (self.playerDidToEnd) self.playerDidToEnd(asset);
        if ([self.controlView respondsToSelector:@selector(videoPlayerPlayEnd:)]) {
            [self.controlView videoPlayerPlayEnd:self];
        }
    };
    
    self.currentPlayerManager.playerPlayFailed = ^(id<TFY_PlayerMediaPlayback>  _Nonnull asset, id  _Nonnull error) {
        @player_strongify(self)
        if (self.playerPlayFailed) self.playerPlayFailed(asset, error);
        if ([self.controlView respondsToSelector:@selector(videoPlayerPlayFailed:error:)]) {
            [self.controlView videoPlayerPlayFailed:self error:error];
        }
    };
    
    self.currentPlayerManager.presentationSizeChanged = ^(id<TFY_PlayerMediaPlayback>  _Nonnull asset, CGSize size){
        @player_strongify(self)
        self.orientationObserver.presentationSize = size;
        if (self.orientationObserver.fullScreenMode == FullScreenModeAutomatic) {
            if (size.width > size.height) {
                self.orientationObserver.fullScreenMode = FullScreenModeLandscape;
            } else {
                self.orientationObserver.fullScreenMode = FullScreenModePortrait;
            }
        }
        if (self.presentationSizeChanged) self.presentationSizeChanged(asset, size);
        if ([self.controlView respondsToSelector:@selector(videoPlayer:presentationSizeChanged:)]) {
            [self.controlView videoPlayer:self presentationSizeChanged:size];
        }
    };
}

- (void)layoutPlayerSubViews {
    if (self.containerView && self.currentPlayerManager.view && self.currentPlayerManager.isPreparedToPlay) {
        UIView *superview = nil;
        if (self.isFullScreen) {
            superview = self.orientationObserver.fullScreenContainerView;
        } else if (self.containerView) {
            superview = self.containerView;
        }
        [superview addSubview:self.currentPlayerManager.view];
        [self.currentPlayerManager.view addSubview:self.controlView];
        
        self.currentPlayerManager.view.frame = superview.bounds;
        self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.controlView.frame = self.currentPlayerManager.view.bounds;
        self.controlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.orientationObserver updateRotateView:self.currentPlayerManager.view containerView:self.containerView];
    }
}

#pragma mark - getter

- (TFY_PlayerNotification *)notification {
    if (!_notification) {
        _notification = [[TFY_PlayerNotification alloc] init];
        @player_weakify(self)
        _notification.willResignActive = ^(TFY_PlayerNotification * _Nonnull registrar) {
            @player_strongify(self)
            if (self.isViewControllerDisappear) return;
            if (self.pauseWhenAppResignActive && self.currentPlayerManager.isPlaying && !self.autoStartPiPWhenEnterBackground) {
                self.pauseByEvent = YES;
            }
            self.orientationObserver.lockedScreen = YES;
            UIWindow *window = nil;
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                    if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                        window = windowScene.windows.firstObject;
                        break;
                    }
                }
            }
            [window endEditing:YES];
            if (!self.pauseWhenAppResignActive) {
                [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                [self.pipManager configureAudioSessionForPiP];
            }
            
            if (self.autoStartPiPWhenEnterBackground && !self.isPictureInPictureActive && self.enablePictureInPicture) {
                [self startPictureInPicture];
            }
        };
        _notification.didBecomeActive = ^(TFY_PlayerNotification * _Nonnull registrar) {
            @player_strongify(self)
            if (self.isViewControllerDisappear) return;
            if (self.isPauseByEvent && !self.autoStartPiPWhenEnterBackground) self.pauseByEvent = NO;
            self.orientationObserver.lockedScreen = NO;
        };
        _notification.oldDeviceUnavailable = ^(TFY_PlayerNotification * _Nonnull registrar) {
            @player_strongify(self)
            if (self.currentPlayerManager.isPlaying) {
                [self.currentPlayerManager play];
            }
        };
        _notification.protectedDataWill = ^(TFY_PlayerNotification * _Nonnull registrar) {
            @player_strongify(self)
            [self.currentPlayerManager pause];
        };
    }
    return _notification;
}

- (TFY_FloatView *)smallFloatView {
    if (!_smallFloatView) {
        _smallFloatView = [[TFY_FloatView alloc] init];
        UIWindow *parentWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    parentWindow = windowScene.windows.firstObject;
                    break;
                }
            }
        }
        _smallFloatView.parentView = parentWindow;
        _smallFloatView.hidden = YES;
    }
    return _smallFloatView;
}

#pragma mark - setter

- (void)setCurrentPlayerManager:(id<TFY_PlayerMediaPlayback>)currentPlayerManager {
    if (!currentPlayerManager) return;
    if (_currentPlayerManager.isPreparedToPlay) {
        [_currentPlayerManager stop];
        [_currentPlayerManager.view removeFromSuperview];
        [self removeDeviceOrientationObserver];
        [self.gestureControl removeGestureToView:self.currentPlayerManager.view];
    }
    _currentPlayerManager = currentPlayerManager;
    self.gestureControl.disableTypes = self.disableGestureTypes;
    [self.gestureControl addGestureToView:currentPlayerManager.view];
    [self playerManagerCallbcak];
    self.controlView.player = self;
    [self layoutPlayerSubViews];
    if (currentPlayerManager.isPreparedToPlay) {
        [self addDeviceOrientationObserver];
    }
    [self.orientationObserver updateRotateView:currentPlayerManager.view containerView:self.containerView];
}

- (void)setContainerView:(UIView *)containerView {
    _containerView = containerView;
    if (self.scrollView) {
        self.scrollView.tfy_containerView = containerView;
    }
    if (!containerView) return;
    containerView.userInteractionEnabled = YES;
    [self layoutPlayerSubViews];
    [self.orientationObserver updateRotateView:self.currentPlayerManager.view containerView:containerView];
}

- (void)setControlView:(UIView<TFY_PlayerMediaControl> *)controlView {
    if (controlView && controlView != _controlView) {
        [_controlView removeFromSuperview];
    }
    _controlView = controlView;
    if (!controlView) return;
    controlView.player = self;
    [self layoutPlayerSubViews];
}

- (void)setContainerType:(PlayerContainerType)containerType {
    _containerType = containerType;
    if (self.scrollView) {
        self.scrollView.tfy_containerType = containerType;
    }
}

- (void)setScrollView:(UIScrollView *)scrollView {
    _scrollView = scrollView;
    self.scrollView.tfy_WWANAutoPlay = self.isWWANAutoPlay;
    @player_weakify(self)
    scrollView.tfy_playerWillAppearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        if (self.isFullScreen) return;
        if (self.tfy_playerWillAppearInScrollView) self.tfy_playerWillAppearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerDidAppearInScrollView:)]) {
            [self.controlView playerDidAppearInScrollView:self];
        }
    };
    
    scrollView.tfy_playerDidAppearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        if (self.isFullScreen) return;
        if (self.tfy_playerDidAppearInScrollView) self.tfy_playerDidAppearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerDidAppearInScrollView:)]) {
            [self.controlView playerDidAppearInScrollView:self];
        }
    };
    
    scrollView.tfy_playerWillDisappearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        if (self.isFullScreen) return;
        if (self.tfy_playerWillDisappearInScrollView) self.tfy_playerWillDisappearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerWillDisappearInScrollView:)]) {
            [self.controlView playerWillDisappearInScrollView:self];
        }
    };
    
    scrollView.tfy_playerDidDisappearInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        if (self.isFullScreen) return;
        if (self.tfy_playerDidDisappearInScrollView) self.tfy_playerDidDisappearInScrollView(indexPath);
        if ([self.controlView respondsToSelector:@selector(playerDidDisappearInScrollView:)]) {
            [self.controlView playerDidDisappearInScrollView:self];
        }
       
        if (self.stopWhileNotVisible) { /// stop playing
            if (self.containerType == PlayerContainerTypeView) {
                [self stopCurrentPlayingView];
            } else if (self.containerType == PlayerContainerTypeCell) {
                [self stopCurrentPlayingCell];
            }
        } else { /// add to window
            if (!self.isSmallFloatViewShow) {
                [self addPlayerViewToSmallFloatView];
            }
        }
    };
    
    scrollView.tfy_playerAppearingInScrollView = ^(NSIndexPath * _Nonnull indexPath, CGFloat playerApperaPercent) {
        @player_strongify(self)
        if (self.isFullScreen) return;
        if (self.tfy_playerAppearingInScrollView) self.tfy_playerAppearingInScrollView(indexPath, playerApperaPercent);
        if ([self.controlView respondsToSelector:@selector(playerAppearingInScrollView:playerApperaPercent:)]) {
            [self.controlView playerAppearingInScrollView:self playerApperaPercent:playerApperaPercent];
        }
        if (!self.stopWhileNotVisible && playerApperaPercent >= self.playerApperaPercent) {
            if (self.containerType == PlayerContainerTypeView) {
                if (self.isSmallFloatViewShow) {
                    [self addPlayerViewToContainerView:self.containerView];
                }
            } else if (self.containerType == PlayerContainerTypeCell) {
                if (self.isSmallFloatViewShow) {
                    [self addPlayerViewToCell];
                }
            }
        }
    };
    
    scrollView.tfy_playerDisappearingInScrollView = ^(NSIndexPath * _Nonnull indexPath, CGFloat playerDisapperaPercent) {
        @player_strongify(self)
        if (self.isFullScreen) return;
        if (self.tfy_playerDisappearingInScrollView) self.tfy_playerDisappearingInScrollView(indexPath, playerDisapperaPercent);
        if ([self.controlView respondsToSelector:@selector(playerDisappearingInScrollView:playerDisapperaPercent:)]) {
            [self.controlView playerDisappearingInScrollView:self playerDisapperaPercent:playerDisapperaPercent];
        }
        if (playerDisapperaPercent >= self.playerDisapperaPercent) {
            if (self.stopWhileNotVisible) { /// stop playing
                if (self.containerType == PlayerContainerTypeView) {
                    [self stopCurrentPlayingView];
                } else if (self.containerType == PlayerContainerTypeCell) {
                    [self stopCurrentPlayingCell];
                }
            } else {  /// add to window
                if (!self.isSmallFloatViewShow) {
                    [self addPlayerViewToSmallFloatView];
                }
            }
        }
    };
    
    scrollView.tfy_playerShouldPlayInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        if (self.tfy_playerShouldPlayInScrollView) self.tfy_playerShouldPlayInScrollView(indexPath);
    };
    
    scrollView.tfy_scrollViewDidEndScrollingCallback = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        if (self.tfy_scrollViewDidEndScrollingCallback) self.tfy_scrollViewDidEndScrollingCallback(indexPath);
    };
}

- (void)setCustomAudioSession:(BOOL)customAudioSession {
    objc_setAssociatedObject(self, @selector(customAudioSession), @(customAudioSession), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setShouldLoopPlay:(BOOL)shouldLoopPlay {
    objc_setAssociatedObject(self, @selector(shouldLoopPlay), @(shouldLoopPlay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setShouldAutoPlayNext:(BOOL)shouldAutoPlayNext {
    objc_setAssociatedObject(self, @selector(shouldAutoPlayNext), @(shouldAutoPlayNext), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - PiP Controller Reset

- (void)handlePipContinuousPlayback {
    // 延迟一点时间确保播放器状态稳定
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPipCheckDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.shouldAutoPlayNext && !self.isLastAssetURL) {
            [self playTheNextInPip];
        } else if (self.shouldLoopPlay) {
            [self playTheIndexInPip:0];
        } else {
            self.isHandlingPipContinuousPlay = NO;
        }
    });
}

// 画中画专用的播放下一个视频方法
- (void)playTheNextInPip {
    if (self.assetURLs.count > 0) {
        NSInteger index = self.currentPlayIndex + 1;
        if (index >= self.assetURLs.count) {
            // 如果启用了循环播放，从头开始播放
            if (self.shouldLoopPlay) {
                index = 0;
            } else {
                self.isHandlingPipContinuousPlay = NO;
                return; // 不循环播放，停止播放
            }
        }
        [self playTheIndexInPip:index];
    }
}

// 画中画专用的播放指定索引视频方法
- (void)playTheIndexInPip:(NSInteger)index {
    if (self.assetURLs.count > 0) {
        if (index >= self.assetURLs.count) {
            self.isHandlingPipContinuousPlay = NO;
            return;
        }
        
        NSURL *assetURL = [self.assetURLs objectAtIndex:index];
        self.currentPlayIndex = index;
        // 设置新的资源URL但不触发播放器重建
        objc_setAssociatedObject(self, @selector(assetURL), assetURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // 使用画中画专用的资源切换方法
        [self switchToNewAssetInPipMode:assetURL];
    }
}

// 画中画模式下的资源切换方法
- (void)switchToNewAssetInPipMode:(NSURL *)assetURL {
    // 获取当前的AVPlayer实例
    AVPlayer *player = [self getCurrentPlayer];
    
    if (player) {
        // 创建新的AVPlayerItem而不是重新创建整个播放器
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
        AVPlayerItem *newPlayerItem = [AVPlayerItem playerItemWithAsset:asset];
        // 暂停当前播放
        [player pause];
        
        // 替换PlayerItem
        [player replaceCurrentItemWithPlayerItem:newPlayerItem];
        
        // 等待新item准备就绪后开始播放
        [self observeNewPlayerItemForPip:newPlayerItem];
    } else {
        // 如果无法获取AVPlayer，回退到普通方式
        [self fallbackToNormalAssetSwitch:assetURL];
    }
}

// 回退到普通的资源切换方式
- (void)fallbackToNormalAssetSwitch:(NSURL *)assetURL {
    // 记录画中画状态
    BOOL wasPipActive = [self isPictureInPictureActive];
    
    if (wasPipActive) {
        // 在画中画模式下，使用特殊的方式切换资源，避免完全重建播放器
        [self switchAssetURLForPipMode:assetURL];
        // 等待播放器准备好后重新启动画中画
        [self observePlayerReadyStateForPip:assetURL];
    } else {
        // 非画中画模式，使用正常方式
        self.currentPlayerManager.assetURL = assetURL;
        // 标记画中画连续播放处理完成
        self.isHandlingPipContinuousPlay = NO;
        self.pipStoppedDueToPlaybackEnd = NO;
    }
}

// 专门为画中画模式设计的资源切换方法  
- (void)switchAssetURLForPipMode:(NSURL *)assetURL {
    // 获取当前的AVPlayer和AVPlayerLayer
    AVPlayer *currentPlayer = [self getCurrentPlayer];
    AVPlayerLayer *currentPlayerLayer = [self getCurrentPlayerLayer];
    
    if (currentPlayer && currentPlayerLayer) {
        // 暂停当前播放
        [currentPlayer pause];
        
        // 创建新的AVURLAsset和AVPlayerItem
        AVURLAsset *newAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
        AVPlayerItem *newPlayerItem = [AVPlayerItem playerItemWithAsset:newAsset];
        
        // 替换PlayerItem
        [currentPlayer replaceCurrentItemWithPlayerItem:newPlayerItem];
        
        // 手动更新播放器管理器的内部引用
        [self updatePlayerManagerReferencesForPip:newAsset playerItem:newPlayerItem assetURL:assetURL];
        
        // 监听新PlayerItem的状态
        [self observeNewPlayerItemForPip:newPlayerItem];
        
    } else {
        // 如果无法获取必要的对象，回退到正常方式
        self.currentPlayerManager.assetURL = assetURL;
    }
}

// 安全获取当前AVPlayer的方法
- (AVPlayer *)getCurrentPlayer {
    // 先从缓存获取
    NSString *cacheKey = [NSString stringWithFormat:@"player_%@", self.currentPlayerManager.assetURL.absoluteString];
    AVPlayer *cachedPlayer = [self.playerCache objectForKey:cacheKey];
    if (cachedPlayer) {
        return cachedPlayer;
    }
    
    if ([self.currentPlayerManager respondsToSelector:@selector(player)]) {
        AVPlayer *player = [self.currentPlayerManager performSelector:@selector(player)];
        if (player) {
            // 缓存player实例
            [self.playerCache setObject:player forKey:cacheKey cost:1];
        }
        return player;
    }
    return nil;
}

// 安全获取当前AVPlayerLayer的方法
- (AVPlayerLayer *)getCurrentPlayerLayer {
    // 先从缓存获取
    NSString *cacheKey = [NSString stringWithFormat:@"playerLayer_%@", self.currentPlayerManager.assetURL.absoluteString];
    AVPlayerLayer *cachedLayer = [self.playerCache objectForKey:cacheKey];
    if (cachedLayer) {
        return cachedLayer;
    }
    
    if ([self.currentPlayerManager respondsToSelector:@selector(avPlayerLayer)]) {
        AVPlayerLayer *layer = [self.currentPlayerManager performSelector:@selector(avPlayerLayer)];
        if (layer) {
            // 缓存layer实例
            [self.playerCache setObject:layer forKey:cacheKey cost:1];
        }
        return layer;
    }
    return nil;
}

// 手动更新播放器管理器的内部引用
- (void)updatePlayerManagerReferencesForPip:(AVURLAsset *)asset playerItem:(AVPlayerItem *)playerItem assetURL:(NSURL *)assetURL {
    // 使用KVC直接设置内部属性，避免触发setter
    @try {
        NSObject *playerManager = (NSObject *)self.currentPlayerManager;
        [playerManager setValue:asset forKey:@"asset"];
        [playerManager setValue:playerItem forKey:@"playerItem"];
        [playerManager setValue:assetURL forKey:@"assetURL"];
    } @catch (NSException *exception) {
        NSLog(@"TFY_PlayerController: updatePlayerManagerReferencesForPip - 更新内部引用失败: %@", exception.reason);
    }
}

// 重新初始化播放器管理器的观察者和通知系统
- (void)reinitializePlayerManagerObserversForPip {
    
    // 先清理旧的观察者和通知
    @try {
        NSObject *playerManager = (NSObject *)self.currentPlayerManager;
        
        // 移除旧的KVO观察者
        id playerItemKVO = [playerManager valueForKey:@"playerItemKVO"];
        if (playerItemKVO && [playerItemKVO respondsToSelector:NSSelectorFromString(@"safelyRemoveAllObservers")]) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [playerItemKVO performSelector:NSSelectorFromString(@"safelyRemoveAllObservers")];
            #pragma clang diagnostic pop
        }
        
        // 移除旧的时间观察者
        id timeObserver = [playerManager valueForKey:@"timeObserver"];
        if (timeObserver) {
            AVPlayer *player = [self.currentPlayerManager performSelector:@selector(player)];
            if (player) {
                [player removeTimeObserver:timeObserver];
                [playerManager setValue:nil forKey:@"timeObserver"];
            }
        }
        
        // 移除旧的播放结束通知
        id itemEndObserver = [playerManager valueForKey:@"itemEndObserver"];
        if (itemEndObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:itemEndObserver];
            [playerManager setValue:nil forKey:@"itemEndObserver"];
        }
        
    } @catch (NSException *exception) {
        NSLog(@"TFY_PlayerController: reinitializePlayerManagerObserversForPip - 清理旧观察者时出错: %@", exception.reason);
    }
    
    // 调用播放器管理器的itemObserving方法来重新设置所有必要的观察者和通知
    SEL itemObservingSelector = NSSelectorFromString(@"itemObserving");
    if ([self.currentPlayerManager respondsToSelector:itemObservingSelector]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.currentPlayerManager performSelector:itemObservingSelector];
        #pragma clang diagnostic pop
    } else {
        NSLog(@"TFY_PlayerController: reinitializePlayerManagerObserversForPip - 播放器管理器不支持itemObserving方法");
    }
    
    // 手动重新绑定播放结束通知，确保新的PlayerItem能触发回调
    [self manuallySetupPlayerEndNotificationForPip];
}

// 手动设置播放结束通知，确保画中画连续播放正常工作
- (void)manuallySetupPlayerEndNotificationForPip {
    
    // 获取当前的PlayerItem
    AVPlayerItem *currentItem = nil;
    if ([self.currentPlayerManager respondsToSelector:@selector(player)]) {
        AVPlayer *player = [self.currentPlayerManager performSelector:@selector(player)];
        if (player) {
            currentItem = player.currentItem;
        }
    }
    
    if (currentItem) {
        
        // 移除旧的通知（如果有的话）
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:AVPlayerItemDidPlayToEndTimeNotification 
                                                      object:nil];
        
        // 添加新的播放结束通知
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(pipPlayerItemDidPlayToEnd:) 
                                                     name:AVPlayerItemDidPlayToEndTimeNotification 
                                                   object:currentItem];
        
    } else {
        NSLog(@"TFY_PlayerController: manuallySetupPlayerEndNotificationForPip - 警告：无法获取当前PlayerItem");
    }
}

// 画中画专用的播放结束通知处理
- (void)pipPlayerItemDidPlayToEnd:(NSNotification *)notification {
    
    // 检查是否在画中画模式下
    BOOL isPipActive = [self isPictureInPictureActive];

    if (isPipActive) {
        // 检查是否需要处理画中画连续播放
        if (!self.isHandlingPipContinuousPlay) {
            // 第一次开始画中画连续播放
            self.isHandlingPipContinuousPlay = YES;
        }
        
        // 标记画中画是因为播放结束而停止的
        self.pipStoppedDueToPlaybackEnd = YES;
        self.pipRetryCount = 0;
        // 在画中画模式下，直接处理连续播放逻辑
        [self handlePipContinuousPlayback];
    }
}

// 监听新PlayerItem的准备状态
- (void)observeNewPlayerItemForPip:(AVPlayerItem *)playerItem {
    
    // 监听PlayerItem状态
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:TFYPlayerPipItemContext];
    
    // 设置一个标记，避免重复移除观察者
    objc_setAssociatedObject(playerItem, @"isObserving", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 设置超时处理
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            NSNumber *isObserving = objc_getAssociatedObject(playerItem, @"isObserving");            if (isObserving.boolValue) {
                @try {
                    [playerItem removeObserver:strongSelf forKeyPath:@"status" context:TFYPlayerPipItemContext];
                    objc_setAssociatedObject(playerItem, @"isObserving", @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                } @catch (NSException *exception) {
                    NSLog(@"TFY_PlayerController: 超时移除观察者时出现异常: %@", exception.reason);
                }
                
                if (strongSelf.isHandlingPipContinuousPlay) {
                    strongSelf.isHandlingPipContinuousPlay = NO;
                    strongSelf.pipStoppedDueToPlaybackEnd = NO;
                }
            }
        }
    });
}

// 更新播放器管理器的内部状态，确保与新的PlayerItem同步
- (void)updatePlayerManagerStateForPip:(AVPlayerItem *)playerItem {
    
    // 重新设置播放器管理器的观察者和通知（在playerItem引用更新后）
    [self reinitializePlayerManagerObserversForPip];
    
    // 重新设置播放器管理器的回调 - 这是关键！
    [self playerManagerCallbcak];

    // 验证回调是否正确设置
    if (self.currentPlayerManager.playerDidToEnd) {
        NSLog(@"TFY_PlayerController: updatePlayerManagerStateForPip - playerDidToEnd回调已设置");
    } else {
        NSLog(@"TFY_PlayerController: updatePlayerManagerStateForPip - 警告：playerDidToEnd回调未设置！");
    }
    
    // 手动设置播放器管理器的播放状态
    @try {
        NSObject *playerManager = (NSObject *)self.currentPlayerManager;
        [playerManager setValue:@YES forKey:@"isPreparedToPlay"];
        [playerManager setValue:@YES forKey:@"isReadyToPlay"];
       
    } @catch (NSException *exception) {
        NSLog(@"TFY_PlayerController: updatePlayerManagerStateForPip - 设置播放状态失败: %@", exception.reason);
    }
    
    // 触发播放器准备完成的回调
    if (self.currentPlayerManager.playerReadyToPlay) {
        self.currentPlayerManager.playerReadyToPlay(self.currentPlayerManager, self.assetURL);
    }
}



// 监听播放器准备状态用于画中画重启
- (void)observePlayerReadyStateForPip:(NSURL *)assetURL {
    self.pipRetryCount = 0;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPipCheckDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf checkPlayerReadyAndRestartPip];
        }
    });
}

// 检查播放器准备状态并重启画中画
- (void)checkPlayerReadyAndRestartPip {
    
    if (self.currentPlayerManager.isPreparedToPlay || self.currentPlayerManager.playState == PlayerPlayStatePlaying) {
        [self restartPipAfterVideoChange];
    } else {
        self.pipRetryCount++;
        if (self.pipRetryCount < 3) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self checkPlayerReadyAndRestartPip];
            });
        } else {
            [self restartPipAfterVideoChange];
        }
    }
}

- (void)restartPipAfterVideoChange {
    
    // 强制重新创建画中画控制器，但不重置现有的
    objc_setAssociatedObject(self, @selector(pipController), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    // 启动新的画中画
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startPictureInPicture];
        // 标记画中画连续播放处理完成
        self.isHandlingPipContinuousPlay = NO;
        self.pipStoppedDueToPlaybackEnd = NO;
    });
}

// 重写observeValueForKeyPath来处理画中画模式下的PlayerItem状态变化
- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change 
                       context:(void *)context {
    
    if (context == TFYPlayerPipItemContext) {
        if ([keyPath isEqualToString:@"status"]) {
            AVPlayerItem *playerItem = (AVPlayerItem *)object;
            
            if (playerItem.status == AVPlayerItemStatusReadyToPlay) {

                // 安全地移除观察者
                NSNumber *isObserving = objc_getAssociatedObject(playerItem, @"isObserving");
                if (isObserving.boolValue) {
                    @try {
                        [playerItem removeObserver:self forKeyPath:@"status" context:context];
                        objc_setAssociatedObject(playerItem, @"isObserving", @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    } @catch (NSException *exception) {
                        NSLog(@"TFY_PlayerController: 移除观察者时出现异常: %@", exception.reason);
                    }
                }
                
                // 更新播放器管理器的内部状态
                [self updatePlayerManagerStateForPip:playerItem];
                
                // 获取AVPlayer并开始播放
                if ([self.currentPlayerManager respondsToSelector:@selector(player)]) {
                    AVPlayer *player = [self.currentPlayerManager performSelector:@selector(player)];
                    if (player) {
                        [player play];
                    }
                }
                
                // 标记画中画连续播放处理完成，但保持连续播放能力
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPipCheckDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // 不要在这里设置 isHandlingPipContinuousPlay = NO，这会阻止后续的连续播放
                    // 只重置播放结束标志
                    self.pipStoppedDueToPlaybackEnd = NO;
                });
                
            } else if (playerItem.status == AVPlayerItemStatusFailed) {
                
                // 安全地移除观察者
                NSNumber *isObserving = objc_getAssociatedObject(playerItem, @"isObserving");
                if (isObserving.boolValue) {
                    @try {
                        [playerItem removeObserver:self forKeyPath:@"status" context:context];
                        objc_setAssociatedObject(playerItem, @"isObserving", @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    } @catch (NSException *exception) {
                        NSLog(@"TFY_PlayerController: 移除观察者时出现异常: %@", exception.reason);
                    }
                }
                
                // 标记画中画连续播放处理完成
                self.isHandlingPipContinuousPlay = NO;
                self.pipStoppedDueToPlaybackEnd = NO;
            }
        }
    } else {
        // 调用父类方法处理其他情况
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

// 检查是否已经创建了画中画控制器
- (BOOL)hasPipController {
    if (@available(iOS 15.0, *)) {
        return objc_getAssociatedObject(self, @selector(pipController)) != nil;
    }
    return NO;
}

- (void)resetPipController {
    if (@available(iOS 15.0, *)) {
        AVPictureInPictureController *pip = objc_getAssociatedObject(self, @selector(pipController));
        if (pip) {
            pip.delegate = nil;
            objc_setAssociatedObject(self, @selector(pipController), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

- (BOOL)allowOrentitaionRotation {
    NSNumber *value = objc_getAssociatedObject(self, @selector(allowOrentitaionRotation));
    return value ? [value boolValue] : NO;
}

- (BOOL)exitFullScreenWhenStop {
    NSNumber *value = objc_getAssociatedObject(self, @selector(exitFullScreenWhenStop));
    return value ? [value boolValue] : NO;
}

- (UIStatusBarAnimation)fullScreenStatusBarAnimation {
    NSNumber *value = objc_getAssociatedObject(self, @selector(fullScreenStatusBarAnimation));
    return value ? (UIStatusBarAnimation)[value integerValue] : UIStatusBarAnimationSlide;
}

- (UIStatusBarStyle)fullScreenStatusBarStyle {
    NSNumber *value = objc_getAssociatedObject(self, @selector(fullScreenStatusBarStyle));
    return value ? (UIStatusBarStyle)[value integerValue] : UIStatusBarStyleLightContent;
}

- (BOOL)isFullScreen {
    NSNumber *value = objc_getAssociatedObject(self, @selector(isFullScreen));
    return value ? [value boolValue] : NO;
}

- (BOOL)isLockedScreen {
    NSNumber *value = objc_getAssociatedObject(self, @selector(isLockedScreen));
    return value ? [value boolValue] : NO;
}

- (void)setOrientationWillChange:(void (^)(TFY_PlayerController *player, BOOL isFullScreen))orientationWillChange {
    objc_setAssociatedObject(self, @selector(orientationWillChange), orientationWillChange, OBJC_ASSOCIATION_COPY);
}

- (BOOL)shouldAutorotate {
    NSNumber *value = objc_getAssociatedObject(self, @selector(shouldAutorotate));
    return value ? [value boolValue] : YES;
}

- (BOOL)isStatusBarHidden {
    NSNumber *value = objc_getAssociatedObject(self, @selector(isStatusBarHidden));
    return value ? [value boolValue] : NO;
}

- (void (^)(TFY_PlayerController *player, BOOL isFullScreen))orientationDidChanged {
    return objc_getAssociatedObject(self, @selector(orientationDidChanged));
}

// autoStartPiPWhenEnterBackground属性实现
- (void)setAutoStartPiPWhenEnterBackground:(BOOL)autoStartPiPWhenEnterBackground {
    objc_setAssociatedObject(self, @selector(autoStartPiPWhenEnterBackground), @(autoStartPiPWhenEnterBackground), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (BOOL)autoStartPiPWhenEnterBackground {
    NSNumber *value = objc_getAssociatedObject(self, @selector(autoStartPiPWhenEnterBackground));
    return value ? [value boolValue] : NO;
}
// isPictureInPictureActive属性实现
- (BOOL)isPictureInPictureActive {
    return self.pipManager.isPictureInPictureActive;
}
// isPictureInPictureSupported属性实现
- (BOOL)isPictureInPictureSupported {
    return self.pipManager.isPictureInPictureSupported;
}

- (TFY_PlayerPictureInPictureManager *)pipManager {
    return _pipManager;
}

@end

@implementation TFY_PlayerController (PlayerTimeControl)

- (NSTimeInterval)currentTime {
    return self.currentPlayerManager.currentTime;
}

- (NSTimeInterval)totalTime {
    return self.currentPlayerManager.totalTime;
}

- (NSTimeInterval)bufferTime {
    return self.currentPlayerManager.bufferTime;
}

- (float)progress {
    if (self.totalTime == 0) return 0;
    return self.currentTime/self.totalTime;
}

- (float)bufferProgress {
    if (self.totalTime == 0) return 0;
    return self.bufferTime/self.totalTime;
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL))completionHandler {
    [self.currentPlayerManager seekToTime:time completionHandler:completionHandler];
}

@end

@implementation TFY_PlayerController (PlayerPlaybackControl)

- (void)playTheNext {
    // 只有在非画中画连续播放处理状态下且画中画控制器存在时才重置
    if (!self.isHandlingPipContinuousPlay && [self hasPipController]) {
        [self resetPipController];
    }
    
    if (self.assetURLs.count > 0) {
        NSInteger index = self.currentPlayIndex + 1;
        if (index >= self.assetURLs.count) {
            // 如果启用了循环播放，从头开始播放
            if (self.shouldLoopPlay) {
                index = 0;
            } else {
                return; // 不循环播放，停止播放
            }
        }
        NSURL *assetURL = [self.assetURLs objectAtIndex:index];
        self.assetURL = assetURL;
        self.currentPlayIndex = index;
    }
}

- (void)playThePrevious {
    // 只有在非画中画连续播放处理状态下且画中画控制器存在时才重置
    if (!self.isHandlingPipContinuousPlay && [self hasPipController]) {
        [self resetPipController];
    }
    
    if (self.assetURLs.count > 0) {
        NSInteger index = self.currentPlayIndex - 1;
        if (index < 0) {
            // 如果启用了循环播放，从最后一个开始播放
            if (self.shouldLoopPlay) {
                index = self.assetURLs.count - 1;
            } else {
                return; // 不循环播放，停止播放
            }
        }
        NSURL *assetURL = [self.assetURLs objectAtIndex:index];
        self.assetURL = assetURL;
        self.currentPlayIndex = index;
    }
}

- (void)playTheIndex:(NSInteger)index {
    // 只有在非画中画连续播放处理状态下且画中画控制器存在时才重置
    if (!self.isHandlingPipContinuousPlay && [self hasPipController]) {
        [self resetPipController];
    }
    
    if (self.assetURLs.count > 0) {
        if (index >= self.assetURLs.count) return;
        NSURL *assetURL = [self.assetURLs objectAtIndex:index];
        self.assetURL = assetURL;
        self.currentPlayIndex = index;
    }
}

- (void)stop {
    if (self.isFullScreen && self.exitFullScreenWhenStop) {
        @player_weakify(self)
        [self.orientationObserver enterFullScreen:NO animated:NO completion:^{
            @player_strongify(self)
            [self.currentPlayerManager stop];
            [self.currentPlayerManager.view removeFromSuperview];
        }];
    } else {
        [self.currentPlayerManager stop];
        [self.currentPlayerManager.view removeFromSuperview];
    }
    self.lockedScreen = NO;
    if (self.scrollView) self.scrollView.tfy_stopPlay = YES;
    [self.notification removeNotification];
    [self.orientationObserver removeDeviceOrientationObserver];
}

- (void)replaceCurrentPlayerManager:(id<TFY_PlayerMediaPlayback>)playerManager {
    self.currentPlayerManager = playerManager;
}

/// Add video to the cell
- (void)addPlayerViewToCell {
    self.isSmallFloatViewShow = NO;
    self.smallFloatView.hidden = YES;
    UIView *cell = [self.scrollView tfy_getCellForIndexPath:self.playingIndexPath];
    self.containerView = [cell viewWithTag:self.containerViewTag];
    [self.containerView addSubview:self.currentPlayerManager.view];
    self.currentPlayerManager.view.frame = self.containerView.bounds;
    self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if ([self.controlView respondsToSelector:@selector(videoPlayer:floatViewShow:)]) {
        [self.controlView videoPlayer:self floatViewShow:NO];
    }
    [self layoutPlayerSubViews];
}

//// Add video to the container view
- (void)addPlayerViewToContainerView:(UIView *)containerView {
    self.isSmallFloatViewShow = NO;
    self.smallFloatView.hidden = YES;
    self.containerView = containerView;
    [self.containerView addSubview:self.currentPlayerManager.view];
    self.currentPlayerManager.view.frame = self.containerView.bounds;
    self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.orientationObserver updateRotateView:self.currentPlayerManager.view containerView:self.containerView];
    if ([self.controlView respondsToSelector:@selector(videoPlayer:floatViewShow:)]) {
        [self.controlView videoPlayer:self floatViewShow:NO];
    }
}

- (void)addPlayerViewToSmallFloatView {
    self.isSmallFloatViewShow = YES;
    self.smallFloatView.hidden = NO;
    [self.smallFloatView addSubview:self.currentPlayerManager.view];
    self.currentPlayerManager.view.frame = self.smallFloatView.bounds;
    self.currentPlayerManager.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.orientationObserver updateRotateView:self.currentPlayerManager.view containerView:self.smallFloatView];
    if ([self.controlView respondsToSelector:@selector(videoPlayer:floatViewShow:)]) {
        [self.controlView videoPlayer:self floatViewShow:YES];
    }
}

- (void)stopCurrentPlayingView {
    if (self.containerView) {
        [self stop];
        self.isSmallFloatViewShow = NO;
        if (self.smallFloatView) self.smallFloatView.hidden = YES;
    }
}

- (void)stopCurrentPlayingCell {
    if (self.scrollView.tfy_playingIndexPath) {
        [self stop];
        self.isSmallFloatViewShow = NO;
        self.playingIndexPath = nil;
        if (self.smallFloatView) self.smallFloatView.hidden = YES;
    }
}

#pragma mark - getter

- (BOOL)resumePlayRecord {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (NSURL *)assetURL {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSArray<NSURL *> *)assetURLs {
    return objc_getAssociatedObject(self, _cmd);
}

- (BOOL)isLastAssetURL {
    if (self.assetURLs.count > 0) {
        return [self.assetURL isEqual:self.assetURLs.lastObject];
    }
    return NO;
}

- (BOOL)isFirstAssetURL {
    if (self.assetURLs.count > 0) {
        return [self.assetURL isEqual:self.assetURLs.firstObject];
    }
    return NO;
}

- (BOOL)isPauseByEvent {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (float)brightness {
    return [UIScreen mainScreen].brightness;
}

- (float)volume {
    CGFloat volume = self.volumeViewSlider.value;
    if (volume == 0) {
        volume = [[AVAudioSession sharedInstance] outputVolume];
    }
    return volume;
}

- (BOOL)isMuted {
    return self.volume == 0;
}

- (float)lastVolumeValue {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (PlayerPlaybackState)playState {
    return self.currentPlayerManager.playState;
}

- (BOOL)isPlaying {
    return self.currentPlayerManager.isPlaying;
}

- (BOOL)pauseWhenAppResignActive {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.pauseWhenAppResignActive = YES;
    return YES;
}

- (void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, NSURL * _Nonnull))playerPrepareToPlay {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, NSURL * _Nonnull))playerReadyToPlay {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, NSTimeInterval, NSTimeInterval))playerPlayTimeChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, NSTimeInterval))playerBufferTimeChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, PlayerPlaybackState))playerPlayStateChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, PlayerLoadState))playerLoadStateChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<TFY_PlayerMediaPlayback> _Nonnull))playerDidToEnd {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, id _Nonnull))playerPlayFailed {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, CGSize ))presentationSizeChanged {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSInteger)currentPlayIndex {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (BOOL)isViewControllerDisappear {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)customAudioSession {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)shouldLoopPlay {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.shouldLoopPlay = NO;
    return NO;
}

- (BOOL)shouldAutoPlayNext {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.shouldAutoPlayNext = YES;
    return YES;
}

#pragma mark - setter

- (void)setResumePlayRecord:(BOOL)resumePlayRecord {
    objc_setAssociatedObject(self, @selector(resumePlayRecord), @(resumePlayRecord), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setAssetURL:(NSURL *)assetURL {
    // 只有在画中画控制器已存在时才需要重置
    if ([self hasPipController]) {
        [self resetPipController];
    }
    objc_setAssociatedObject(self, @selector(assetURL), assetURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.currentPlayerManager.assetURL = assetURL;
}

- (void)setAssetURLs:(NSArray<NSURL *> * _Nullable)assetURLs {
    objc_setAssociatedObject(self, @selector(assetURLs), assetURLs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setVolume:(float)volume {
    volume = TFYPlayerClampValue(volume, 0.0, 1.0);
    objc_setAssociatedObject(self, @selector(volume), @(volume), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.volumeViewSlider.value = volume;
}

- (void)setMuted:(BOOL)muted {
    if (muted) {
        if (self.volumeViewSlider.value > 0) {
            self.lastVolumeValue = self.volumeViewSlider.value;
        }
        self.volumeViewSlider.value = 0;
    } else {
        self.volumeViewSlider.value = self.lastVolumeValue;
    }
}

- (void)setLastVolumeValue:(float)lastVolumeValue {
    objc_setAssociatedObject(self, @selector(lastVolumeValue), @(lastVolumeValue), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setBrightness:(float)brightness {
    brightness = TFYPlayerClampValue(brightness, 0.0, 1.0);
    objc_setAssociatedObject(self, @selector(brightness), @(brightness), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [UIScreen mainScreen].brightness = brightness;
}

- (void)setPauseByEvent:(BOOL)pauseByEvent {
    objc_setAssociatedObject(self, @selector(isPauseByEvent), @(pauseByEvent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (pauseByEvent) {
        [self.currentPlayerManager pause];
    } else {
        [self.currentPlayerManager play];
    }
}

- (void)setPauseWhenAppResignActive:(BOOL)pauseWhenAppResignActive {
    objc_setAssociatedObject(self, @selector(pauseWhenAppResignActive), @(pauseWhenAppResignActive), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setPlayerPrepareToPlay:(void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, NSURL * _Nonnull))playerPrepareToPlay {
    objc_setAssociatedObject(self, @selector(playerPrepareToPlay), playerPrepareToPlay, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerReadyToPlay:(void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, NSURL * _Nonnull))playerReadyToPlay {
    objc_setAssociatedObject(self, @selector(playerReadyToPlay), playerReadyToPlay, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerPlayTimeChanged:(void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, NSTimeInterval, NSTimeInterval))playerPlayTimeChanged {
    objc_setAssociatedObject(self, @selector(playerPlayTimeChanged), playerPlayTimeChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerBufferTimeChanged:(void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, NSTimeInterval))playerBufferTimeChanged {
    objc_setAssociatedObject(self, @selector(playerBufferTimeChanged), playerBufferTimeChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerPlayStateChanged:(void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, PlayerPlaybackState))playerPlayStateChanged {
    objc_setAssociatedObject(self, @selector(playerPlayStateChanged), playerPlayStateChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerLoadStateChanged:(void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, PlayerLoadState))playerLoadStateChanged {
    objc_setAssociatedObject(self, @selector(playerLoadStateChanged), playerLoadStateChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerDidToEnd:(void (^)(id<TFY_PlayerMediaPlayback> _Nonnull))playerDidToEnd {
    objc_setAssociatedObject(self, @selector(playerDidToEnd), playerDidToEnd, OBJC_ASSOCIATION_COPY);
}

- (void)setPlayerPlayFailed:(void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, id _Nonnull))playerPlayFailed {
    objc_setAssociatedObject(self, @selector(playerPlayFailed), playerPlayFailed, OBJC_ASSOCIATION_COPY);
}

- (void)setPresentationSizeChanged:(void (^)(id<TFY_PlayerMediaPlayback> _Nonnull, CGSize))presentationSizeChanged {
    objc_setAssociatedObject(self, @selector(presentationSizeChanged), presentationSizeChanged, OBJC_ASSOCIATION_COPY);
}

- (void)setCurrentPlayIndex:(NSInteger)currentPlayIndex {
    objc_setAssociatedObject(self, @selector(currentPlayIndex), @(currentPlayIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setViewControllerDisappear:(BOOL)viewControllerDisappear {
    objc_setAssociatedObject(self, @selector(isViewControllerDisappear), @(viewControllerDisappear), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.scrollView) self.scrollView.tfy_viewControllerDisappear = viewControllerDisappear;
    if (!self.currentPlayerManager.isPreparedToPlay) return;
    if (viewControllerDisappear) {
        [self removeDeviceOrientationObserver];
        if (self.currentPlayerManager.isPlaying) self.pauseByEvent = YES;
        if (self.isSmallFloatViewShow) self.smallFloatView.hidden = YES;
    } else {
        [self addDeviceOrientationObserver];
        if (self.isPauseByEvent) self.pauseByEvent = NO;
        if (self.isSmallFloatViewShow) self.smallFloatView.hidden = NO;
    }
}

@end

@implementation TFY_PlayerController (PlayerOrientationRotation)

- (void)addDeviceOrientationObserver {
    if (self.allowOrentitaionRotation) {
        [self.orientationObserver addDeviceOrientationObserver];
    }
}

- (void)removeDeviceOrientationObserver {
    [self.orientationObserver removeDeviceOrientationObserver];
}

/// Enter the fullScreen while the TFY_FullScreenMode is TFY_FullScreenModeLandscape.
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated {
    [self rotateToOrientation:orientation animated:animated completion:nil];
}

/// Enter the fullScreen while the TFY_FullScreenMode is TFY_FullScreenModeLandscape.
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void(^ __nullable)(void))completion {
    self.orientationObserver.fullScreenMode = FullScreenModeLandscape;
    [self.orientationObserver rotateToOrientation:orientation animated:animated completion:completion];
}

- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated completion:(void (^ _Nullable)(void))completion {
    self.orientationObserver.fullScreenMode = FullScreenModePortrait;
    [self.orientationObserver enterPortraitFullScreen:fullScreen animated:animated completion:completion];
}

- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated {
    [self enterPortraitFullScreen:fullScreen animated:animated completion:nil];
}

- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated completion:(void (^ _Nullable)(void))completion {
    if (self.orientationObserver.fullScreenMode == FullScreenModePortrait) {
        [self.orientationObserver enterPortraitFullScreen:fullScreen animated:animated completion:completion];
    } else {
        UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
        orientation = fullScreen? UIInterfaceOrientationLandscapeRight : UIInterfaceOrientationPortrait;
        [self.orientationObserver rotateToOrientation:orientation animated:animated completion:completion];
    }
}

- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated {
    [self enterFullScreen:fullScreen animated:animated completion:nil];
}

#pragma mark - getter

- (TFY_OrientationObserver *)orientationObserver {
    @player_weakify(self)
    TFY_OrientationObserver *orientationObserver = objc_getAssociatedObject(self, _cmd);
    if (!orientationObserver) {
        orientationObserver = [[TFY_OrientationObserver alloc] init];
        orientationObserver.orientationWillChange = ^(TFY_OrientationObserver * _Nonnull observer, BOOL isFullScreen) {
            @player_strongify(self)
            if (self.orientationWillChange) self.orientationWillChange(self, isFullScreen);
            if ([self.controlView respondsToSelector:@selector(videoPlayer:orientationWillChange:)]) {
                [self.controlView videoPlayer:self orientationWillChange:observer];
            }
            [self.controlView setNeedsLayout];
            [self.controlView layoutIfNeeded];
        };
        orientationObserver.orientationDidChanged = ^(TFY_OrientationObserver * _Nonnull observer, BOOL isFullScreen) {
            @player_strongify(self)
            if (self.orientationDidChanged) self.orientationDidChanged(self, isFullScreen);
            if ([self.controlView respondsToSelector:@selector(videoPlayer:orientationDidChanged:)]) {
                [self.controlView videoPlayer:self orientationDidChanged:observer];
            }
        };
        objc_setAssociatedObject(self, _cmd, orientationObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return orientationObserver;
}

- (void (^)(TFY_PlayerController * _Nonnull, BOOL))orientationWillChange {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setOrientationDidChanged:(void (^)(TFY_PlayerController * _Nonnull, BOOL))orientationDidChanged {
    objc_setAssociatedObject(self, @selector(orientationDidChanged), orientationDidChanged, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    objc_setAssociatedObject(self, @selector(isStatusBarHidden), @(statusBarHidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.fullScreenStatusBarHidden = statusBarHidden;
}

- (void)setLockedScreen:(BOOL)lockedScreen {
    objc_setAssociatedObject(self, @selector(isLockedScreen), @(lockedScreen), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.lockedScreen = lockedScreen;
    if ([self.controlView respondsToSelector:@selector(lockedVideoPlayer:lockedScreen:)]) {
        [self.controlView lockedVideoPlayer:self lockedScreen:lockedScreen];
    }
}

- (void)setAllowOrentitaionRotation:(BOOL)allowOrentitaionRotation {
    objc_setAssociatedObject(self, @selector(allowOrentitaionRotation), @(allowOrentitaionRotation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.allowOrientationRotation = allowOrentitaionRotation;
}

- (void)setExitFullScreenWhenStop:(BOOL)exitFullScreenWhenStop {
    objc_setAssociatedObject(self, @selector(exitFullScreenWhenStop), @(exitFullScreenWhenStop), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFullScreenStatusBarStyle:(UIStatusBarStyle)fullScreenStatusBarStyle {
    objc_setAssociatedObject(self, @selector(fullScreenStatusBarStyle), @(fullScreenStatusBarStyle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.fullScreenStatusBarStyle = fullScreenStatusBarStyle;
}

- (void)setFullScreenStatusBarAnimation:(UIStatusBarAnimation)fullScreenStatusBarAnimation {
    objc_setAssociatedObject(self, @selector(fullScreenStatusBarAnimation), @(fullScreenStatusBarAnimation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.orientationObserver.fullScreenStatusBarAnimation = fullScreenStatusBarAnimation;
}

@end

@implementation TFY_PlayerController (PlayerViewGesture)

#pragma mark - getter

- (TFY_PlayerGestureControl *)gestureControl {
    TFY_PlayerGestureControl *gestureControl = objc_getAssociatedObject(self, _cmd);
    if (!gestureControl) {
        gestureControl = [[TFY_PlayerGestureControl alloc] init];
        @player_weakify(self)
        gestureControl.triggerCondition = ^BOOL(TFY_PlayerGestureControl * _Nonnull control, PlayerGestureType type, UIGestureRecognizer * _Nonnull gesture, UITouch *touch) {
            @player_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureTriggerCondition:gestureType:gestureRecognizer:touch:)]) {
                return [self.controlView gestureTriggerCondition:control gestureType:type gestureRecognizer:gesture touch:touch];
            }
            return YES;
        };
        
        gestureControl.singleTapped = ^(TFY_PlayerGestureControl * _Nonnull control) {
            @player_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureSingleTapped:)]) {
                [self.controlView gestureSingleTapped:control];
            }
        };
        
        gestureControl.doubleTapped = ^(TFY_PlayerGestureControl * _Nonnull control) {
            @player_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureDoubleTapped:)]) {
                [self.controlView gestureDoubleTapped:control];
            }
        };
        
        gestureControl.beganPan = ^(TFY_PlayerGestureControl * _Nonnull control, PanDirection direction, PanLocation location) {
            @player_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureBeganPan:panDirection:panLocation:)]) {
                [self.controlView gestureBeganPan:control panDirection:direction panLocation:location];
            }
        };
        
        gestureControl.changedPan = ^(TFY_PlayerGestureControl * _Nonnull control, PanDirection direction, PanLocation location, CGPoint velocity) {
            @player_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureChangedPan:panDirection:panLocation:withVelocity:)]) {
                [self.controlView gestureChangedPan:control panDirection:direction panLocation:location withVelocity:velocity];
            }
        };
        
        gestureControl.endedPan = ^(TFY_PlayerGestureControl * _Nonnull control, PanDirection direction, PanLocation location) {
            @player_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gestureEndedPan:panDirection:panLocation:)]) {
                [self.controlView gestureEndedPan:control panDirection:direction panLocation:location];
            }
        };
        
        gestureControl.pinched = ^(TFY_PlayerGestureControl * _Nonnull control, float scale) {
            @player_strongify(self)
            if ([self.controlView respondsToSelector:@selector(gesturePinched:scale:)]) {
                [self.controlView gesturePinched:control scale:scale];
            }
        };
        
        gestureControl.longPressed = ^(TFY_PlayerGestureControl * _Nonnull control, LongPressGestureRecognizerState state) {
            @player_strongify(self)
            if ([self.controlView respondsToSelector:@selector(longPressed:state:)]) {
                [self.controlView longPressed:control state:state];
            }
        };
        objc_setAssociatedObject(self, _cmd, gestureControl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return gestureControl;
}

- (PlayerDisableGestureTypes)disableGestureTypes {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (PlayerDisablePanMovingDirection)disablePanMovingDirection {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

#pragma mark - setter

- (void)setDisableGestureTypes:(PlayerDisableGestureTypes)disableGestureTypes {
    objc_setAssociatedObject(self, @selector(disableGestureTypes), @(disableGestureTypes), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.gestureControl.disableTypes = disableGestureTypes;
}

- (void)setDisablePanMovingDirection:(PlayerDisablePanMovingDirection)disablePanMovingDirection {
    objc_setAssociatedObject(self, @selector(disablePanMovingDirection), @(disablePanMovingDirection), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.gestureControl.disablePanMovingDirection = disablePanMovingDirection;
}

@end

@implementation TFY_PlayerController (PlayerScrollView)

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {
            NSSelectorFromString(@"dealloc")
        };
        
        for (NSInteger index = 0; index < sizeof(selectors) / sizeof(SEL); ++index) {
            SEL originalSelector = selectors[index];
            SEL swizzledSelector = NSSelectorFromString([@"tfy_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
            Method originalMethod = class_getInstanceMethod(self, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
            if (class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
    });
}

- (void)tfy_dealloc {
    [self.smallFloatView removeFromSuperview];
    self.smallFloatView = nil;
    [self tfy_dealloc];
}

#pragma mark - setter

- (void)setWWANAutoPlay:(BOOL)WWANAutoPlay {
    objc_setAssociatedObject(self, @selector(isWWANAutoPlay), @(WWANAutoPlay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.scrollView) self.scrollView.tfy_WWANAutoPlay = self.isWWANAutoPlay;
}

- (void)setStopWhileNotVisible:(BOOL)stopWhileNotVisible {
    self.scrollView.tfy_stopWhileNotVisible = stopWhileNotVisible;
    objc_setAssociatedObject(self, @selector(stopWhileNotVisible), @(stopWhileNotVisible), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setContainerViewTag:(NSInteger)containerViewTag {
    objc_setAssociatedObject(self, @selector(containerViewTag), @(containerViewTag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.scrollView.tfy_containerViewTag = containerViewTag;
}

- (void)setPlayingIndexPath:(NSIndexPath *)playingIndexPath {
    objc_setAssociatedObject(self, @selector(playingIndexPath), playingIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (playingIndexPath) {
        self.isSmallFloatViewShow = NO;
        if (self.smallFloatView) self.smallFloatView.hidden = YES;
        
        UIView *cell = [self.scrollView tfy_getCellForIndexPath:playingIndexPath];
        self.containerView = [cell viewWithTag:self.containerViewTag];
        [self addDeviceOrientationObserver];
        self.scrollView.tfy_playingIndexPath = playingIndexPath;
        [self layoutPlayerSubViews];
    } else {
        self.scrollView.tfy_playingIndexPath = playingIndexPath;
    }
}

- (void)setShouldAutoPlay:(BOOL)shouldAutoPlay {
    objc_setAssociatedObject(self, @selector(shouldAutoPlay), @(shouldAutoPlay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.scrollView.tfy_shouldAutoPlay = shouldAutoPlay;
}

- (void)setSectionAssetURLs:(NSArray<NSArray<NSURL *> *> * _Nullable)sectionAssetURLs {
    objc_setAssociatedObject(self, @selector(sectionAssetURLs), sectionAssetURLs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setPlayerDisapperaPercent:(CGFloat)playerDisapperaPercent {
    playerDisapperaPercent = TFYPlayerClampValue(playerDisapperaPercent, 0.0, 1.0);
    self.scrollView.tfy_playerDisapperaPercent = playerDisapperaPercent;
    objc_setAssociatedObject(self, @selector(playerDisapperaPercent), @(playerDisapperaPercent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setPlayerApperaPercent:(CGFloat)playerApperaPercent {
    playerApperaPercent = TFYPlayerClampValue(playerApperaPercent, 0.0, 1.0);
    self.scrollView.tfy_playerApperaPercent = playerApperaPercent;
    objc_setAssociatedObject(self, @selector(playerApperaPercent), @(playerApperaPercent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setTfy_playerAppearingInScrollView:(void (^)(NSIndexPath * _Nonnull, CGFloat))tfy_playerAppearingInScrollView {
    objc_setAssociatedObject(self, @selector(tfy_playerAppearingInScrollView), tfy_playerAppearingInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setTfy_playerDisappearingInScrollView:(void (^)(NSIndexPath * _Nonnull, CGFloat))tfy_playerDisappearingInScrollView {
    objc_setAssociatedObject(self, @selector(tfy_playerDisappearingInScrollView), tfy_playerDisappearingInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setTfy_playerDidAppearInScrollView:(void (^)(NSIndexPath * _Nonnull))tfy_playerDidAppearInScrollView {
    objc_setAssociatedObject(self, @selector(tfy_playerDidAppearInScrollView), tfy_playerDidAppearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setTfy_playerWillDisappearInScrollView:(void (^)(NSIndexPath * _Nonnull))tfy_playerWillDisappearInScrollView {
    objc_setAssociatedObject(self, @selector(tfy_playerWillDisappearInScrollView), tfy_playerWillDisappearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setTfy_playerWillAppearInScrollView:(void (^)(NSIndexPath * _Nonnull))tfy_playerWillAppearInScrollView {
    objc_setAssociatedObject(self, @selector(tfy_playerWillAppearInScrollView), tfy_playerWillAppearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setTfy_playerDidDisappearInScrollView:(void (^)(NSIndexPath * _Nonnull))tfy_playerDidDisappearInScrollView {
    objc_setAssociatedObject(self, @selector(tfy_playerDidDisappearInScrollView), tfy_playerDidDisappearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setTfy_playerShouldPlayInScrollView:(void (^)(NSIndexPath * _Nonnull))tfy_playerShouldPlayInScrollView {
    objc_setAssociatedObject(self, @selector(tfy_playerShouldPlayInScrollView), tfy_playerShouldPlayInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setTfy_scrollViewDidEndScrollingCallback:(void (^)(NSIndexPath * _Nonnull))tfy_scrollViewDidEndScrollingCallback {
    objc_setAssociatedObject(self, @selector(tfy_scrollViewDidEndScrollingCallback), tfy_scrollViewDidEndScrollingCallback, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - getter

- (BOOL)isWWANAutoPlay {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)stopWhileNotVisible {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.stopWhileNotVisible = YES;
    return YES;
}

- (NSInteger)containerViewTag {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (NSIndexPath *)playingIndexPath {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSIndexPath *)shouldPlayIndexPath {
    return self.scrollView.tfy_shouldPlayIndexPath;
}

- (NSArray<NSArray<NSURL *> *> *)sectionAssetURLs {
    return objc_getAssociatedObject(self, _cmd);
}

- (BOOL)shouldAutoPlay {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (CGFloat)playerDisapperaPercent {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.floatValue;
    self.playerDisapperaPercent = kDefaultPlayerDisapperaPercent;
    return kDefaultPlayerDisapperaPercent;
}

- (CGFloat)playerApperaPercent {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.floatValue;
    self.playerApperaPercent = kDefaultPlayerApperaPercent;
    return kDefaultPlayerApperaPercent;
}

- (void (^)(NSIndexPath * _Nonnull, CGFloat))tfy_playerAppearingInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull, CGFloat))tfy_playerDisappearingInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))tfy_playerDidAppearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))tfy_playerWillDisappearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))tfy_playerWillAppearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))tfy_playerDidDisappearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))tfy_playerShouldPlayInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))tfy_scrollViewDidEndScrollingCallback {
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - Public method

- (void)tfy_filterShouldPlayCellWhileScrolled:(void (^ __nullable)(NSIndexPath *indexPath))handler {
    [self.scrollView tfy_filterShouldPlayCellWhileScrolled:handler];
}

- (void)tfy_filterShouldPlayCellWhileScrolling:(void (^ __nullable)(NSIndexPath *indexPath))handler {
    [self.scrollView tfy_filterShouldPlayCellWhileScrolling:handler];
}

- (void)playTheIndexPath:(NSIndexPath *)indexPath {
    self.playingIndexPath = indexPath;
    NSURL *assetURL;
    if (self.sectionAssetURLs.count) {
        assetURL = self.sectionAssetURLs[indexPath.section][indexPath.row];
    } else if (self.assetURLs.count) {
        assetURL = self.assetURLs[indexPath.row];
        self.currentPlayIndex = indexPath.row;
    }
    self.assetURL = assetURL;
}


- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollPosition:(PlayerScrollViewScrollPosition)scrollPosition animated:(BOOL)animated {
    [self playTheIndexPath:indexPath scrollPosition:scrollPosition animated:animated completionHandler:nil];
}

- (void)playTheIndexPath:(NSIndexPath *)indexPath scrollPosition:(PlayerScrollViewScrollPosition)scrollPosition animated:(BOOL)animated completionHandler:(void (^ __nullable)(void))completionHandler {
    NSURL *assetURL;
    if (self.sectionAssetURLs.count) {
        assetURL = self.sectionAssetURLs[indexPath.section][indexPath.row];
    } else if (self.assetURLs.count) {
        assetURL = self.assetURLs[indexPath.row];
        self.currentPlayIndex = indexPath.row;
    }
    @player_weakify(self)
    [self.scrollView tfy_scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated completionHandler:^{
        @player_strongify(self)
        if (completionHandler) completionHandler();
        self.playingIndexPath = indexPath;
        self.assetURL = assetURL;
    }];
}


- (void)playTheIndexPath:(NSIndexPath *)indexPath assetURL:(NSURL *)assetURL {
    self.playingIndexPath = indexPath;
    self.assetURL = assetURL;
}


- (void)playTheIndexPath:(NSIndexPath *)indexPath
                assetURL:(NSURL *)assetURL
          scrollPosition:(PlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated {
    [self playTheIndexPath:indexPath assetURL:assetURL scrollPosition:scrollPosition animated:animated completionHandler:nil];
}


- (void)playTheIndexPath:(NSIndexPath *)indexPath
                assetURL:(NSURL *)assetURL
          scrollPosition:(PlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated
       completionHandler:(void (^ __nullable)(void))completionHandler {
    @player_weakify(self)
    [self.scrollView tfy_scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated completionHandler:^{
        @player_strongify(self)
        if (completionHandler) completionHandler();
        self.playingIndexPath = indexPath;
        self.assetURL = assetURL;
    }];
}

@end

#pragma mark - PlayerPictureInPicture
@implementation TFY_PlayerController (PlayerPictureInPicture)

#pragma mark - Picture In Picture Methods

- (BOOL)startPictureInPicture {
    return [self.pipManager startPictureInPicture];
}

- (void)stopPictureInPicture {
    [self.pipManager stopPictureInPicture];
}

- (NSTimeInterval)lastPipStartTime {
    NSNumber *value = objc_getAssociatedObject(self, @selector(lastPipStartTime));
    return value ? [value doubleValue] : 0;
}

- (void)setLastPipStartTime:(NSTimeInterval)lastPipStartTime {
    objc_setAssociatedObject(self, @selector(lastPipStartTime), @(lastPipStartTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AVPictureInPictureController *)pipController {
    if (@available(iOS 15.0, *)) {
        return objc_getAssociatedObject(self, @selector(pipController));
    }
    return nil;
}

- (void)setPipController:(AVPictureInPictureController *)pipController {
    if (@available(iOS 15.0, *)) {
        objc_setAssociatedObject(self, @selector(pipController), pipController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - Picture In Picture Properties

- (void)setEnablePictureInPicture:(BOOL)enablePictureInPicture {
    self.pipManager.enablePictureInPicture = enablePictureInPicture;
}

- (BOOL)enablePictureInPicture {
    return self.pipManager.enablePictureInPicture;
}

- (void)setEnablePipContinuousPlay:(BOOL)enablePipContinuousPlay {
    objc_setAssociatedObject(self, @selector(enablePipContinuousPlay), @(enablePipContinuousPlay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.pipManager.enableContinuousPlayback = enablePipContinuousPlay;
}

- (BOOL)enablePipContinuousPlay {
    NSNumber *value = objc_getAssociatedObject(self, @selector(enablePipContinuousPlay));
    if (value) {
        return [value boolValue];
    }
    return self.pipManager.enableContinuousPlayback;
}

- (void)setPipWillStart:(void (^)(TFY_PlayerController *))pipWillStart {
    objc_setAssociatedObject(self, @selector(pipWillStart), pipWillStart, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(TFY_PlayerController *))pipWillStart {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPipDidStart:(void (^)(TFY_PlayerController *))pipDidStart {
    objc_setAssociatedObject(self, @selector(pipDidStart), pipDidStart, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(TFY_PlayerController *))pipDidStart {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPipWillStop:(void (^)(TFY_PlayerController *))pipWillStop {
    objc_setAssociatedObject(self, @selector(pipWillStop), pipWillStop, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(TFY_PlayerController *))pipWillStop {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPipDidStop:(void (^)(TFY_PlayerController *))pipDidStop {
    objc_setAssociatedObject(self, @selector(pipDidStop), pipDidStop, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(TFY_PlayerController *))pipDidStop {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPipFailedToStart:(void (^)(TFY_PlayerController *, NSError *))pipFailedToStart {
    objc_setAssociatedObject(self, @selector(pipFailedToStart), pipFailedToStart, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(TFY_PlayerController *, NSError *))pipFailedToStart {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPipRestoreUserInterface:(void (^)(TFY_PlayerController *, void(^)(BOOL)))pipRestoreUserInterface {
    objc_setAssociatedObject(self, @selector(pipRestoreUserInterface), pipRestoreUserInterface, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(TFY_PlayerController *, void(^)(BOOL)))pipRestoreUserInterface {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPipRequestNextAssetURL:(NSURL * _Nullable (^)(TFY_PlayerController *))pipRequestNextAssetURL {
    objc_setAssociatedObject(self, @selector(pipRequestNextAssetURL), pipRequestNextAssetURL, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSURL * _Nullable (^)(TFY_PlayerController *))pipRequestNextAssetURL {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setPipStoppedDueToPlaybackEnd:(BOOL)pipStoppedDueToPlaybackEnd {
    objc_setAssociatedObject(self, @selector(pipStoppedDueToPlaybackEnd), @(pipStoppedDueToPlaybackEnd), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)pipStoppedDueToPlaybackEnd {
    NSNumber *value = objc_getAssociatedObject(self, @selector(pipStoppedDueToPlaybackEnd));
    return value ? [value boolValue] : NO;
}

- (void)setIsHandlingPipContinuousPlay:(BOOL)isHandlingPipContinuousPlay {
    objc_setAssociatedObject(self, @selector(isHandlingPipContinuousPlay), @(isHandlingPipContinuousPlay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isHandlingPipContinuousPlay {
    NSNumber *value = objc_getAssociatedObject(self, @selector(isHandlingPipContinuousPlay));
    return value ? [value boolValue] : NO;
}

- (void)setPipRetryCount:(NSInteger)pipRetryCount {
    objc_setAssociatedObject(self, @selector(pipRetryCount), @(pipRetryCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)pipRetryCount {
    NSNumber *value = objc_getAssociatedObject(self, @selector(pipRetryCount));
    return value ? [value integerValue] : 0;
}

#pragma mark - TFYPictureInPictureManagerDelegate

- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager willStartPictureInPicture:(AVPictureInPictureController *)pipController {
    if (self.pipWillStart) {
        self.pipWillStart(self);
    }
}

- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager didStartPictureInPicture:(AVPictureInPictureController *)pipController {
    if (self.pipDidStart) {
        self.pipDidStart(self);
    }
}

- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager willStopPictureInPicture:(AVPictureInPictureController *)pipController {
    if (self.pipWillStop) {
        self.pipWillStop(self);
    }
}

- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager didStopPictureInPicture:(AVPictureInPictureController *)pipController {
    if (self.pipDidStop) {
        self.pipDidStop(self);
    }
}

- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager failedToStartWithError:(NSError *)error {
    if (self.pipFailedToStart) {
        self.pipFailedToStart(self, error);
    }
}

- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager 
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL restored))completionHandler {
    if (self.pipRestoreUserInterface) {
        self.pipRestoreUserInterface(self, completionHandler);
    } else {
        if (completionHandler) {
            completionHandler(NO);
        }
    }
}

- (void)pictureInPictureManager:(TFY_PlayerPictureInPictureManager *)manager didChangeState:(TFYPipState)state {
    NSLog(@"TFY_PlayerController: 画中画状态变更为: %ld", (long)state);
}

- (NSURL * _Nullable)pictureInPictureManagerRequestNextAssetURL:(TFY_PlayerPictureInPictureManager *)manager {
    if (self.pipRequestNextAssetURL) {
        return self.pipRequestNextAssetURL(self);
    }
    
    // 默认逻辑：如果有assetURLs数组，自动播放下一个
    if (self.assetURLs && self.assetURLs.count > 0) {
        NSInteger nextIndex = self.currentPlayIndex + 1;
        if (nextIndex < self.assetURLs.count) {
            return self.assetURLs[nextIndex];
        }
    }
    return nil;
}

- (void)pictureInPictureManagerDidCompleteContinuousPlayback:(TFY_PlayerPictureInPictureManager *)manager {
    NSLog(@"TFY_PlayerController: 画中画连续播放完成");
}


@end

@implementation TFY_PlayerController (PlayerPerformance)

- (NSDictionary *)getPerformanceStats {
    TFY_PlayerPerformanceOptimizer *optimizer = [TFY_PlayerPerformanceOptimizer sharedOptimizer];
    NSMutableDictionary *stats = [[optimizer getPerformanceStats] mutableCopy];
    
    // 添加播放器特定的统计信息
    stats[@"isPlaying"] = @(self.currentPlayerManager.isPlaying);
    stats[@"currentTime"] = @(self.currentPlayerManager.currentTime);
    stats[@"totalTime"] = @(self.currentPlayerManager.totalTime);
    stats[@"bufferTime"] = @(self.currentPlayerManager.bufferTime);
    stats[@"loadState"] = @(self.currentPlayerManager.loadState);
    
    return [stats copy];
}

- (void)clearPlayerCache {
    // 清理播放记录缓存
    [_tfyPlayRecords removeAllObjects];
    
    // 清理性能优化器缓存
    TFY_PlayerPerformanceOptimizer *optimizer = [TFY_PlayerPerformanceOptimizer sharedOptimizer];
    [optimizer clearAllCaches];
}

- (void)triggerMemoryCleanup {
    // 手动触发内存清理
    TFY_PlayerPerformanceOptimizer *optimizer = [TFY_PlayerPerformanceOptimizer sharedOptimizer];
    [optimizer clearMemoryCache];
    
    // 清理播放器缓存
    [self.playerCache removeAllObjects];
}

@end

#pragma mark - Player Cache Management

@implementation TFY_PlayerController (PlayerCache)

// 缓存播放器状态
- (void)cachePlayerState {
    if (!self.currentPlayerManager.assetURL) return;
    
    NSMutableDictionary *state = [NSMutableDictionary dictionary];
    state[@"isPlaying"] = @(self.currentPlayerManager.isPlaying);
    state[@"currentTime"] = @(self.currentPlayerManager.currentTime);
    state[@"totalTime"] = @(self.currentPlayerManager.totalTime);
    state[@"bufferTime"] = @(self.currentPlayerManager.bufferTime);
    state[@"loadState"] = @(self.currentPlayerManager.loadState);
    state[@"playState"] = @(self.currentPlayerManager.playState);
    state[@"presentationSize"] = [NSValue valueWithCGSize:self.currentPlayerManager.presentationSize];
    
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", kPlayerStateCacheKey, self.currentPlayerManager.assetURL.absoluteString];
    [self.playerCache setObject:state forKey:cacheKey cost:5];
}

// 获取缓存的播放器状态
- (NSDictionary *)getCachedPlayerState {
    if (!self.currentPlayerManager.assetURL) return nil;
    
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", kPlayerStateCacheKey, self.currentPlayerManager.assetURL.absoluteString];
    return [self.playerCache objectForKey:cacheKey];
}

// 缓存播放器配置
- (void)cachePlayerConfig {
    NSMutableDictionary *config = [NSMutableDictionary dictionary];
    config[@"volume"] = @(self.volume);
    config[@"brightness"] = @(self.brightness);
    config[@"muted"] = @(self.isMuted);
    config[@"shouldAutoPlayNext"] = @(self.shouldAutoPlayNext);
    config[@"shouldLoopPlay"] = @(self.shouldLoopPlay);
    config[@"pauseWhenAppResignActive"] = @(self.pauseWhenAppResignActive);
    
    [self.playerCache setObject:config forKey:kPlayerConfigCacheKey cost:3];
}

// 获取缓存的播放器配置
- (NSDictionary *)getCachedPlayerConfig {
    return [self.playerCache objectForKey:kPlayerConfigCacheKey];
}

// 应用缓存的配置
- (void)applyCachedPlayerConfig {
    NSDictionary *config = [self getCachedPlayerConfig];
    if (config) {
        if (config[@"volume"]) self.volume = [config[@"volume"] floatValue];
        if (config[@"brightness"]) self.brightness = [config[@"brightness"] floatValue];
        if (config[@"muted"]) self.muted = [config[@"muted"] boolValue];
        if (config[@"shouldAutoPlayNext"]) self.shouldAutoPlayNext = [config[@"shouldAutoPlayNext"] boolValue];
        if (config[@"shouldLoopPlay"]) self.shouldLoopPlay = [config[@"shouldLoopPlay"] boolValue];
        if (config[@"pauseWhenAppResignActive"]) self.pauseWhenAppResignActive = [config[@"pauseWhenAppResignActive"] boolValue];
    }
}

// 缓存时间转换结果
- (NSString *)cachedTimeString:(NSTimeInterval)time {
    // 简单缓存实现，实际可根据需求优化
    static NSCache *timeCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeCache = [[NSCache alloc] init];
    });
    NSString *key = [NSString stringWithFormat:@"%.0f", time];
    NSString *cached = [timeCache objectForKey:key];
    if (cached) return cached;
    NSInteger totalSeconds = (NSInteger)time;
    NSInteger hours = totalSeconds / 3600;
    NSInteger minutes = (totalSeconds % 3600) / 60;
    NSInteger seconds = totalSeconds % 60;
    NSString *result = hours > 0 ? [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds] : [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
    [timeCache setObject:result forKey:key];
    return result;
}

@end


