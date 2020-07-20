//
//  TFY_DouyinCollectionView.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "PlayerAController.h"

NS_ASSUME_NONNULL_BEGIN

@interface TFY_DouyinCollectionView : PlayerAController

- (void)playTheIndex:(NSInteger)index;

@property (nonatomic) UICollectionViewScrollDirection scrollDirection;
@end

NS_ASSUME_NONNULL_END
