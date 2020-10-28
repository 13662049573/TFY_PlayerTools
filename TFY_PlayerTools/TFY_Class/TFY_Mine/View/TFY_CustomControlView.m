//
//  TFY_CustomControlView.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_CustomControlView.h"

@interface TFY_CustomControlView ()<TFY_SliderViewDelegate>
/// 底部工具栏
@property (nonatomic, strong) UIView *bottomToolView;
/// 顶部工具栏
@property (nonatomic, strong) UIView *topToolView;
/// 标题
@property (nonatomic, strong) UILabel *titleLabel;
/// 播放或暂停按钮
@property (nonatomic, strong) UIButton *playOrPauseBtn;
/// 播放的当前时间
@property (nonatomic, strong) UILabel *currentTimeLabel;
/// 滑杆
@property (nonatomic, strong) TFY_SliderView *slider;
/// 视频总时间
@property (nonatomic, strong) UILabel *totalTimeLabel;
/// 全屏按钮
@property (nonatomic, strong) UIButton *fullScreenBtn;

@property (nonatomic, assign) BOOL isShow;

@property (nonatomic, strong) UIImageView *bgImgView;

@property (nonatomic, assign) BOOL controlViewAppeared;

@property (nonatomic, strong) dispatch_block_t afterBlock;

@property (nonatomic, assign) NSTimeInterval sumTime;

/// 底部播放进度
@property (nonatomic, strong) TFY_SliderView *bottomPgrogress;

/// 加载loading
@property (nonatomic, strong) TFY_SpeedLoadingView *activity;

/// 封面图
@property (nonatomic, strong) UIImageView *coverImageView;

@end

