//
//  TFYTableViewCell.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TFYTableData.h"
#import "TFYTableViewCellLayout.h"
NS_ASSUME_NONNULL_BEGIN

@protocol TFYTableViewCellDelegate <NSObject>

- (void)tfy_playTheVideoAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface TFYTableViewCell : UITableViewCell

@property (nonatomic, strong) TFYTableViewCellLayout *layout;

@property (nonatomic, strong, readonly) UIImageView *coverImageView;

@property (nonatomic, copy) void(^playCallback)(void);

- (void)setDelegate:(id<TFYTableViewCellDelegate>)delegate withIndexPath:(NSIndexPath *)indexPath;

- (void)showMaskView;

- (void)hideMaskView;

- (void)setNormalMode;

@end

NS_ASSUME_NONNULL_END
