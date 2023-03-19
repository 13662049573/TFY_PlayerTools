//
//  TFY_PlayerController.h
//  TFY_PlayerView
//
//  Created by 田风有 on 2019/6/30.
//  Copyright © 2019 田风有. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "TFY_PlayerMediaPlayback.h"
#import "TFY_OrientationObserver.h"
#import "TFY_PlayerMediaControl.h"
#import "TFY_PlayerGestureControl.h"
#import "TFY_PlayerNotification.h"
#import "TFY_FloatView.h"
#import "UIScrollView+TFY_Player.h"

NS_ASSUME_NONNULL_BEGIN

@interface TFY_PlayerController : NSObject

/**
 *  你需要适合的控制器，或者默认图片View
 */
@property (nonatomic, strong) UIView *containerView;
/**
 *  currentPlayerManager必须符合`TFY_PlayerMediaPlayback`协议。
 */
@property (nonatomic, strong) id<TFY_PlayerMediaPlayback> currentPlayerManager;

/**
 * 自定义controlView必须符合`TFY_PlayerMediaControl`协议。
 */
@property (nonatomic, strong) UIView<TFY_PlayerMediaControl> *controlView;

/**
 *  通知管理器类
 */
@property (nonatomic, strong, readonly) TFY_PlayerNotification *notification;

/**
 * 容器视图类型。
 */
@property (nonatomic, assign, readonly) PlayerContainerType containerType;

/**
 *  播放的小容器视图。
 */
@property (nonatomic, strong, readonly) TFY_FloatView *smallFloatView;

/**
 *  是否显示小窗口。
 */
@property (nonatomic, assign, readonly) BOOL isSmallFloatViewShow;

/// 滚动视图是tableView或collectionView。
@property (nonatomic, weak, nullable) UIScrollView *scrollView;

/*!
 playerWithPlayerManager: containerView:
 创建一个TFY_PlayerController来播放一个单独的视听项目。
 playerManager必须符合“TFY_PlayerMediaPlayback”协议。
 containerView查看视频帧必须设置containerView。
 tfyPlayerController的实例。
 */
+ (instancetype)playerWithPlayerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerView:(UIView *)containerView;

/*!
 initWithPlayerManager: containerView:
 创建一个TFY_PlayerController来播放一个单独的视听项目。
 playerManager必须符合“tfyPlayerMediaPlayback”协议。
 containerView查看视频帧必须设置containerView。
 tfyPlayerController的实例。
 */
- (instancetype)initWithPlayerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerView:(UIView *)containerView;

/*!
 playerWithScrollView: playerManager: containerViewTag:
 创建一个TFY_PlayerController来播放一个单独的视听项目。在' UITableView '或' UICollectionView '中使用。
 scrollView是tableView或collectionView。
 playerManager必须符合“TFY_PlayerMediaPlayback”协议。
 要在scrollView查看视频，必须设置containerViewTag。
 tfyPlayerController的实例。
 */
+ (instancetype)playerWithScrollView:(UIScrollView *)scrollView playerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag;

/*!
  initWithScrollView: playerManager: containerViewTag:
 创建一个TFY_PlayerController来播放一个单独的视听项目。在' UITableView '或' UICollectionView '中使用。
 scrollView是tableView或collectionView。
 playerManager必须符合“TFY_PlayerMediaPlayback”协议。
 要在scrollView查看视频，必须设置containerViewTag。
 tfyPlayerController的实例。
 */
- (instancetype)initWithScrollView:(UIScrollView *)scrollView playerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerViewTag:(NSInteger)containerViewTag;

/*!
 playerWithScrollView: playerManager: containerView:
 创建一个TFY_PlayerController来播放一个单独的视听项目。在' UIScrollView '中使用。playerManager必须符合“TFY_PlayerMediaPlayback”协议。在scrollView中查看视频。
 tfyPlayerController的实例。
 */
+ (instancetype)playerWithScrollView:(UIScrollView *)scrollView playerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerView:(UIView *)containerView;

