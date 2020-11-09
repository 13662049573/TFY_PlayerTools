//
//  TFY_RotationController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_RotationController.h"

@interface TFY_RotationController ()
TFY_PROPERTY_STRONG TFY_PlayerView *controlView;
TFY_PROPERTY_STRONG UISwitch *switch1,*switch2;
TFY_PROPERTY_STRONG UILabel *name_label1,*name_label2;
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
        _switch1 = UISwitchSet();
        _switch1.makeChain.makeTag(1).addTarget(self, @selector(switch1Click:), UIControlEventTouchUpInside);
    }
    return _switch1;
}

-(UISwitch *)switch2{
    if (!_switch2) {
        _switch2 = UISwitchSet();
        _switch2.makeChain.makeTag(2).on(YES).addTarget(self, @selector(switch1Click:), UIControlEventTouchUpInside);
    }
    return _switch2;
}

-(UILabel *)name_label1{
    if (!_name_label1) {
        _name_label1 =UILabelSet();
        _name_label1.makeChain
        .text(@"开启控制器旋转")
        .font([UIFont systemFontOfSize:14 weight:UIFontWeightRegular])
        .textAlignment(NSTextAlignmentCenter)
        .textColor([UIColor tfy_colorWithHex:LCColor_A1]);
    }
    return _name_label1;
}

-(UILabel *)name_label2{
    if (!_name_label2) {
        _name_label2 = UILabelSet();
        _name_label2.makeChain
        .text(@"是否开启自动旋转")
        .font([UIFont systemFontOfSize:14 weight:UIFontWeightRegular])
        .textAlignment(NSTextAlignmentRight)
        .textColor([UIColor tfy_colorWithHex:LCColor_A1]);
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
