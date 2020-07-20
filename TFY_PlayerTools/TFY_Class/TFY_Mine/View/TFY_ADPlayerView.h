//
//  TFY_ADPlayerView.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFY_ADPlayerView : UIView<TFY_PlayerMediaControl>
@property (nonatomic, copy) void(^skipCallback)(void);

@property (nonatomic, copy) void(^fullScreenCallback)(void);
@end

NS_ASSUME_NONNULL_END
