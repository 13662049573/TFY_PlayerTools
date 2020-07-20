//
//  UIResponder+LM_Navigation.m
//  Femalepregnancy
//
//  Created by tiandengyou on 2019/12/6.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "UIResponder+LM_Navigation.h"

@implementation UIResponder (LM_Navigation)

-(TFY_NavigationController *)navcontroller:(UIViewController *)vc{
    TFY_NavigationController *nav = [[TFY_NavigationController alloc] initWithRootViewController:vc];
    nav.backimage = [UIImage tfy_imageFromGradientColors:@[[UIColor tfy_colorWithHex:LCColor_A4],[UIColor tfy_colorWithHex:LCColor_A5]] gradientType:TFY_GradientTypeUprightToLowleft imageSize:CGSizeMake(TFY_Width_W, TFY_kNavBarHeight)];
    nav.backIconImage = [[UIImage imageNamed:@"Return-white"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    nav.titleColor = [UIColor tfy_colorWithHex:LCColor_B5];
    return nav;
}

@end
