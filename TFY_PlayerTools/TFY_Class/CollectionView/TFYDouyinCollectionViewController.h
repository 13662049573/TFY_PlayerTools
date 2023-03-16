//
//  TFYDouyinCollectionViewController.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFYDouyinCollectionViewController : UIViewController

@property (nonatomic, assign) PlayerScrollViewDirection scrollViewDirection;

- (void)playTheIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
