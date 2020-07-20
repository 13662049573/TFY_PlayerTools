//
//  PlayerAController.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/17.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "BaseViewController.h"
#import "TFY_RootModel.h"


static NSString * _Nonnull kVideoCover = @"https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240";

NS_ASSUME_NONNULL_BEGIN

@interface PlayerAController : BaseViewController

TFY_CATEGORY_STRONG_PROPERTY TFY_PlayerController *player;

TFY_CATEGORY_STRONG_PROPERTY UIImageView *imageViews;

TFY_CATEGORY_STRONG_PROPERTY TFY_PlayerVideoModel *models;

TFY_CATEGORY_STRONG_PROPERTY TFY_RootModel *playermodels;

TFY_CATEGORY_STRONG_PROPERTY NSMutableArray<TFY_PlayerVideoModel *> *urls;

- (void)requestData:(void (^)(id x))nextBlock;
@end

NS_ASSUME_NONNULL_END
