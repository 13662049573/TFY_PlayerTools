//
//  TFY_FullScreenController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_FullScreenController.h"

@interface TFY_FullScreenController ()
TFY_CATEGORY_STRONG_PROPERTY TFY_PlayerView *controlView;
@end

@implementation TFY_FullScreenController

- (void)viewDidLoad {
    [super viewDidLoad];
    @weakify(self)
    self.controlView.backBtnClickCallback = ^{
        @strongify(self)
        [self.player enterFullScreen:NO animated:NO];
        [self.player stop];
        [self.navigationController popViewControllerAnimated:NO];
    };
    
    self.player = [[TFY_PlayerController alloc] initWithPlayerManagercontainerView:[ScenePackage defaultPackage].window];
    self.player.controlView = self.controlView;
    self.player.orientationObserver.supportInterfaceOrientation = InterfaceOrientationMaskLandscape;
    [self.player enterFullScreen:YES animated:NO];
    
    TFY_PlayerVideoModel *modes6 = [TFY_PlayerVideoModel new];
    modes6.tfy_url = @"http://220.249.115.46:18080/wav/day_by_day.mp4";
       
    self.player.assetUrlModel = modes6;
    
}

- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
        _controlView.fastViewAnimated = YES;
        _controlView.effectViewShow = NO;
        _controlView.prepareShowLoading = YES;
    }
    return _controlView;
}
@end
