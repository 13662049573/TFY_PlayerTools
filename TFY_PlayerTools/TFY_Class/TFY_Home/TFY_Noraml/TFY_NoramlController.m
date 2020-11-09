//
//  TFY_NoramlController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/17.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_NoramlController.h"

@interface TFY_NoramlController ()
TFY_PROPERTY_STRONG TFY_PlayerView *controlView;
TFY_PROPERTY_STRONG NSArray <TFY_PlayerVideoModel *>*assetURLs;
TFY_PROPERTY_STRONG UIButton *playBtn;
TFY_PROPERTY_STRONG UIButton *changeBtn;
TFY_PROPERTY_STRONG UIButton *nextBtn;
@end

@implementation TFY_NoramlController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.imageViews];
    self.imageViews.tfy_LeftSpace(0).tfy_TopSpace(0).tfy_RightSpace(0).tfy_Height(TFY_PLAYER_ScreenW*9/16);
    
    [self.imageViews addSubview:self.playBtn];
    self.playBtn.tfy_Center(0, 0).tfy_size(44, 44);
    
    [self.view addSubview:self.changeBtn];
    self.changeBtn.tfy_LeftSpace(30).tfy_RightSpace(30).tfy_TopSpaceToView(40, self.imageViews).tfy_Height(50);
    
    [self.view addSubview:self.nextBtn];
    self.nextBtn.tfy_LeftSpaceEqualView(self.changeBtn).tfy_RightSpaceEqualView(self.changeBtn).tfy_TopSpaceToView(30, self.changeBtn).tfy_Height(50);
    
    self.player = [TFY_PlayerController playerWithPlayerManagercontainerView:self.imageViews];
    self.player.controlView = self.controlView;
       // 设置退到后台继续播放
    self.player.pauseWhenAppResignActive = NO;
       //键盘开启转向
    self.player.forceDeviceOrientation = YES;
    
    /// 播放完成
    TFY_PLAYER_WS(myself);
   self.player.playerDidToEnd = ^(id  _Nonnull asset) {
       [myself.player.currentPlayerManager replay];
       [myself.player playTheNext];
       if (!myself.player.isLastAssetURL) {
           NSString *title = [NSString stringWithFormat:@"视频标题%zd",myself.player.currentPlayIndex];
           [myself.controlView showTitle:title coverURLString:kVideoCover fullScreenMode:FullScreenModeLandscape];
       } else {
           [myself.player stop];
       }
   };
    
    self.player.assetUrlMododels = self.assetURLs;
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

- (UIButton *)changeBtn{
    if (!_changeBtn) {
        _changeBtn = UIButtonSet();
        _changeBtn.makeChain
        .text(@"改变视频", UIControlStateNormal)
        .textColor([UIColor tfy_colorWithHex:LCColor_B5], UIControlStateNormal)
        .font([UIFont systemFontOfSize:16 weight:UIFontWeightBold])
        .cornerRadius(25)
        .backgroundColor([UIColor tfy_colorWithHex:LCColor_A3])
        .addTarget(self, @selector(changeVideo), UIControlEventTouchUpInside);
    }
    return _changeBtn;
}

- (UIButton *)nextBtn{
    if (!_nextBtn) {
        _nextBtn = UIButtonSet();
        _nextBtn.makeChain
        .text(@"下一个", UIControlStateNormal)
        .textColor([UIColor tfy_colorWithHex:LCColor_B5], UIControlStateNormal)
        .font([UIFont systemFontOfSize:16 weight:UIFontWeightBold])
        .cornerRadius(25).backgroundColor([UIColor tfy_colorWithHex:LCColor_A3])
        .addTarget(self, @selector(nextClick), UIControlEventTouchUpInside);
    }
    return _nextBtn;
}

- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
        _controlView.fastViewAnimated = YES;
        _controlView.autoHiddenTimeInterval = 5;
        _controlView.autoFadeTimeInterval = 0.5;
        _controlView.prepareShowLoading = YES;
        _controlView.prepareShowControlView = YES;
    }
    return _controlView;
}

- (void)playClick:(UIButton *)sender {
    [self.player playTheIndex:0];
    [self.controlView showTitle:@"视频标题" coverURLString:kVideoCover fullScreenMode:FullScreenModeAutomatic];
}

- (void)changeVideo{
    NSString *URLString = @"https://www.apple.com/105/media/cn/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/bruce/mac-bruce-tpl-cn-2018_1280x720h.mp4";
   TFY_PlayerVideoModel *modes = [TFY_PlayerVideoModel new];
   modes.tfy_name = @"这是一条测试数据";
   modes.tfy_url = URLString;
   modes.tfy_pic = kVideoCover;
   self.player.assetUrlModel = modes;
   [self.controlView showTitle:modes.tfy_name coverURLString:kVideoCover fullScreenMode:FullScreenModeAutomatic];
}

- (void)nextClick{
    if (!self.player.isLastAssetURL) {
        [self.player playTheNext];
        NSString *title = [NSString stringWithFormat:@"视频标题%zd",self.player.currentPlayIndex];

        [self.controlView showTitle:title coverURLString:kVideoCover fullScreenMode:FullScreenModeAutomatic];
    }
}

- (NSArray<TFY_PlayerVideoModel *> *)assetURLs {
    if (!_assetURLs) {
        TFY_PlayerVideoModel *modes1 = [TFY_PlayerVideoModel new];
        modes1.tfy_url = @"https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4";
        
        TFY_PlayerVideoModel *modes2 = [TFY_PlayerVideoModel new];
        modes2.tfy_url = @"https://www.apple.com/105/media/cn/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/bruce/mac-bruce-tpl-cn-2018_1280x720h.mp4";
        
        TFY_PlayerVideoModel *modes3 = [TFY_PlayerVideoModel new];
        modes3.tfy_url = @"https://www.apple.com/105/media/us/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/peter/mac-peter-tpl-cc-us-2018_1280x720h.mp4";
        
        TFY_PlayerVideoModel *modes4 = [TFY_PlayerVideoModel new];
        modes4.tfy_url = @"https://www.apple.com/105/media/us/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/grimes/mac-grimes-tpl-cc-us-2018_1280x720h.mp4";
        
        TFY_PlayerVideoModel *modes5 = [TFY_PlayerVideoModel new];
        modes5.tfy_url = @"http://220.249.115.46:18080/wav/no.9.mp4";
        
        TFY_PlayerVideoModel *modes6 = [TFY_PlayerVideoModel new];
        modes6.tfy_url = @"http://220.249.115.46:18080/wav/day_by_day.mp4";
        
        TFY_PlayerVideoModel *modes7 = [TFY_PlayerVideoModel new];
        modes7.tfy_url = @"http://220.249.115.46:18080/wav/Lovey_Dovey.mp4";
        
        _assetURLs = @[modes1,modes2,modes3,modes4,modes5,modes6,modes7];
         
    }
    return _assetURLs;
}


@end
