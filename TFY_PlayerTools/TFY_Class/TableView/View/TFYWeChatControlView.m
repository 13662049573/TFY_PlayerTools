//
//  TFYWeChatControlView.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYWeChatControlView.h"
#import "UIImageView+PlayerImageView.h"
#import "UIView+PlayerFrame.h"
#import "TFY_ITools.h"
#import "TFY_LoadingView.h"

@interface TFYWeChatControlView ()
@property (nonatomic, strong) TFY_LoadingView *activity;
@end

@implementation TFYWeChatControlView
@synthesize player = _player;

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addSubview:self.activity];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat min_x = 0;
    CGFloat min_y = 0;
    CGFloat min_w = 0;
    CGFloat min_h = 0;
    
    min_w = 44;
    min_h = 44;
    self.activity.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.activity.player_centerX = self.player_centerX;
    self.activity.player_centerY = self.player_centerY;
}

/// 播放状态改变
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer playStateChanged:(PlayerPlaybackState)state {
    if (state == PlayerPlayStatePlaying) {
        /// 开始播放时候判断是否显示loading
        if (videoPlayer.currentPlayerManager.loadState == PlayerLoadStateStalled) {
            [self.activity startAnimating];
        } else if ((videoPlayer.currentPlayerManager.loadState == PlayerLoadStateStalled || videoPlayer.currentPlayerManager.loadState == PlayerLoadStatePrepare)) {
            [self.activity startAnimating];
        }
    } else if (state == PlayerPlayStatePaused) {
        /// 暂停的时候隐藏loading
        [self.activity stopAnimating];
    } else if (state == PlayerPlayStatePlayFailed) {
        [self.activity stopAnimating];
    }
}

/// 加载状态改变
- (void)videoPlayer:(TFY_PlayerController *)videoPlayer loadStateChanged:(PlayerLoadState)state {
    if (state == PlayerLoadStateStalled && videoPlayer.currentPlayerManager.isPlaying) {
        [self.activity startAnimating];
    } else if ((state == PlayerLoadStateStalled || state == PlayerLoadStatePrepare) && videoPlayer.currentPlayerManager.isPlaying) {
        [self.activity startAnimating];
    } else {
        [self.activity stopAnimating];
    }
}

- (void)gestureSingleTapped:(TFY_PlayerGestureControl *)gestureControl {
    if (!self.player.isFullScreen) {
        [self.player enterPortraitFullScreen:YES animated:YES];
    }
}

/// 手势筛选，返回NO不响应该手势
- (BOOL)gestureTriggerCondition:(TFY_PlayerGestureControl *)gestureControl gestureType:(PlayerGestureType)gestureType gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer touch:(nonnull UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        if (gestureRecognizer == gestureControl.singleTap && !self.player.isFullScreen) {
            return YES;
        }
        return NO;
    }
    return YES;
}

- (void)setPlayer:(TFY_PlayerController *)player {
    _player = player;
}

- (void)showCoverViewWithUrl:(NSString *)coverUrl {
    [self.player.currentPlayerManager.view.coverImageView setImageWithURLString:coverUrl placeholder:[UIImage imageNamed:@"img_video_loading"]];
}

#pragma mark - getter

- (TFY_LoadingView *)activity {
    if (!_activity) {
        _activity = [[TFY_LoadingView alloc] init];
        _activity.hidesWhenStopped = YES;
        _activity.animType = LoadingTypeFadeOut;
    }
    return _activity;
}

@end
