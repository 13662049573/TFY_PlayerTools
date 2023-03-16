//
//  TFYTableHeaderView.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TFYTableData.h"
NS_ASSUME_NONNULL_BEGIN

@interface TFYTableHeaderView : UIView

@property (nonatomic, strong) TFYTableData *data;
@property (nonatomic, strong, readonly) UIImageView *coverImageView;

@property (nonatomic, copy) void(^playCallback)(void);
@end

NS_ASSUME_NONNULL_END
