//
//  TFYADControlView.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYADControlView.h"
#import "UIView+PlayerFrame.h"
#import "TFY_ITools.h"

@interface TFYADControlView ()
@property (nonatomic, strong) UIImageView *bgImgView;

@property (nonatomic, strong) UIButton *skipBtn;

@property (nonatomic, strong) UIButton *fullScreenBtn;
@end

@implementation TFYADControlView
@synthesize player = _player;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.skipBtn];
        [self addSubview:self.fullScreenBtn];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat min_x = 0;
    CGFloat min_y = 0;
    CGFloat min_w = 0;
    CGFloat min_h = 0;
    CGFloat min_view_w = self.player_width;
    CGFloat min_view_h = self.bounds.size.height;

    self.bgImgView.frame = self.bounds;
    
    min_x = min_view_w - 100;
    min_y = 20;
    min_w = 70;
    min_h = 30;
    self.skipBtn.frame =  CGRectMake(min_x, min_y, min_w, min_h);
    self.skipBtn.layer.cornerRadius = min_h/2;
    self.skipBtn.layer.masksToBounds = YES;
    
    min_w = 30;
    min_h = min_w;
    min_x = min_view_w - min_w - 20;
    min_y = min_view_h - min_h - 20;
    self.fullScreenBtn.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.fullScreenBtn.layer.cornerRadius = min_h/2;
    self.fullScreenBtn.layer.masksToBounds = YES;
}


- (void)skipBtnClick {
    if (self.skipCallback) self.skipCallback();
}

- (void)fullScreenBtnClick {
    if (self.fullScreenCallback) self.fullScreenCallback();
}

/// 加载状态改变
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer loadStateChanged:(PlayerLoadState)state {
    if (state == PlayerLoadStatePrepare) {
        self.bgImgView.hidden = NO;
    } else if (state == PlayerLoadStatePlaythroughOK || state == PlayerLoadStatePlayable) {
        self.bgImgView.hidden = YES;
    }
}

/// 播放进度改变回调
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
    NSString *title = [NSString stringWithFormat:@"跳过 %zd秒",(NSInteger)(totalTime-currentTime)];
    [self.skipBtn setTitle:title forState:UIControlStateNormal];
}

- (void)videoPlayer:(TFY_PlayerController *)videoPlayer orientationWillChange:(TFY_OrientationObserver *)observer {
    self.fullScreenBtn.selected = observer.isFullScreen;
}

- (void)gestureSingleTapped:(TFY_PlayerGestureControl *)gestureControl {
  
}

- (void)setPlayer:(TFY_PlayerController *)player {
    _player = player;
    player.currentPlayerManager.scalingMode = PlayerScalingModeAspectFill;
    [player.currentPlayerManager.view insertSubview:self.bgImgView atIndex:0];
}

- (UIImageView *)bgImgView {
    if (!_bgImgView) {
        _bgImgView = [[UIImageView alloc] init];
        _bgImgView.userInteractionEnabled = YES;
    }
    return _bgImgView;
}

- (UIButton *)skipBtn {
    if (!_skipBtn) {
        _skipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _skipBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        [_skipBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _skipBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [_skipBtn addTarget:self action:@selector(skipBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _skipBtn;
}

- (UIButton *)fullScreenBtn {
    if (!_fullScreenBtn) {
        _fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenBtn setImage:Player_Image(@"Player_fullscreen") forState:UIControlStateNormal];
        [_fullScreenBtn setImage:Player_Image(@"Player_shrinkscreen") forState:UIControlStateSelected];
        [_fullScreenBtn addTarget:self action:@selector(fullScreenBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _fullScreenBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    }
    return _fullScreenBtn;
}


@end