/*!
 initWithScrollView: playerManager: containerView:
 创建一个TFY_PlayerController来播放一个单独的视听项目。在' UIScrollView '中使用。playerManager必须符合“TFY_PlayerMediaPlayback”协议。在scrollView中查看视频。
 tfyPlayerController的实例。
 */
- (instancetype)initWithScrollView:(UIScrollView *)scrollView playerManager:(id<TFY_PlayerMediaPlayback>)playerManager containerView:(UIView *)containerView;

@end

@interface TFY_PlayerController (PlayerTimeControl)

/// 玩家当前的游戏时间。
@property (nonatomic, readonly) NSTimeInterval currentTime;

/// 玩家总时间。
@property (nonatomic, readonly) NSTimeInterval totalTime;

/// 玩家缓冲时间。
@property (nonatomic, readonly) NSTimeInterval bufferTime;

/// 玩家进程，0…1
@property (nonatomic, readonly) float progress;

/// 玩家bufferProgress, 0…1
@property (nonatomic, readonly) float bufferProgress;

/**
 使用此方法查找当前播放器的指定时间，并在查找操作完成时收到通知。

 时过境迁。
 completionHandler完成处理程序。
 */
- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^ __nullable)(BOOL finished))completionHandler;

@end

@interface TFY_PlayerController (PlayerPlaybackControl)

///恢复播放记录。
///内存存储回放记录。
@property (nonatomic, assign) BOOL resumePlayRecord;

/// 0 --1.0
///只影响设备实例的音频音量，不影响播放器。
///您可以根据需要更改设备音量或播放器音量，更改播放器音量您可以遵循' tfyPlayerMediaPlayback '协议。
@property (nonatomic) float volume;

///设备静音。
///只影响设备实例的音频静音，不影响播放器。
///您可以根据需要更改设备静音或播放器静音，更改播放器静音可以遵循' tfyPlayerMediaPlayback '协议。
@property (nonatomic, getter=isMuted) BOOL muted;

//0…1.0，其中1.0是最大亮度。仅主界面支持。
@property (nonatomic) float brightness;

/// 播放资产URL。
@property (nonatomic, nullable) NSURL *assetURL;

///如果tableView或collectionView只有一个section，使用' assetURLs '。
///如果tableView或collectionView有更多的section，使用' sectionAssetURLs '。
///设置这个你可以使用' playthennext ' ' playThePrevious ' ' playTheIndex: '方法。
@property (nonatomic, copy, nullable) NSArray <NSURL *>*assetURLs;

/// 当前播放的索引，仅限于一维数组。
@property (nonatomic) NSInteger currentPlayIndex;

/// is the first asset URL in `assetURLs`.
@property (nonatomic, readonly) BOOL isLastAssetURL;

/// is the first asset URL in `assetURLs`.
@property (nonatomic, readonly) BOOL isFirstAssetURL;

///如果是，播放器将被调用pause方法当收到' UIApplicationWillResignActiveNotification '通知。
/// default为YES。
@property (nonatomic) BOOL pauseWhenAppResignActive;

///当播放器播放时，它被一些事件暂停，而不是由用户点击暂停。
///例如，当播放器播放时，应用程序进入后台或推到另一个viewController
@property (nonatomic, getter=isPauseByEvent) BOOL pauseByEvent;

///当前的播放器控制器是消失，而不是dealloc
@property (nonatomic, getter=isViewControllerDisappear) BOOL viewControllerDisappear;

/// 你可以自定义AVAudioSession，
/// default为NO。
@property (nonatomic, assign) BOOL customAudioSession;

/// 当玩家在准备游戏时调用的块。
@property (nonatomic, copy, nullable) void(^playerPrepareToPlay)(id<TFY_PlayerMediaPlayback> asset, NSURL *assetURL);

/// 当玩家准备好游戏时调用的块。
@property (nonatomic, copy, nullable) void(^playerReadyToPlay)(id<TFY_PlayerMediaPlayback> asset, NSURL *assetURL);

