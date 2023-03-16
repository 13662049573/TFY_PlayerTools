//
//  AppDelegate.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/16.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "AppDelegate.h"
#import "LM_TabBarController.h"
#import "TFY_PlayerTool.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 启动图片延时: 2秒
    [NSThread sleepForTimeInterval:1.5];
    
    [TFY_ServerConfig setTFY_ConfigEnv:@"01"];
    
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


/// 在这里写支持的旋转方向，为了防止横屏方向，应用启动时候界面变为横屏模式
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    InterfaceOrientationMask orientationMask = [TFY_LandscapeRotationManager supportedInterfaceOrientationsForWindow:window];
    if (orientationMask != InterfaceOrientationMaskUnknow) {
        return (UIInterfaceOrientationMask)orientationMask;
    }
    /// 这里是非播放器VC支持的方向
    return UIInterfaceOrientationMaskPortrait;
}

@end
