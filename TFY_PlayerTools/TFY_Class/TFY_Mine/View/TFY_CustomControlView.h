//
//  TFY_CustomControlView.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFY_CustomControlView : UIView<TFY_PlayerMediaControl>
/// 控制层自动隐藏的时间，默认2.5秒
@property (nonatomic, assign) NSTimeInterval autoHiddenTimeInterval;

/// 控制层显示、隐藏动画的时长，默认0.25秒
@property (nonatomic, assign) NSTimeInterval autoFadeTimeInterval;

/**
 设置标题、封面、全屏模式
  title 视频的标题
  coverUrl 视频的封面，占位图默认是灰色的
  fullScreenMode 全屏模式
 */
- (void)showTitle:(NSString *)title coverURLString:(NSString *)coverUrl fullScreenMode:(FullScreenMode)fullScreenMode;
@end

NS_ASSUME_NONNULL_END