/// 当玩家游戏进程改变时调用的块。
@property (nonatomic, copy, nullable) void(^playerPlayTimeChanged)(id<TFY_PlayerMediaPlayback> asset, NSTimeInterval currentTime, NSTimeInterval duration);

/// 当播放器播放缓冲区改变时调用的块。
@property (nonatomic, copy, nullable) void(^playerBufferTimeChanged)(id<TFY_PlayerMediaPlayback> asset, NSTimeInterval bufferTime);

/// 当播放器回放状态改变时调用的块。
@property (nonatomic, copy, nullable) void(^playerPlayStateChanged)(id<TFY_PlayerMediaPlayback> asset, PlayerPlaybackState playState);

/// 当播放器加载状态改变时调用的块。
@property (nonatomic, copy, nullable) void(^playerLoadStateChanged)(id<TFY_PlayerMediaPlayback> asset, PlayerLoadState loadState);

/// 当播放器播放失败时调用的块。
@property (nonatomic, copy, nullable) void(^playerPlayFailed)(id<TFY_PlayerMediaPlayback> asset, id error);

/// 当播放器播放结束时调用的块。
@property (nonatomic, copy, nullable) void(^playerDidToEnd)(id<TFY_PlayerMediaPlayback> asset);

// 当视频大小改变时调用的块。
@property (nonatomic, copy, nullable) void(^presentationSizeChanged)(id<TFY_PlayerMediaPlayback> asset, CGSize size);

/**
 播放下一个url，而' assetURLs '不是NULL。
 */
- (void)playTheNext;

/**
 播放之前的url，而' assetURLs '不是NULL。
 */
- (void)playThePrevious;

/**
 播放url的索引，而' assetURLs '不是NULL。
 指数玩指数。
 */
- (void)playTheIndex:(NSInteger)index;

/**
 播放器停止和playerView从超级视图删除，删除其他通知。
 */
- (void)stop;

/*!
 replaceCurrentPlayerManager:
 将玩家当前的玩家管理器替换为指定的玩家项目。管理器必须符合' tfyPlayerMediaPlayback '协议
 将成为玩家当前玩家管理器的playerManager。
 */
- (void)replaceCurrentPlayerManager:(id<TFY_PlayerMediaPlayback>)manager;

/**
 添加视频到单元格。
 */
- (void)addPlayerViewToCell;

/**
 向容器视图添加视频。
 */
- (void)addPlayerViewToContainerView:(UIView *)containerView;

/**
 添加到小浮动视图。
 */
- (void)addPlayerViewToSmallFloatView;

/**
 停止当前播放的视频并删除playerView。
 */
- (void)stopCurrentPlayingView;

/**
 停止当前在单元格上播放的视频。
 */
- (void)stopCurrentPlayingCell;

@end

@interface TFY_PlayerController (PlayerOrientationRotation)

@property (nonatomic, readonly) TFY_OrientationObserver *orientationObserver;

///是否支持屏幕自动旋转
///取值为NO。
///该属性用于UIViewController的shouldautoroate方法的返回值。
@property (nonatomic, readonly) BOOL shouldAutorotate;

///是否允许视频方向旋转。
///默认是YES..
@property (nonatomic) BOOL allowOrentitaionRotation;

///当tfyFullScreenMode为tfyFullScreenModeLandscape时，朝向为庭园左或庭园右，此值为YES。
///当tfyFullScreenMode为tfyFullScreenModePortrait时，当玩家fullscene时，此值为YES。
@property (nonatomic, readonly) BOOL isFullScreen;

/// 当调用' stop '方法时，退出fullScreen模型，默认为YES。
@property (nonatomic, assign) BOOL exitFullScreenWhenStop;

/// 锁定屏幕方向。
@property (nonatomic, getter=isLockedScreen) BOOL lockedScreen;

/// The block invoked When player will rotate.
@property (nonatomic, copy, nullable) void(^orientationWillChange)(TFY_PlayerController *player, BOOL isFullScreen);

