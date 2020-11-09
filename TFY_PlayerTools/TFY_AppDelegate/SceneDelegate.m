//
//  SceneDelegate.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/16.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "SceneDelegate.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions  API_AVAILABLE(ios(13.0)){
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    [self.window tfy_showOnScene:scene];
}

@end