@implementation TFY_CustomControlView
@synthesize player = _player;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 添加子控件
        [self addSubview:self.topToolView];
        [self addSubview:self.bottomToolView];
        [self addSubview:self.playOrPauseBtn];
        [self.topToolView addSubview:self.titleLabel];
        [self.bottomToolView addSubview:self.currentTimeLabel];
        [self.bottomToolView addSubview:self.slider];
        [self.bottomToolView addSubview:self.totalTimeLabel];
        [self.bottomToolView addSubview:self.fullScreenBtn];
        [self addSubview:self.bottomPgrogress];
        [self addSubview:self.activity];

        self.autoFadeTimeInterval = 0.2;
        self.autoHiddenTimeInterval = 2.5;

        // 设置子控件的响应事件
        [self makeSubViewsAction];
        
        [self resetControlView];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)makeSubViewsAction {
    [self.playOrPauseBtn addTarget:self action:@selector(playPauseButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.fullScreenBtn addTarget:self action:@selector(fullScreenButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - SliderViewDelegate

- (void)sliderTouchBegan:(float)value {
    self.slider.isdragging = YES;
}

- (void)sliderTouchEnded:(float)value {
    if (self.player.totalTime > 0) {
        @weakify(self)
        [self.player seekToTime:self.player.totalTime*value completionHandler:^(BOOL finished) {
            @strongify(self)
            if (finished) {
                self.slider.isdragging = NO;
            }
        }];
    } else {
        self.slider.isdragging = NO;
    }
}

- (void)sliderValueChanged:(float)value {
    if (self.player.totalTime == 0) {
        self.slider.value = 0;
        return;
    }
    self.slider.isdragging = YES;
    NSString *currentTimeString = [TFY_ITools convertTimeSecond:self.player.totalTime*value];
    self.currentTimeLabel.text = currentTimeString;
}

- (void)sliderTapped:(float)value {
    if (self.player.totalTime > 0) {
        self.slider.isdragging = YES;
        @weakify(self)
        [self.player seekToTime:self.player.totalTime*value completionHandler:^(BOOL finished) {
            @strongify(self)
            if (finished) {
                self.slider.isdragging = NO;
                [self.player.currentPlayerManager play];
            }
        }];
    } else {
        self.slider.isdragging = NO;
        self.slider.value = 0;
    }
}

#pragma mark - action

- (void)playPauseButtonClickAction:(UIButton *)sender {
    [self playOrPause];
}

- (void)fullScreenButtonClickAction:(UIButton *)sender {
    [self.player enterFullScreen:!self.player.isFullScreen animated:YES];
}

/// 根据当前播放状态取反
- (void)playOrPause {
    self.playOrPauseBtn.selected = !self.playOrPauseBtn.isSelected;
    self.playOrPauseBtn.isSelected? [self.player.currentPlayerManager play]: [self.player.currentPlayerManager pause];
}

- (void)playBtnSelectedState:(BOOL)selected {
    self.playOrPauseBtn.selected = selected;
}

#pragma mark - 添加子控件约束

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat min_x = 0;
    CGFloat min_y = 0;
    CGFloat min_w = 0;
    CGFloat min_h = 0;
    CGFloat min_view_w = self.bounds.size.width;
    CGFloat min_view_h = self.bounds.size.height;
    CGFloat min_margin = 9;
    
    self.coverImageView.frame = self.bounds;
    self.bgImgView.frame = self.bounds;
    
    min_w = 80;
    min_h = 80;
    self.activity.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.activity.player_centerX = self.player_centerX;
    self.activity.player_centerY = self.player_centerY + 10;
    
    min_x = 0;
    min_y = 0;
    min_w = min_view_w;
    min_h = (Player_iPhoneX && self.player.isFullScreen) ? 80 : 40;
    self.topToolView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = (Player_iPhoneX && self.player.isFullScreen) ? 44: 15;
    min_y = 0;
    min_w = min_view_w - min_x - 15;
    min_h = 30;
    self.titleLabel.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.titleLabel.player_centerY = self.topToolView.player_centerY;

    min_h = (Player_iPhoneX && self.player.isFullScreen) ? 100 : 40;
    min_x = 0;
    min_y = min_view_h - min_h;
    min_w = min_view_w;
    self.bottomToolView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_x = 0;
    min_y = 0;
    min_w = 44;
    min_h = min_w;
    self.playOrPauseBtn.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.playOrPauseBtn.center = self.center;
    
    min_x = (Player_iPhoneX && self.player.isFullScreen) ? 44: 15;
    min_w = 62;
    min_h = 28;
    min_y = (self.bottomToolView.player_height - min_h)/2;
    self.currentTimeLabel.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    min_w = 28;
    min_h = min_w;
    min_x = self.bottomToolView.player_width - min_w - ((Player_iPhoneX && self.player.isFullScreen) ? 44: min_margin);
    min_y = 0;
    self.fullScreenBtn.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.fullScreenBtn.player_centerY = self.currentTimeLabel.player_centerY;
    
    min_w = 62;
    min_h = 28;
    min_x = self.fullScreenBtn.player_left - min_w - 4;
    min_y = 0;
    self.totalTimeLabel.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.totalTimeLabel.player_centerY = self.currentTimeLabel.player_centerY;
    
    min_x = self.currentTimeLabel.player_right + 4;
    min_y = 0;
    min_w = self.totalTimeLabel.player_left - min_x - 4;
    min_h = 30;
    self.slider.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.slider.player_centerY = self.currentTimeLabel.player_centerY;
    
    min_x = 0;
    min_y = min_view_h - 1;
    min_w = min_view_w;
    min_h = 1;
    self.bottomPgrogress.frame = CGRectMake(min_x, min_y, min_w, min_h);
    
    if (!self.isShow) {
        self.topToolView.player_y = -self.topToolView.player_height;
        self.bottomToolView.player_y = self.player_height;
        self.playOrPauseBtn.alpha = 0;
    } else {
        self.topToolView.player_y = 0;
        self.bottomToolView.player_y = self.player_height - self.bottomToolView.player_height;
        self.playOrPauseBtn.alpha = 1;
    }
}

#pragma mark - private

/** 重置ControlView */
- (void)resetControlView {
    self.bottomToolView.alpha        = 1;
    self.slider.value                = 0;
    self.slider.bufferValue          = 0;
    self.currentTimeLabel.text       = @"00:00";
    self.totalTimeLabel.text         = @"00:00";
    self.backgroundColor             = [UIColor clearColor];
    self.playOrPauseBtn.selected     = YES;
    self.titleLabel.text             = @"";
}

- (void)showControlView {
    self.topToolView.alpha           = 1;
    self.bottomToolView.alpha        = 1;
    self.isShow                      = YES;
    self.topToolView.player_y            = 0;
    self.bottomToolView.player_y         = self.player_height - self.bottomToolView.player_height;
    self.playOrPauseBtn.alpha        = 1;
    self.player.statusBarHidden      = NO;
}

- (void)hideControlView {
    self.isShow                      = NO;
    self.topToolView.player_y            = -self.topToolView.player_height;
    self.bottomToolView.player_y         = self.player_height;
    self.player.statusBarHidden      = NO;
    self.playOrPauseBtn.alpha        = 0;
    self.topToolView.alpha           = 0;
    self.bottomToolView.alpha        = 0;
}

- (void)autoFadeOutControlView {
    self.controlViewAppeared = YES;
    [self cancelAutoFadeOutControlView];
    @weakify(self)
    self.afterBlock = dispatch_block_create(0, ^{
        @strongify(self)
        [self hideControlViewWithAnimated:YES];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.autoHiddenTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(),self.afterBlock);
}

/// 取消延时隐藏controlView的方法
- (void)cancelAutoFadeOutControlView {
    if (self.afterBlock) {
        dispatch_block_cancel(self.afterBlock);
        self.afterBlock = nil;
    }
}

/// 隐藏控制层
- (void)hideControlViewWithAnimated:(BOOL)animated {
    self.controlViewAppeared = NO;
    [UIView animateWithDuration:animated ? self.autoFadeTimeInterval : 0 animations:^{
        [self hideControlView];
    } completion:^(BOOL finished) {
        self.bottomPgrogress.hidden = NO;
    }];
}

/// 显示控制层
- (void)showControlViewWithAnimated:(BOOL)animated {
    self.controlViewAppeared = YES;
    [self autoFadeOutControlView];
    [UIView animateWithDuration:animated ? self.autoFadeTimeInterval : 0 animations:^{
        [self showControlView];
    } completion:^(BOOL finished) {
        self.bottomPgrogress.hidden = YES;
    }];
}


- (BOOL)shouldResponseGestureWithPoint:(CGPoint)point withGestureType:(PlayerGestureType)type touch:(nonnull UITouch *)touch {
    CGRect sliderRect = [self.bottomToolView convertRect:self.slider.frame toView:self];
    if (CGRectContainsPoint(sliderRect, point)) {
        return NO;
    }
    return YES;
}

/**
 设置标题、封面、全屏模式
 
 @param title 视频的标题
 @param coverUrl 视频的封面，占位图默认是灰色的
 @param fullScreenMode 全屏模式
 */
- (void)showTitle:(NSString *)title coverURLString:(NSString *)coverUrl fullScreenMode:(FullScreenMode)fullScreenMode {
    UIImage *placeholder = [TFY_ITools imageWithColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1] size:self.bgImgView.bounds.size];
    [self resetControlView];
    [self layoutIfNeeded];
    [self setNeedsDisplay];
    self.titleLabel.text = title;
    self.player.orientationObserver.fullScreenMode = fullScreenMode;
    [self.coverImageView setImageWithURLString:coverUrl placeholder:placeholder];
    [self.bgImgView setImageWithURLString:coverUrl placeholder:placeholder];
}

/// 调节播放进度slider和当前时间更新
- (void)sliderValueChanged:(CGFloat)value currentTimeString:(NSString *)timeString {
    self.slider.value = value;
    self.currentTimeLabel.text = timeString;
    self.slider.isdragging = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.slider.sliderBtn.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }];
}

/// 滑杆结束滑动
- (void)sliderChangeEnded {
    self.slider.isdragging = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.slider.sliderBtn.transform = CGAffineTransformIdentity;
    }];
}