/// 当玩家旋转时，方块被调用。
@property (nonatomic, copy, nullable) void(^orientationDidChanged)(TFY_PlayerController *player, BOOL isFullScreen);

/// 默认是UIStatusBarStyleLightContent。
@property (nonatomic, assign) UIStatusBarStyle fullScreenStatusBarStyle;

/// defalut是UIStatusBarAnimationSlide。
@property (nonatomic, assign) UIStatusBarAnimation fullScreenStatusBarAnimation;

/// 全屏状态栏隐藏。
@property (nonatomic, getter=isStatusBarHidden) BOOL statusBarHidden;

/**
 添加设备方向观测器。
 */
- (void)addDeviceOrientationObserver;

/**
 移除设备方向观测器。
 */
- (void)removeDeviceOrientationObserver;

/**
 当tfyFullScreenMode为tfyFullScreenModeLandscape时，进入fullScreen。

 orientation是UIInterfaceOrientation。
 动画就是动画。
*/
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated;

/**
 当tfyFullScreenMode为tfyFullScreenModeLandscape时，进入fullScreen。

 orientation是UIInterfaceOrientation。
 动画就是动画。
 完成旋转已完成的回调。
*/
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void(^ __nullable)(void))completion;

/**
 当tfyFullScreenMode为tfyFullScreenModePortrait时，进入fullScreen。

 fullScreen是全屏。
 动画就是动画。
 完成旋转已完成的回调。
 */
- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated completion:(void(^ __nullable)(void))completion;

/**
 当tfyFullScreenMode为tfyFullScreenModePortrait时，进入fullScreen。

 fullScreen是全屏。
 动画就是动画。
 */
- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

/**
 全屏模式由tfyFullScreenMode决定。

 fullScreen是全屏。
 动画就是动画。
 完成旋转已完成的回调。
 */
- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated completion:(void(^ __nullable)(void))completion;

/**
 全屏模式由tfyFullScreenMode决定。

 fullScreen是全屏。
 动画就是动画。
 */
- (void)enterFullScreen:(BOOL)fullScreen animated:(BOOL)animated;

@end

@interface TFY_PlayerController (PlayerViewGesture)

/// An instance of tfyPlayerGestureControl.
@property (nonatomic, readonly) TFY_PlayerGestureControl *gestureControl;

/// The gesture types that the player not support.
@property (nonatomic, assign) PlayerDisableGestureTypes disableGestureTypes;

/// The pan gesture moving direction that the player not support.
@property (nonatomic) PlayerDisablePanMovingDirection disablePanMovingDirection;

@end

@interface TFY_PlayerController (PlayerScrollView)

/// scrollView播放器应该自动播放，默认是YES。
@property (nonatomic) BOOL shouldAutoPlay;

/// WWAN网络自动播放，只支持在scrollView模式下' shouldAutoPlay '为YES时，默认为NO。
@property (nonatomic, getter=isWWANAutoPlay) BOOL WWANAutoPlay;

/// indexPath正在播放。
@property (nonatomic, readonly, nullable) NSIndexPath *playingIndexPath;

/// 滚动时应该播放indexPath。
@property (nonatomic, readonly, nullable) NSIndexPath *shouldPlayIndexPath;

/// 播放器在scrollView中显示的视图标签。
@property (nonatomic, readonly) NSInteger containerViewTag;

/// 当前播放的单元格在单元格退出屏幕时停止播放，默认为YES。
@property (nonatomic) BOOL stopWhileNotVisible;

/**
 当前玩家滚动滑出屏幕的百分比。
 ' stopWhileNotVisible '为YES时使用的属性，停止当前播放的播放器。
 ' stopWhileNotVisible '为NO时使用的属性，当前播放的播放器添加到小容器视图。
 范围为0.0~1.0，默认值为0.5。
 0.0表示玩家将消失。
 1.0是玩家消失了。
 */
@property (nonatomic) CGFloat playerDisapperaPercent;

/**
 当前播放器滚动到屏幕百分比来播放视频。
 范围为0.0~1.0，默认值为0.0。
 0.0表示玩家将会出现。
 1.0是玩家确实出现了。
 */
