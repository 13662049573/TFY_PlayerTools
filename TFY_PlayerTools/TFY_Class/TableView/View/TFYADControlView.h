//
//  TFYADControlView.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFYADControlView : UIView<TFY_PlayerMediaControl>

@property (nonatomic, copy) void(^skipCallback)(void);

@property (nonatomic, copy) void(^fullScreenCallback)(void);

@end

NS_ASSUME_NONNULL_END
