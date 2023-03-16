//
//  TFYDouYinControlView.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYDouYinControlView.h"
#import "UIView+PlayerFrame.h"
#import "UIImageView+PlayerImageView.h"

@interface TFYDouYinControlView ()
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) TFY_SliderView *sliderView;
@end

@implementation TFYDouYinControlView
@synthesize player = _player;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.playBtn];
        [self addSubview:self.sliderView];
        [self resetControlView];
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
    CGFloat min_view_h = self.player_height;
    
    min_w = 100;
    min_h = 100;
    self.playBtn.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.playBtn.center = self.center;
    
    min_x = 0;
    min_y = min_view_h - 80;
    min_w = min_view_w;
    min_h = 1;
    self.sliderView.frame = CGRectMake(min_x, min_y, min_w, min_h);
}

- (void)resetControlView {
    self.playBtn.hidden = YES;
    self.sliderView.value = 0;
    self.sliderView.bufferValue = 0;
}

/// 加载状态改变
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer loadStateChanged:(PlayerLoadState)state {
    if ((state == PlayerLoadStateStalled || state == PlayerLoadStatePrepare) && videoPlayer.currentPlayerManager.isPlaying) {
        [self.sliderView startAnimating];
    } else {
        [self.sliderView stopAnimating];
    }
}

/// 播放进度改变回调
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
    self.sliderView.value = videoPlayer.progress;
}

- (void)videoPlayer:(TFY_PlayerController *)videoPlayer bufferTime:(NSTimeInterval)bufferTime {}

- (void)gestureSingleTapped:(TFY_PlayerGestureControl *)gestureControl {
    if (self.player.currentPlayerManager.isPlaying) {
        [self.player.currentPlayerManager pause];
        self.playBtn.hidden = NO;
        self.playBtn.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
        [UIView animateWithDuration:0.2f delay:0
                            options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.playBtn.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else {
        [self.player.currentPlayerManager play];
        self.playBtn.hidden = YES;
    }
}

- (void)setPlayer:(TFY_PlayerController *)player {
    _player = player;
}

- (void)showCoverViewWithUrl:(NSString *)coverUrl {
    [self.player.currentPlayerManager.view.coverImageView setImageWithURLString:coverUrl placeholder:[UIImage imageNamed:@"img_video_loading"]];
}

#pragma mark - getter

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playBtn.userInteractionEnabled = NO;
        [_playBtn setImage:[UIImage imageNamed:@"icon_play_pause"] forState:UIControlStateNormal];
    }
    return _playBtn;
}

- (TFY_SliderView *)sliderView {
    if (!_sliderView) {
        _sliderView = [[TFY_SliderView alloc] init];
        _sliderView.maximumTrackTintColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.2];
        _sliderView.minimumTrackTintColor = [UIColor whiteColor];
        _sliderView.bufferTrackTintColor  = [UIColor clearColor];
        _sliderView.sliderHeight = 1;
        _sliderView.isHideSliderBlock = NO;
    }
    return _sliderView;
}


@end
