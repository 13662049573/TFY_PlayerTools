//
//  TFY_DouyinCollectionFlowLayout.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_DouyinCollectionFlowLayout.h"

@implementation TFY_DouyinCollectionFlowLayout

/**初始化布局*/
- (void)prepareLayout{
    [super prepareLayout];
    [self setupLayout];
}

- (void)setupLayout{
    self.sectionInset = UIEdgeInsetsZero;
    self.minimumLineSpacing = 0;
    self.minimumInteritemSpacing = 0;
    
    self.itemSize = CGSizeMake(Player_ScreenWidth, Player_ScreenHeight);
    
}
@end
