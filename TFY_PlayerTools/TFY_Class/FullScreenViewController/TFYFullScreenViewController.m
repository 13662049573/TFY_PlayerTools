//
//  TFYFullScreenViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYFullScreenViewController.h"
#import "TFYSmallPlayViewController.h"
#import "TFY_PlayerTool.h"
static NSString *kVideoCover = @"https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240";

@interface TFYFullScreenViewController ()
@property (nonatomic, strong) TFY_PlayerController *player;
@property (nonatomic, strong) TFY_PlayerControlView *controlView;
@end

@implementation TFYFullScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    @player_weakify(self)
    self.controlView.backBtnClickCallback = ^{
        @player_strongify(self)
        [self.player rotateToOrientation:UIInterfaceOrientationPortrait animated:NO completion:nil];
        [self.player stop];
        [self dismissViewControllerAnimated:NO completion:nil];
    };
    
    TFY_AVPlayerManager *playerManager = [[TFY_AVPlayerManager alloc] init];
    /// 播放器相关
    self.player = [[TFY_PlayerController alloc] initWithPlayerManager:playerManager containerView:self.view];
    self.player.controlView = self.controlView;
    self.player.orientationObserver.supportInterfaceOrientation = InterfaceOrientationMaskLandscape;
    
    /// 设置转屏方向
    [self.player rotateToOrientation:UIInterfaceOrientationLandscapeRight animated:NO completion:nil];
    playerManager.assetURL = [NSURL URLWithString:@"https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return self.player.isStatusBarHidden;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (TFY_PlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerControlView new];
        _controlView.fastViewAnimated = YES;
        _controlView.effectViewShow = NO;
        _controlView.prepareShowLoading = YES;
        _controlView.showCustomStatusBar = YES;
    }
    return _controlView;
}


@end