#pragma mark - ZFPlayerControlViewDelegate

/// 手势筛选，返回NO不响应该手势
- (BOOL)gestureTriggerCondition:(TFY_PlayerGestureControl *)gestureControl gestureType:(PlayerGestureType)gestureType gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer touch:(nonnull UITouch *)touch {
    CGPoint point = [touch locationInView:self];
    if (self.player.isSmallFloatViewShow && !self.player.isFullScreen && gestureType != PlayerGestureTypeSingleTap) {
        return NO;
    }
    return [self shouldResponseGestureWithPoint:point withGestureType:gestureType touch:touch];
}

/// 单击手势事件
- (void)gestureSingleTapped:(TFY_PlayerGestureControl *)gestureControl {
    if (!self.player) return;
    if (self.player.isSmallFloatViewShow && !self.player.isFullScreen) {
        [self.player enterFullScreen:YES animated:YES];
    } else {
        if (self.controlViewAppeared) {
            [self hideControlViewWithAnimated:YES];
        } else {
            /// 显示之前先把控制层复位，先隐藏后显示
            [self hideControlViewWithAnimated:NO];
            [self showControlViewWithAnimated:YES];
        }
    }
}

/// 双击手势事件
- (void)gestureDoubleTapped:(TFY_PlayerGestureControl *)gestureControl {
    [self playOrPause];
}

