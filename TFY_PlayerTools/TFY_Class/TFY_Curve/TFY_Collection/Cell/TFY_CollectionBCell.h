//
//  TFY_CollectionBCell.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFY_CollectionBCell : UICollectionViewCell
TFY_CATEGORY_STRONG_PROPERTY TFY_ListModel *listModel;

@property (nonatomic, copy  ) void(^playBlock)(UIButton *sender);
@end

NS_ASSUME_NONNULL_END
