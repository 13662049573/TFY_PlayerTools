//
//  UIViewController+LM_Util.m
//  Femalepregnancy
//
//  Created by tiandengyou on 2019/12/30.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "UIViewController+LM_Util.h"
#import <objc/runtime.h>
#import "AppDelegate.h"

#define AtAppDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

//定义常量 必须是C语言字符串
static char *FullScreenAllowRotationKey = "FullScreenAllowRotationKey";

@implementation UIViewController (LM_Util)

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector){
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

/**
 *  是否允许横屏 bool YES 允许 NO 不允许
 */
- (BOOL)shouldAutorotate1{
    NSNumber *number = objc_getAssociatedObject(self, FullScreenAllowRotationKey);
    BOOL flag = number.boolValue;
    return flag;
}

/**
 * 屏幕方向  屏幕方向
 */
- (UIInterfaceOrientationMask)supportedInterfaceOrientations1{
    //get方法通过key获取对象
    NSNumber *number = objc_getAssociatedObject(self, FullScreenAllowRotationKey);
    BOOL flag = number.boolValue;
    if (flag) {
        return UIInterfaceOrientationMaskLandscapeLeft;
    }else{
        return UIInterfaceOrientationMaskPortrait;
    }
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation1{
    NSNumber *number = objc_getAssociatedObject(self, FullScreenAllowRotationKey);
    BOOL flag = number.boolValue;
    if (flag) {
        return UIInterfaceOrientationLandscapeLeft;
    }else{
        return UIInterfaceOrientationPortrait;
    }
}

/**
 * 强制横屏方法  fullscreen 屏幕方向
 */
- (void)setNewOrientation:(BOOL)fullscreen{
//    AtAppDelegate.allowRotation = fullscreen;
     objc_setAssociatedObject(self, FullScreenAllowRotationKey,[NSNumber numberWithBool:fullscreen], OBJC_ASSOCIATION_ASSIGN);
    
    swizzleMethod([self class], @selector(shouldAutorotate), @selector(shouldAutorotate1));
    swizzleMethod([self class], @selector(supportedInterfaceOrientations), @selector(supportedInterfaceOrientations1));
    swizzleMethod([self class], @selector(preferredInterfaceOrientationForPresentation), @selector(preferredInterfaceOrientationForPresentation1));
    
    @autoreleasepool {
        if (fullscreen) {
            NSNumber *resetOrientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
            [[UIDevice currentDevice] setValue:resetOrientationTarget forKey:@"orientation"];
            NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft];
            [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
        }else{
            NSNumber *resetOrientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationUnknown];
            [[UIDevice currentDevice] setValue:resetOrientationTarget forKey:@"orientation"];
            NSNumber *orientationTarget = [NSNumber numberWithInt:UIInterfaceOrientationPortrait];
            [[UIDevice currentDevice] setValue:orientationTarget forKey:@"orientation"];
        }
    }
}

@end