/// 开始滑动手势事件
- (void)gestureBeganPan:(TFY_PlayerGestureControl *)gestureControl panDirection:(PanDirection)direction panLocation:(PanLocation)location {
    if (direction == PanDirectionH) {
        self.sumTime = self.player.currentTime;
    }
}

/// 滑动中手势事件
- (void)gestureChangedPan:(TFY_PlayerGestureControl *)gestureControl panDirection:(PanDirection)direction panLocation:(PanLocation)location withVelocity:(CGPoint)velocity {

}

/// 滑动结束手势事件
- (void)gestureEndedPan:(TFY_PlayerGestureControl *)gestureControl panDirection:(PanDirection)direction panLocation:(PanLocation)location {
    @weakify(self)
    if (direction == PanDirectionH && self.sumTime >= 0 && self.player.totalTime > 0) {
        [self.player seekToTime:self.sumTime completionHandler:^(BOOL finished) {
            @strongify(self)
            /// 左右滑动调节播放进度
            [self sliderChangeEnded];
            if (self.controlViewAppeared) {
                [self autoFadeOutControlView];
            }
        }];
        self.sumTime = 0;
    }
}

/// 捏合手势事件，这里改变了视频的填充模式
- (void)gesturePinched:(TFY_PlayerGestureControl *)gestureControl scale:(float)scale {
    if (scale > 1) {
        self.player.currentPlayerManager.scalingMode = PlayerScalingModeAspectFill;
    } else {
        self.player.currentPlayerManager.scalingMode = PlayerScalingModeAspectFit;
    }
}

/// 准备播放
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer prepareToPlay:(NSURL *)assetURL {
    [self hideControlViewWithAnimated:NO];
}

/// 播放状态改变
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer playStateChanged:(PlayerPlaybackState)state {
    if (state == PlayerPlayStatePlaying) {
        [self playBtnSelectedState:YES];
        /// 开始播放时候判断是否显示loading
        if (videoPlayer.currentPlayerManager.loadState == PlayerLoadStateStalled) {
            [self.activity startAnimating];
        } else if ((videoPlayer.currentPlayerManager.loadState == PlayerLoadStateStalled || videoPlayer.currentPlayerManager.loadState == PlayerLoadStatePrepare)) {
            [self.activity startAnimating];
        }
    } else if (state == PlayerPlayStatePaused) {
        [self playBtnSelectedState:NO];
        /// 暂停的时候隐藏loading
        [self.activity stopAnimating];
    } else if (state == PlayerPlayStatePlayFailed) {
        [self.activity stopAnimating];
    }
}

/// 加载状态改变
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer loadStateChanged:(PlayerLoadState)state {
    if (state == PlayerLoadStatePrepare) {
        self.coverImageView.hidden = NO;
    } else if (state == PlayerLoadStatePlaythroughOK || state == PlayerLoadStatePlayable) {
        self.coverImageView.hidden = YES;
        self.player.currentPlayerManager.view.backgroundColor = [UIColor blackColor];
    }
    if (state == PlayerLoadStateStalled && videoPlayer.currentPlayerManager.isPlaying) {
        [self.activity startAnimating];
    } else if ((state == PlayerLoadStateStalled || state == PlayerLoadStatePrepare) && videoPlayer.currentPlayerManager.isPlaying) {
        [self.activity startAnimating];
    } else {
        [self.activity stopAnimating];
    }
}

/// 播放进度改变回调
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
    if (!self.slider.isdragging) {
        NSString *currentTimeString = [TFY_ITools convertTimeSecond:currentTime];
        self.currentTimeLabel.text = currentTimeString;
        NSString *totalTimeString = [TFY_ITools convertTimeSecond:totalTime];
        self.totalTimeLabel.text = totalTimeString;
        self.slider.value = videoPlayer.progress;
    }
    self.bottomPgrogress.value = videoPlayer.progress;
}

/// 缓冲改变回调
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer bufferTime:(NSTimeInterval)bufferTime {
    self.slider.bufferValue = videoPlayer.bufferProgress;
    self.bottomPgrogress.bufferValue = videoPlayer.bufferProgress;
}

- (void)videoPlayer:(TFY_PlayerController *)videoPlayer presentationSizeChanged:(CGSize)size {
    
}

