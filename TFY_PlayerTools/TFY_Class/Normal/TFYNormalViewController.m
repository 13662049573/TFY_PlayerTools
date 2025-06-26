//
//  TFYNormalViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYNormalViewController.h"
#import <AVKit/AVKit.h>
#import "TFYNotAutoPlayViewController.h"
#import "TFY_PlayerTool.h"

static NSString *kVideoCover = @"https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240";

@interface TFYNormalViewController ()
@property (nonatomic, strong) TFY_PlayerController *player;
@property (nonatomic, strong) UIImageView *containerView;
@property (nonatomic, strong) TFY_PlayerControlView *controlView;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIButton *changeBtn;
@property (nonatomic, strong) UIButton *nextBtn;
@property (nonatomic, strong) UIButton *pipBtn;
@property (nonatomic, strong) NSArray <NSURL *>*assetURLs;
@end

@implementation TFYNormalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Push" style:UIBarButtonItemStylePlain target:self action:@selector(pushNewVC)];
    [self.view addSubview:self.containerView];
    
    [self.containerView addSubview:self.playBtn];
    [self.view addSubview:self.changeBtn];
    [self.view addSubview:self.nextBtn];
    [self.view addSubview:self.pipBtn];
    [self setupPlayer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.player.viewControllerDisappear = NO;
    [self updatePipButtonTitle];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.player.viewControllerDisappear = YES;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat x = 0;
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat w = CGRectGetWidth(self.view.frame);
    CGFloat h = w*9/16;
    self.containerView.frame = CGRectMake(x, y, w, h);
    
    w = 44;
    h = w;
    x = (CGRectGetWidth(self.containerView.frame)-w)/2;
    y = (CGRectGetHeight(self.containerView.frame)-h)/2;
    self.playBtn.frame = CGRectMake(x, y, w, h);
    
    w = 100;
    h = 30;
    x = (CGRectGetWidth(self.view.frame)-w)/2;
    y = CGRectGetMaxY(self.containerView.frame)+50;
    self.changeBtn.frame = CGRectMake(x, y, w, h);
    
    w = 100;
    h = 30;
    x = (CGRectGetWidth(self.view.frame)-w)/2;
    y = CGRectGetMaxY(self.changeBtn.frame)+50;
    self.nextBtn.frame = CGRectMake(x, y, w, h);
    
    
    w = 100;
    h = 30;
    x = (CGRectGetWidth(self.view.frame)-w)/2;
    y = CGRectGetMaxY(self.nextBtn.frame)+50;
    self.pipBtn.frame = CGRectMake(x, y, w, h);
}

