//
//  TFY_AutoPlayerCell.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/17.
//  Copyright © 2020 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TFY_RootModel.h"
#import "TableViewCellDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TFY_AutoPlayerCell : UITableViewCell

TFY_PROPERTY_STRONG TFY_ListModel *listModel;

@property (weak, nonatomic)id<TableViewCellDelegate> delegate;

@property (strong, nonatomic)NSIndexPath *indexPath;

@end

NS_ASSUME_NONNULL_END
