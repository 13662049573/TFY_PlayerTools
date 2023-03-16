//
//  TFYDouYinCell.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TFYTableData.h"
#import "TFYDouYinCellDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TFYDouYinCell : UITableViewCell

@property (nonatomic, strong) TFYTableData *data;

@property (nonatomic, weak) id<TFYDouYinCellDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
