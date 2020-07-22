//
//  UIViewController+LM_Util.h
//  Femalepregnancy
//
//  Created by tiandengyou on 2019/12/30.
//  Copyright © 2019 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (LM_Util)
/**
 * 强制横屏方法
 * 横屏(如果属性值为YES,仅允许屏幕向左旋转,否则仅允许竖屏)
 * fullscreen 屏幕方向
 */
- (void)setNewOrientation:(BOOL)fullscreen;
@end

NS_ASSUME_NONNULL_END
