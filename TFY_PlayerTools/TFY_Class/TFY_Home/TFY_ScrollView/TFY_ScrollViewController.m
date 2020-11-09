//
//  TFY_ScrollViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/18.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_ScrollViewController.h"

@interface TFY_ScrollViewController ()<UIScrollViewDelegate>
TFY_PROPERTY_STRONG TFY_PlayerView *controlView;
TFY_PROPERTY_STRONG UIScrollView *scrollView;
TFY_PROPERTY_STRONG UIButton *playBtn;
@end

@implementation TFY_ScrollViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.scrollView];
    [self.scrollView tfy_AutoSize:0 top:0 right:0 bottom:0];
    
    [self.scrollView addSubview:self.imageViews];
    self.imageViews.tfy_Center(0, 0).tfy_size(TFY_PLAYER_ScreenW, TFY_PLAYER_ScreenW*9/16);
    
    [self.imageViews addSubview:self.playBtn];
    self.playBtn.tfy_Center(0, 0).tfy_size(44, 44);
    
    self.player = [[TFY_PlayerController alloc] initWithScrollView:self.scrollView containerView:self.imageViews];
    self.player.controlView = self.controlView;
    self.player.playerDisapperaPercent = 1.0;
    self.player.playerApperaPercent = 0.0;
    /// 播放小窗相关
    self.player.stopWhileNotVisible = NO;
    
    CGFloat margin = 20;
    CGFloat w = TFY_PLAYER_ScreenW/2;
    CGFloat h = w * 9/16;
    CGFloat x = TFY_PLAYER_ScreenW - w - margin;
    CGFloat y = TFY_PLAYER_ScreenH - h - margin;
    self.player.smallFloatView.frame = CGRectMake(x, y, w, h);
    
    @weakify(self)
   self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
       @strongify(self)
       [self setNeedsStatusBarAppearanceUpdate];
   };
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [scrollView tfy_scrollViewDidScroll];
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.delegate = self;
        _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 2000);
    }
    return _scrollView;
}
- (UIButton *)playBtn{
    if (!_playBtn) {
        _playBtn = UIButtonSet();
        _playBtn.makeChain
        .image([UIImage imageNamed:@"new_allPlay_44x44_"], UIControlStateNormal)
        .addTarget(self, @selector(playClick:), UIControlEventTouchUpInside);
    }
    return _playBtn;
}

- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
        _controlView.prepareShowLoading = YES;
    }
    return _controlView;
}

- (void)playClick:(UIButton *)sender {
    NSString *URLString = @"http://220.249.115.46:18080/wav/day_by_day.mp4";
    TFY_PlayerVideoModel *modes = [TFY_PlayerVideoModel new];
    modes.tfy_name = @"这是一条测试数据";
    modes.tfy_url = URLString;
    self.player.assetUrlModel = modes;
    [self.controlView showTitle:modes.tfy_name coverURLString:kVideoCover fullScreenMode:FullScreenModeAutomatic];
}
@end
