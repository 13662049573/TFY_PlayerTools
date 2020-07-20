//
//  TFY_RotationController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_RotationController.h"

@interface TFY_RotationController ()
TFY_CATEGORY_STRONG_PROPERTY TFY_PlayerView *controlView;
TFY_CATEGORY_STRONG_PROPERTY UISwitch *switch1,*switch2;
TFY_CATEGORY_STRONG_PROPERTY UILabel *name_label1,*name_label2;
@end

@implementation TFY_RotationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.imageViews];
    self.imageViews.tfy_LeftSpace(0).tfy_TopSpace(0).tfy_RightSpace(0).tfy_Height(TFY_PLAYER_ScreenW*9/16);
    
    
    [self.view addSubview:self.switch1];
    self.switch1.tfy_LeftSpace(30).tfy_TopSpaceToView(50, self.imageViews).tfy_size(50, 30);
    
    [self.view addSubview:self.name_label1];
    self.name_label1.tfy_LeftSpaceEqualView(self.switch1).tfy_TopSpaceToView(0, self.switch1).tfy_size(Player_ScreenWidth/2-30, 40);
    
    [self.view addSubview:self.switch2];
    self.switch2.tfy_RightSpace(30).tfy_TopSpaceEqualView(self.switch1).tfy_size(50, 30);
    
    [self.view addSubview:self.name_label2];
    self.name_label2.tfy_RightSpaceEqualView(self.switch2).tfy_TopSpaceToView(0, self.switch2).tfy_size(Player_ScreenWidth/2-30, 40);
    
    
   self.player = [TFY_PlayerController playerWithPlayerManagercontainerView:self.imageViews];
   self.player.controlView = self.controlView;
    self.player.allowOrentitaionRotation =YES;
    @weakify(self)
   self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
       @strongify(self)
       [self setNeedsStatusBarAppearanceUpdate];
   };
    
    TFY_PlayerVideoModel *modes6 = [TFY_PlayerVideoModel new];
    modes6.tfy_url = @"http://220.249.115.46:18080/wav/day_by_day.mp4";
    
    self.player.assetUrlModel = modes6;
}

-(UISwitch *)switch1{
    if (!_switch1) {
        _switch1 = [[UISwitch alloc] init];
        _switch1.tag = 1;
        [_switch1 addTarget:self action:@selector(switch1Click:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switch1;
}

-(UISwitch *)switch2{
    if (!_switch2) {
        _switch2 = [[UISwitch alloc] init];
        _switch2.tag = 2;
        _switch2.on = YES;
        [_switch2 addTarget:self action:@selector(switch1Click:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switch2;
}

-(UILabel *)name_label1{
    if (!_name_label1) {
        _name_label1 = tfy_label();
        _name_label1.tfy_text(@"开启控制器旋转").tfy_fontSize([UIFont systemFontOfSize:14 weight:UIFontWeightRegular]).tfy_alignment(0).tfy_textcolor(LCColor_A1, 1);
    }
    return _name_label1;
}

-(UILabel *)name_label2{
    if (!_name_label2) {
        _name_label2 = tfy_label();
        _name_label2.tfy_text(@"是否开启自动旋转").tfy_fontSize([UIFont systemFontOfSize:14 weight:UIFontWeightRegular]).tfy_alignment(2).tfy_textcolor(LCColor_A1, 1);
    }
    return _name_label2;
}

- (void)switch1Click:(UISwitch *)sender{
    if (sender.tag == 1) {
        self.player.forceDeviceOrientation = sender.isOn;
    }
    if (sender.tag == 2) {
        self.player.allowOrentitaionRotation = sender.isOn;
    }
}

- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
    }
    return _controlView;
}

@end
