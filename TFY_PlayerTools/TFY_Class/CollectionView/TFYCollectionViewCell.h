//
//  TFYCollectionViewCell.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TFYTableData.h"

NS_ASSUME_NONNULL_BEGIN

@interface TFYCollectionViewCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIButton *playBtn;
/// 播放按钮block
@property (nonatomic, copy  ) void(^playBlock)(UIButton *sender);

@property (nonatomic, strong) TFYTableData *data;
@end

NS_ASSUME_NONNULL_END
