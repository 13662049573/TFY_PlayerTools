//
//  TFY_LandScapeControlView.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TFY_SliderView.h"
#import "TFY_PlayerController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TFY_LandScapeControlView : UIView

/// 顶部工具栏
@property (nonatomic, strong, readonly) UIView *topToolView;

/// 返回按钮
@property (nonatomic, strong, readonly) UIButton *backBtn;

/// 标题
@property (nonatomic, strong, readonly) UILabel *titleLabel;

/// 底部工具栏
@property (nonatomic, strong, readonly) UIView *bottomToolView;

/// 播放或暂停按钮
@property (nonatomic, strong, readonly) UIButton *playOrPauseBtn;

/// 播放的当前时间
@property (nonatomic, strong, readonly) UILabel *currentTimeLabel;

/// 滑杆
@property (nonatomic, strong, readonly) TFY_SliderView *slider;

/// 视频总时间
@property (nonatomic, strong, readonly) UILabel *totalTimeLabel;

/// 锁定屏幕按钮
@property (nonatomic, strong, readonly) UIButton *lockBtn;

/// 横屏时候是否显示自定义状态栏(iOS13+)，默认 NO.
@property (nonatomic, assign) BOOL showCustomStatusBar;

/// 播放器
@property (nonatomic, weak) TFY_PlayerController *player;

/// slider滑动中
@property (nonatomic, copy, nullable) void(^sliderValueChanging)(CGFloat value,BOOL forward);

/// slider滑动结束
@property (nonatomic, copy, nullable) void(^sliderValueChanged)(CGFloat value);

/// 返回按钮点击回调
@property (nonatomic, copy) void(^backBtnClickCallback)(void);

/// 如果是暂停状态，seek完是否播放，默认YES
@property (nonatomic, assign) BOOL seekToPlay;

/// 全屏模式
@property (nonatomic, assign) FullScreenMode fullScreenMode;

/// 重置控制层
- (void)resetControlView;

/// 显示控制层
- (void)showControlView;

/// 隐藏控制层
- (void)hideControlView;

/// 设置播放时间
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime;

/// 设置缓冲时间
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer bufferTime:(NSTimeInterval)bufferTime;

/// 是否响应该手势
- (BOOL)shouldResponseGestureWithPoint:(CGPoint)point withGestureType:(PlayerGestureType)type touch:(nonnull UITouch *)touch;

/// 视频尺寸改变
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer presentationSizeChanged:(CGSize)size;

/// 视频view已经旋转
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer orientationWillChange:(TFY_OrientationObserver *)observer;

/// 标题和全屏模式
- (void)showTitle:(NSString *_Nullable)title fullScreenMode:(FullScreenMode)fullScreenMode;

/// 根据当前播放状态取反
- (void)playOrPause;

/// 播放按钮状态
- (void)playBtnSelectedState:(BOOL)selected;

/// 调节播放进度slider和当前时间更新
- (void)sliderValueChanged:(CGFloat)value currentTimeString:(NSString *)timeString;

/// 滑杆结束滑动
- (void)sliderChangeEnded;


@end

NS_ASSUME_NONNULL_END
