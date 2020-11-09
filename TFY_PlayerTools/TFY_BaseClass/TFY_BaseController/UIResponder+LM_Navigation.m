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
    return nav;
}

@end
