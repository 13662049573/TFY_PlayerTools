//
//  TFY_TableHeaderView.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFY_TableHeaderView : UIView

@property (nonatomic, strong, readonly) UIImageView *coverImageView;

@property (nonatomic, copy) void(^playCallback)(void);
@end

NS_ASSUME_NONNULL_END
