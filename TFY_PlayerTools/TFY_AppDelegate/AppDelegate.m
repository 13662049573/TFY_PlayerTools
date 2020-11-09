//
//  AppDelegate.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/16.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "AppDelegate.h"
#import "LM_TabBarController.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 启动图片延时: 2秒
    [NSThread sleepForTimeInterval:1.5];
    
    [TFY_ServerConfig setTFY_ConfigEnv:@"01"];
    //配置导航栏
    [TFY_Configure setupCustomConfigure:^(TFYNavigationBarConfigure * _Nonnull configure) {
        configure.backImage = [UIImage tfy_imageFromGradientColors:@[[UIColor tfy_colorWithHex:LCColor_A4],[UIColor tfy_colorWithHex:LCColor_A5]] gradientType:TFY_GradientTypeUprightToLowleft imageSize:CGSizeMake(TFY_Width_W(), TFY_kNavBarHeight())];
        configure.backStyle = TFYNavigationBarBackStyleWhite;
        configure.titleColor = [UIColor tfy_colorWithHex:LCColor_B5];
    }];
    
    if (!TFY_ScenePackage.isSceneApp) {
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.window.backgroundColor = [UIColor whiteColor];
        [self.window makeKeyAndVisible];
    }
    [TFY_ScenePackage addBeforeWindowEvent:^(TFY_Scene * _Nonnull application) {
        [UIApplication tfy_window].rootViewController = [LM_TabBarController new];
    }];
    return YES;
}


- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    if(self.enablePortrait)
    {
        if (self.lockedScreen) {
            return UIInterfaceOrientationMaskLandscape;
        }
        return UIInterfaceOrientationMaskLandscape | UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskPortrait;
}
@end
