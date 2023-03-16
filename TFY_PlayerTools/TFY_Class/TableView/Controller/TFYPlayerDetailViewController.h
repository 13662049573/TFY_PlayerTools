//
//  TFYPlayerDetailViewController.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFYPlayerDetailViewController : UIViewController

@property (nonatomic, strong) TFY_PlayerController *player;

@property (nonatomic, copy) void(^detailVCPopCallback)();

@property (nonatomic, copy) void(^detailVCPlayCallback)();

@end

NS_ASSUME_NONNULL_END