/// 视频view即将旋转
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer orientationWillChange:(TFY_OrientationObserver *)observer {
    if (videoPlayer.isSmallFloatViewShow) {
        if (observer.isFullScreen) {
            self.controlViewAppeared = NO;
            [self cancelAutoFadeOutControlView];
        }
    }
    if (self.controlViewAppeared) {
        [self showControlViewWithAnimated:NO];
    } else {
        [self hideControlViewWithAnimated:NO];
    }
}

/// 视频view已经旋转
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer orientationDidChanged:(TFY_OrientationObserver *)observer {
    if (self.controlViewAppeared) {
        [self showControlViewWithAnimated:NO];
    } else {
        [self hideControlViewWithAnimated:NO];
    }
    [self layoutIfNeeded];
    [self setNeedsDisplay];
}

/// 锁定旋转方向
- (void)lockedVideoPlayer:(TFY_PlayerController *)videoPlayer lockedScreen:(BOOL)locked {
    [self showControlViewWithAnimated:YES];
}

#pragma mark - setter

- (void)setPlayer:(TFY_PlayerController *)player {
    _player = player;
    /// 解决播放时候黑屏闪一下问题
    [player.currentPlayerManager.view insertSubview:self.bgImgView atIndex:0];
    [player.currentPlayerManager.view insertSubview:self.coverImageView atIndex:1];
    self.coverImageView.frame = player.currentPlayerManager.view.bounds;
    self.coverImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.bgImgView.frame = player.currentPlayerManager.view.bounds;
    self.bgImgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.coverImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

#pragma mark - getter

- (UIView *)topToolView {
    if (!_topToolView) {
        _topToolView = [[UIView alloc] init];
        UIImage *image = Player_Image(@"top_shadow");
        _topToolView.layer.contents = (id)image.CGImage;
    }
    return _topToolView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _titleLabel;
}

- (UIView *)bottomToolView {
    if (!_bottomToolView) {
        _bottomToolView = [[UIView alloc] init];
        UIImage *image = Player_Image(@"bottom_shadow");
        _bottomToolView.layer.contents = (id)image.CGImage;
    }
    return _bottomToolView;
}

- (UIButton *)playOrPauseBtn {
    if (!_playOrPauseBtn) {
        _playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playOrPauseBtn setImage:Player_Image(@"start_fullscreen") forState:UIControlStateNormal];
        [_playOrPauseBtn setImage:Player_Image(@"pause_fullscreen") forState:UIControlStateSelected];
    }
    return _playOrPauseBtn;
}

- (UILabel *)currentTimeLabel {
    if (!_currentTimeLabel) {
        _currentTimeLabel = [[UILabel alloc] init];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:14.0f];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (TFY_SliderView *)slider {
    if (!_slider) {
        _slider = [[TFY_SliderView alloc] init];
        _slider.delegate = self;
        _slider.maximumTrackTintColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.8];
        _slider.bufferTrackTintColor  = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _slider.minimumTrackTintColor = [UIColor whiteColor];
        [_slider setThumbImage:Player_Image(@"slider") forState:UIControlStateNormal];
        _slider.sliderHeight = 2;
    }
    return _slider;
}

- (UILabel *)totalTimeLabel {
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc] init];
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.font = [UIFont systemFontOfSize:14.0f];
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _totalTimeLabel;
}

- (UIButton *)fullScreenBtn {
    if (!_fullScreenBtn) {
        _fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenBtn setImage:Player_Image(@"btn_zoom_out") forState:UIControlStateNormal];
    }
    return _fullScreenBtn;
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.userInteractionEnabled = YES;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _coverImageView;
}

- (UIImageView *)bgImgView {
    if (!_bgImgView) {
        _bgImgView = [[UIImageView alloc] init];
        _bgImgView.userInteractionEnabled = YES;
    }
    return _bgImgView;
}

- (TFY_SliderView *)bottomPgrogress {
    if (!_bottomPgrogress) {
        _bottomPgrogress = [[TFY_SliderView alloc] init];
        _bottomPgrogress.maximumTrackTintColor = [UIColor clearColor];
        _bottomPgrogress.minimumTrackTintColor = [UIColor whiteColor];
        _bottomPgrogress.bufferTrackTintColor  = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.5];
        _bottomPgrogress.sliderHeight = 1;
        _bottomPgrogress.isHideSliderBlock = NO;
    }
    return _bottomPgrogress;
}

@end
