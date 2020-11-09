//
//  TFY_ADViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_ADViewController.h"
#import "TFY_ADPlayerView.h"

@interface TFY_ADViewController ()
TFY_PROPERTY_STRONG TFY_PlayerController *adPlayer;
TFY_PROPERTY_STRONG TFY_ADPlayerView *adControlView;
TFY_PROPERTY_STRONG TFY_PlayerView *controlView;
@end

@implementation TFY_ADViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.imageViews];
    self.imageViews.tfy_LeftSpace(0).tfy_TopSpace(0).tfy_RightSpace(0).tfy_Height(TFY_PLAYER_ScreenW*9/16);
    
    self.player = [TFY_PlayerController playerWithPlayerManagercontainerView:self.imageViews];
    self.player.controlView = self.controlView;
    /// 设置退到后台继续播放
    self.player.pauseWhenAppResignActive = NO;
    
    @weakify(self)
    self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        @strongify(self)
        [self setNeedsStatusBarAppearanceUpdate];
    };
    
    /// 播放完成
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @strongify(self)
        [self.player.currentPlayerManager replay];
        [self.player playTheNext];
        if (!self.player.isLastAssetURL) {
            NSString *title = [NSString stringWithFormat:@"视频标题%zd",self.player.currentPlayIndex];
            [self.controlView showTitle:title coverURLString:kVideoCover fullScreenMode:FullScreenModeLandscape];
        } else {
            [self.player stop];
        }
    };
    
    TFY_PlayerVideoModel *modes6 = [TFY_PlayerVideoModel new];
    modes6.tfy_url = @"http://220.249.115.46:18080/wav/day_by_day.mp4";
       
    self.player.assetUrlModel = modes6;
    
    self.adPlayer = [TFY_PlayerController playerWithPlayerManagercontainerView:self.imageViews];
    self.adPlayer.controlView = self.adControlView;
    self.adPlayer.exitFullScreenWhenStop = NO;
    self.adPlayer.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        @strongify(self)
        [self setNeedsStatusBarAppearanceUpdate];
    };
    self.adPlayer.playerDidToEnd = ^(id  _Nonnull asset) {
        @strongify(self)
        [self.adPlayer stopCurrentPlayingView];
        self.player.currentPlayerManager.shouldAutoPlay = YES;
        [self.player.currentPlayerManager play];
    };
    
    TFY_PlayerVideoModel *modes7 = [TFY_PlayerVideoModel new];
    modes7.tfy_url = @"http://220.249.115.46:18080/wav/Lovey_Dovey.mp4";
       
    self.adPlayer.assetUrlModel = modes7;
}

- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
        _controlView.fastViewAnimated = YES;
        _controlView.autoHiddenTimeInterval = 5;
        _controlView.autoFadeTimeInterval = 0.5;
        _controlView.prepareShowLoading = YES;
    }
    return _controlView;
}

- (TFY_ADPlayerView *)adControlView {
    if (!_adControlView) {
        _adControlView = [[TFY_ADPlayerView alloc] init];
        @weakify(self)
        _adControlView.skipCallback = ^{
            @strongify(self)
            [self.adPlayer stopCurrentPlayingView];
            self.player.currentPlayerManager.shouldAutoPlay = YES;
            [self.player.currentPlayerManager play];
            self.player.viewControllerDisappear = NO;
        };
        
        _adControlView.fullScreenCallback = ^{
            @strongify(self)
            if (self.player.isFullScreen) {
                [self.player enterFullScreen:NO animated:YES];
            } else {
                [self.player enterFullScreen:YES animated:YES];
            }
        };
    }
    return _adControlView;
}
@end