- (void)setupPlayer {
    TFY_AVPlayerManager *playerManager = [[TFY_AVPlayerManager alloc] init];
    playerManager.shouldAutoPlay = YES;
    /// 播放器相关
    self.player = [TFY_PlayerController playerWithPlayerManager:playerManager containerView:self.containerView];
    self.player.controlView = self.controlView;
    /// 设置退到后台继续播放
    self.player.pauseWhenAppResignActive = NO;
    self.player.shouldAutoPlayNext = YES;
    self.player.shouldLoopPlay = YES;
    /// 启用画中画功能（只有明确启用后才会创建画中画控制器）
    self.player.enablePictureInPicture = YES;
    
    @player_weakify(self)
    self.player.orientationDidChanged = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        /* // 使用YYTextView转屏失败
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if ([window isKindOfClass:NSClassFromString(@"YYTextEffectWindow")]) {
                window.hidden = isFullScreen;
            }
        }
        */
    };
    
    /// 播放完成 - 支持画中画连续播放
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @player_strongify(self)
        NSLog(@"视频播放完成，当前播放索引: %ld", (long)self.player.currentPlayIndex);
        
        // 检查是否在画中画模式下
        BOOL isPipActive = [self.player isPictureInPictureActive];
        
        if (isPipActive) {
            // 在画中画模式下，让 TFY_PlayerController 内部的画中画连续播放逻辑来处理
            // 这里不执行连续播放，避免与内部逻辑冲突
            NSLog(@"画中画模式下播放完成，由TFY_PlayerController内部处理连续播放");
            return;
        }
        
        // 非画中画模式下的正常连续播放逻辑
        if (self.player.shouldAutoPlayNext && !self.player.isLastAssetURL) {
            // 自动播放下一个视频
            [self.player playTheNext];
            NSString *title = [NSString stringWithFormat:@"视频标题%zd",self.player.currentPlayIndex];
            [self.controlView showTitle:title coverURLString:kVideoCover fullScreenMode:FullScreenModeLandscape];
            NSLog(@"自动播放下一个视频，新索引: %ld", (long)self.player.currentPlayIndex);
        } else if (self.player.shouldLoopPlay) {
            // 循环播放，回到第一个视频
            [self.player playTheIndex:0];
            [self.controlView showTitle:@"iPhone X" coverURLString:kVideoCover fullScreenMode:FullScreenModeAutomatic];
            NSLog(@"循环播放，回到第一个视频");
        } else {
            // 停止播放
            [self.player stop];
            NSLog(@"停止播放");
        }
    };
    
    // 画中画相关回调
    self.player.pipWillStart = ^(TFY_PlayerController *player) {
        @player_strongify(self)
        NSLog(@"画中画即将开始");
        self.pipBtn.selected = YES;
        [self updatePipButtonTitle];
    };
    
    self.player.pipDidStart = ^(TFY_PlayerController *player) {
        @player_strongify(self)
        NSLog(@"画中画已经开始，当前视频索引: %ld", (long)self.player.currentPlayIndex);
        // 画中画模式下确保播放器继续工作
        if (!self.player.isPlaying) {
            [self.player.currentPlayerManager play];
        }
        [self updatePipButtonTitle];
    };
    
    self.player.pipWillStop = ^(TFY_PlayerController *player) {
        @player_strongify(self)
        NSLog(@"画中画即将停止");
    };
    
    self.player.pipDidStop = ^(TFY_PlayerController *player) {
        @player_strongify(self)
        NSLog(@"画中画已经停止");
        self.pipBtn.selected = NO;
        [self updatePipButtonTitle];
    };
    
    self.player.pipFailedToStart = ^(TFY_PlayerController *player, NSError *error) {
        @player_strongify(self)
        NSLog(@"画中画启动失败: %@", error.localizedDescription);
        self.pipBtn.selected = NO;
        [self updatePipButtonTitle];
    };
    
    self.player.pipRestoreUserInterface = ^(TFY_PlayerController *player, void(^completion)(BOOL restored)) {
        @player_strongify(self)
        NSLog(@"画中画需要恢复用户界面");
        // 如果正在处理画中画连续播放，不恢复用户界面
        if (player.isHandlingPipContinuousPlay) {
            NSLog(@"正在处理画中画连续播放，不恢复用户界面");
            if (completion) {
                completion(NO);
            }
        } else {
            // 确保界面正确恢复
            if (completion) {
                completion(YES);
            }
        }
    };
    
    self.player.assetURLs = self.assetURLs;
    [self.player playTheIndex:0];
    [self.controlView showTitle:@"iPhone X" coverURLString:kVideoCover fullScreenMode:FullScreenModeAutomatic];
}

- (void)picBtnClick:(UIButton *)sender {
    if ([self.player isPictureInPictureSupported]) {
        if ([self.player isPictureInPictureActive]) {
            [self.player stopPictureInPicture];
            sender.selected = NO;
        } else {
            [self.player startPictureInPicture];
            sender.selected = YES;
        }
        [self updatePipButtonTitle];
    } else {
        NSLog(@"当前设备不支持画中画功能");
    }
}

- (void)updatePipButtonTitle {
    if ([self.player isPictureInPictureActive]) {
        [self.pipBtn setTitle:@"关闭画中画" forState:UIControlStateNormal];
    } else {
        [self.pipBtn setTitle:@"开启画中画" forState:UIControlStateNormal];
    }
}

