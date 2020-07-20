//
//  TFY_DouYinPlayerView.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/19.
//  Copyright © 2020 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFY_DouYinPlayerView : UIView<TFY_PlayerMediaControl>
- (void)resetControlView;

- (void)showCoverViewWithUrl:(NSString *)coverUrl withImageMode:(UIViewContentMode)contentMode;
@end

NS_ASSUME_NONNULL_END
