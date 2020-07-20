//
//  TableViewCellDelegate.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/19.
//  Copyright © 2020 田风有. All rights reserved.
//


@protocol TableViewCellDelegate <NSObject>

- (void)tfy_playTheVideoAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol UICollectionCellDelegate <NSObject>

- (void)tfy_playTheVideoAtIndexPath:(NSIndexPath *)indexPath;

@end
