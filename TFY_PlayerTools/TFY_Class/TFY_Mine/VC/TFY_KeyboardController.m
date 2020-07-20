//
//  TFY_KeyboardController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_KeyboardController.h"

@interface TFY_KeyboardController ()
TFY_CATEGORY_STRONG_PROPERTY TFY_PlayerView *controlView;
@property (nonatomic, strong) UITextField *textField;
@end

@implementation TFY_KeyboardController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.imageViews];
    self.imageViews.tfy_LeftSpace(0).tfy_TopSpace(0).tfy_RightSpace(0).tfy_Height(TFY_PLAYER_ScreenW*9/16);
    
    [self.controlView addSubview:self.textField];
    self.textField.tfy_Center(0, 0).tfy_size(TFY_PLAYER_ScreenW/2, 50);
    
    self.player = [TFY_PlayerController playerWithPlayerManagercontainerView:self.imageViews];
    self.player.controlView = self.controlView;
    self.player.allowOrentitaionRotation =YES;
    self.player.forceDeviceOrientation = YES;
    @weakify(self)
   self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
       @strongify(self)
       self.view.backgroundColor = isFullScreen ? [UIColor blackColor] : [UIColor whiteColor];
       [self.textField resignFirstResponder];
       [self setNeedsStatusBarAppearanceUpdate];
   };
    
    TFY_PlayerVideoModel *modes6 = [TFY_PlayerVideoModel new];
    modes6.tfy_url = @"http://220.249.115.46:18080/wav/day_by_day.mp4";
       
    self.player.assetUrlModel = modes6;
    
     [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.textField resignFirstResponder];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect frame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSLog(@"%@",NSStringFromCGRect(frame));
}

- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
        _controlView.prepareShowControlView = YES;
        _controlView.prepareShowLoading = YES;
    }
    return _controlView;
}
- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.backgroundColor = [UIColor orangeColor];
        _textField.placeholder = @"随意输入吧";
    }
    return _textField;
}
@end
