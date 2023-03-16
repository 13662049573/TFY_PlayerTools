//
//  TFYADViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYADViewController.h"
#import "TFYADControlView.h"
#import "UIImageView+PlayerImageView.h"
#import "UIView+PlayerFrame.h"
#import "TFY_ITools.h"
#import "TFY_PlayerTool.h"
static NSString *kVideoCover = @"https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240";

@interface TFYADViewController ()
@property (nonatomic, strong) TFY_PlayerController *player;
@property (nonatomic, strong) UIImageView *containerView;
@property (nonatomic, strong) TFY_PlayerControlView *controlView;
@property (nonatomic, strong) TFYADControlView *adControlView;
@property (nonatomic, strong) TFY_AVPlayerManager *playerManager;
@property (nonatomic, strong) TFY_AVPlayerManager *adPlayerManager;
@end

@implementation TFYADViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.containerView];
    
    CGFloat x = 0;
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat w = CGRectGetWidth(self.view.frame);
    CGFloat h = w*9/16;
    self.containerView.frame = CGRectMake(x, y, w, h);
    
    
    self.playerManager = [[TFY_AVPlayerManager alloc] init];
    /// 广告
    self.adPlayerManager = [[TFY_AVPlayerManager alloc] init];

    /// 播放器相关
    self.player = [TFY_PlayerController playerWithPlayerManager:self.adPlayerManager containerView:self.containerView];
    self.player.controlView = self.adControlView;
    /// 设置退到后台继续播放
    self.player.pauseWhenAppResignActive = NO;

    @player_weakify(self)
    /// 播放完成
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @player_strongify(self)
        if (self.player.currentPlayerManager == self.adPlayerManager) {
            self.player.controlView = self.controlView;
            self.player.currentPlayerManager = self.playerManager;
            self.player.currentPlayerManager.shouldAutoPlay = YES;
            [self.player.currentPlayerManager play];
            [self.controlView showTitle:@"iPhone X" coverURLString:kVideoCover fullScreenMode:FullScreenModeLandscape];
        } else {
            [self.player stop];
        }
    };
    
    /// 一定要在player初始化之后设置assetURL
    self.playerManager.shouldAutoPlay = NO;
    self.playerManager.assetURL = [NSURL URLWithString:@"https://www.apple.com/105/media/cn/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/bruce/mac-bruce-tpl-cn-2018_1280x720h.mp4"];
    
    self.adPlayerManager.assetURL = [NSURL URLWithString:@"https://fcvideo.cdn.bcebos.com/smart/f103c4fc97d2b2e63b15d2d5999d6477.mp4"];
    self.adPlayerManager.shouldAutoPlay = YES;

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat x = 0;
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat w = CGRectGetWidth(self.view.frame);
    CGFloat h = w*9/16;
    self.containerView.frame = CGRectMake(x, y, w, h);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (TFY_PlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerControlView new];
        _controlView.fastViewAnimated = YES;
        _controlView.autoHiddenTimeInterval = 5;
        _controlView.autoFadeTimeInterval = 0.5;
        _controlView.prepareShowLoading = YES;
    }
    return _controlView;
}

- (TFYADControlView *)adControlView {
    if (!_adControlView) {
        _adControlView = [[TFYADControlView alloc] init];
        @player_weakify(self)
        _adControlView.skipCallback = ^{
            @player_strongify(self)
            self.player.controlView = self.controlView;
            self.player.currentPlayerManager = self.playerManager;
            self.playerManager.shouldAutoPlay = YES;
            [self.player.currentPlayerManager play];
            [self.controlView showTitle:@"iPhone X" coverURLString:kVideoCover fullScreenMode:FullScreenModeLandscape];
        };
        
        _adControlView.fullScreenCallback = ^{
            @player_strongify(self)
            if (self.player.isFullScreen) {
                [self.player enterFullScreen:NO animated:YES];
            } else {
                [self.player enterFullScreen:YES animated:YES];
            }
        };
    }
    return _adControlView;
}

- (UIImageView *)containerView {
    if (!_containerView) {
        _containerView = [UIImageView new];
        [_containerView setImageWithURLString:kVideoCover placeholder:[TFY_ITools imageWithColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1] size:CGSizeMake(1, 1)]];
    }
    return _containerView;
}


@end