@property (nonatomic) CGFloat playerApperaPercent;

/// 如果tableView或collectionView有更多的section，使用' sectionAssetURLs '。
@property (nonatomic, copy, nullable) NSArray <NSArray <NSURL *>*>*sectionAssetURLs;

/// 当玩家出现时，方块被调用。
@property (nonatomic, copy, nullable) void(^tfy_playerAppearingInScrollView)(NSIndexPath *indexPath, CGFloat playerApperaPercent);

/// 当玩家消失时，方块被调用。
@property (nonatomic, copy, nullable) void(^tfy_playerDisappearingInScrollView)(NSIndexPath *indexPath, CGFloat playerDisapperaPercent);

/// 当玩家出现时，块被调用。
@property (nonatomic, copy, nullable) void(^tfy_playerWillAppearInScrollView)(NSIndexPath *indexPath);

/// 当玩家出现时，方块被调用。
@property (nonatomic, copy, nullable) void(^tfy_playerDidAppearInScrollView)(NSIndexPath *indexPath);

/// 当玩家消失时调用的块。
@property (nonatomic, copy, nullable) void(^tfy_playerWillDisappearInScrollView)(NSIndexPath *indexPath);

/// 当玩家消失时，方块被调用。
@property (nonatomic, copy, nullable) void(^tfy_playerDidDisappearInScrollView)(NSIndexPath *indexPath);

/// 当玩家应该游戏时调用的块。
@property (nonatomic, copy, nullable) void(^tfy_playerShouldPlayInScrollView)(NSIndexPath *indexPath);

/// 当玩家停止滚动时，方块被调用。
@property (nonatomic, copy, nullable) void(^tfy_scrollViewDidEndScrollingCallback)(NSIndexPath *indexPath);

/// 筛选当滚动停止时应该播放的单元格(当滚动停止时播放)。
- (void)tfy_filterShouldPlayCellWhileScrolled:(void (^ __nullable)(NSIndexPath *indexPath))handler;

/// 在滚动时过滤应该播放的单元格(您可以使用此功能来过滤突出显示的单元格)。
- (void)tfy_filterShouldPlayCellWhileScrolling:(void (^ __nullable)(NSIndexPath *indexPath))handler;

/**
 播放没有滚动位置的url的indexPath，而' assetURLs '或' sectionAssetURLs '不是NULL。
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath;

/**
 播放url的indexPath，而' assetURLs '或' sectionAssetURLs '不是NULL。

 播放url的indexPath。
 scrollPosition滚动位置。
 动画滚动动画。
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath
          scrollPosition:(PlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated;

/**
 滚动位置播放url的indexPath，而' assetURLs '或' sectionAssetURLs '不是NULL。

 播放url的indexPath。
 scrollPosition滚动位置。
 动画滚动动画。
 滚动完成回调。
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath
          scrollPosition:(PlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated
       completionHandler:(void (^ __nullable)(void))completionHandler;


/**
 滚动位置播放url的indexPath。

 播放url的indexPath
 assetURL播放器URL。
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath assetURL:(NSURL *)assetURL;


/**
 滚动位置播放url的indexPath。

 播放url的indexPath
 assetURL播放器URL。
 scrollPosition滚动位置。
 动画滚动动画。
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath
                assetURL:(NSURL *)assetURL
          scrollPosition:(PlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated;

/**
 滚动位置播放url的indexPath。

 播放url的indexPath
 assetURL播放器URL。
 scrollPosition滚动位置。
 动画滚动动画。
 滚动完成回调。
 */
- (void)playTheIndexPath:(NSIndexPath *)indexPath
                assetURL:(NSURL *)assetURL
          scrollPosition:(PlayerScrollViewScrollPosition)scrollPosition
                animated:(BOOL)animated
       completionHandler:(void (^ __nullable)(void))completionHandler;


@end

NS_ASSUME_NONNULL_END
