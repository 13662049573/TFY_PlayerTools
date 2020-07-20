//
//  TFY_CustomControlController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_CustomControlController.h"
#import "TFY_CustomControlView.h"

@interface TFY_CustomControlController ()
@property (nonatomic, strong) TFY_CustomControlView *controlView;
@end

@implementation TFY_CustomControlController

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
}

- (TFY_CustomControlView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_CustomControlView new];
    }
    return _controlView;
}


@end