- (void)changeVideo:(UIButton *)sender {
    NSString *URLString = @"https://www.apple.com.cn/105/media/cn/airpods-pro/2022/d2deeb8e-83eb-48ea-9721-f567cf0fffa8/films/under-the-spell/airpods-pro-under-the-spell-tpl-cn-2022_16x9.m3u8";
    self.player.assetURL = [NSURL URLWithString:URLString];
    [self.controlView showTitle:@"AirPods" coverURLString:kVideoCover fullScreenMode:FullScreenModeAutomatic];
}

- (void)playClick:(UIButton *)sender {
    [self.player playTheIndex:0];
    [self.controlView showTitle:@"视频标题" coverURLString:kVideoCover fullScreenMode:FullScreenModeAutomatic];
}

- (void)nextClick:(UIButton *)sender {
    if (!self.player.isLastAssetURL) {
        [self.player playTheNext];
        NSString *title = [NSString stringWithFormat:@"视频标题%zd",self.player.currentPlayIndex];
        [self.controlView showTitle:title coverURLString:kVideoCover fullScreenMode:FullScreenModeAutomatic];
    } else {
        NSLog(@"最后一个视频了");
    }
}

- (void)pushNewVC {
    TFYNotAutoPlayViewController *vc = [[TFYNotAutoPlayViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
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
        _controlView.prepareShowControlView = NO;
        _controlView.showCustomStatusBar = YES;
    }
    return _controlView;
}

- (UIImageView *)containerView {
    if (!_containerView) {
        _containerView = [UIImageView new];
        [_containerView sd_setImageWithURL:[NSURL URLWithString:kVideoCover] placeholderImage:[UIImage tfy_createImage:UIColor.redColor]];
    }
    return _containerView;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamed:@"new_allPlay_44x44_"] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)changeBtn {
    if (!_changeBtn) {
        _changeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_changeBtn setTitle:@"Change video" forState:UIControlStateNormal];
        [_changeBtn addTarget:self action:@selector(changeVideo:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _changeBtn;
}

- (UIButton *)nextBtn {
    if (!_nextBtn) {
        _nextBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_nextBtn setTitle:@"Next" forState:UIControlStateNormal];
        [_nextBtn addTarget:self action:@selector(nextClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nextBtn;
}

- (UIButton *)pipBtn {
    if (!_pipBtn) {
        _pipBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_pipBtn setTitle:@"开启画中画" forState:UIControlStateNormal];
        [_pipBtn addTarget:self action:@selector(picBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pipBtn;
}

- (NSArray<NSURL *> *)assetURLs {
    if (!_assetURLs) {
        NSString *url = [@"https://tj-data-bak-to-test20221028.oss-cn-hangzhou.aliyuncs.com/uploadFiles/images/app/banner/浙大妙智康宣传片.mp4" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet  URLQueryAllowedCharacterSet]];
        _assetURLs = @[[NSURL URLWithString:@"https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4"],
                       [NSURL URLWithString:@"https://www.apple.com/105/media/cn/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/bruce/mac-bruce-tpl-cn-2018_1280x720h.mp4"],
                       [NSURL URLWithString:@"https://www.apple.com/105/media/us/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/peter/mac-peter-tpl-cc-us-2018_1280x720h.mp4"],
                       [NSURL URLWithString:@"https://www.apple.com/105/media/us/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/grimes/mac-grimes-tpl-cc-us-2018_1280x720h.mp4"],
                       [NSURL URLWithString:@"https://cdn.cnbj1.fds.api.mi-img.com/mi-mall/7194236f31b2e1e3da0fe06cfed4ba2b.mp4"],
                       [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"],
                       [NSURL URLWithString:@"http://vjs.zencdn.net/v/oceans.mp4"],
                       [NSURL URLWithString:@"https://media.w3.org/2010/05/sintel/trailer.mp4"],
                       [NSURL URLWithString:@"http://mirror.aarnet.edu.au/pub/TED-talks/911Mothers_2010W-480p.mp4"],
                       [NSURL URLWithString:url],
                       [NSURL URLWithString:@"https://sample-videos.com/video123/mp4/480/big_buck_bunny_480p_2mb.mp4"]];
    }
    return _assetURLs;
}

@end
