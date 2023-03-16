//
//  TFYKeyboardViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYKeyboardViewController.h"
#import "UIView+PlayerFrame.h"

@interface TFYKeyboardViewController ()
@property (nonatomic, strong) TFY_PlayerController *player;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) TFY_PlayerControlView *controlView;
@property (nonatomic, strong) UITextField *textField;

@end

@implementation TFYKeyboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.containerView];
    [self.controlView addSubview:self.textField];
    
    TFY_AVPlayerManager *playerManager = [[TFY_AVPlayerManager alloc] init];
    /// 播放器相关
    self.player = [[TFY_PlayerController alloc] initWithPlayerManager:playerManager containerView:self.containerView];
    self.player.controlView = self.controlView;
    @player_weakify(self)
    self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        @player_strongify(self)
        [self.textField resignFirstResponder];
    };
    
    self.player.orientationDidChanged = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        @player_strongify(self)
        [self updateTextFieldLayout];
    };
    
    NSString *URLString = [@"https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    playerManager.assetURL = [NSURL URLWithString:URLString];
    
    [self.controlView showTitle:@"视频标题" coverURLString:@"https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" fullScreenMode:FullScreenModeLandscape];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect frame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    if (self.player.isFullScreen) {
        [UIView animateWithDuration:duration animations:^{
            self.textField.player_bottom = self.controlView.player_height - CGRectGetHeight(frame);
        }];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat x = 0;
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat w = CGRectGetWidth(self.view.frame);
    CGFloat h = w*9/16;
    self.containerView.frame = CGRectMake(x, y, w, h);
    [self updateTextFieldLayout];
}

- (void)updateTextFieldLayout {
    CGFloat w = 200;
    CGFloat h = 35;
    CGFloat x = (self.controlView.player_width - w)/2;
    CGFloat y = self.controlView.player_height - h - 60;
    self.textField.frame = CGRectMake(x, y, w, h);
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

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.textField resignFirstResponder];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (TFY_PlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerControlView new];
        _controlView.prepareShowControlView = YES;
        _controlView.prepareShowLoading = YES;
    }
    return _controlView;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        _textField.backgroundColor = [UIColor whiteColor];
        _textField.placeholder = @"Click on the input";
    }
    return _textField;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
    }
    return _containerView;
}


@end
