//
//  TFY_LightTableViewCell.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/19.
//  Copyright © 2020 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableViewCellDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TFY_LightTableViewCell : UITableViewCell

TFY_CATEGORY_STRONG_PROPERTY TFY_ListModel *listModel;

- (void)setDelegate:(id<TableViewCellDelegate>)delegate withIndexPath:(NSIndexPath *)indexPath;

- (void)showMaskView;

- (void)hideMaskView;

- (void)setNormalMode;

@end

NS_ASSUME_NONNULL_END
