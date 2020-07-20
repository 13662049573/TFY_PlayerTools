//
//  TFY_CollectionBFlowLayout.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_CollectionBFlowLayout.h"

@implementation TFY_CollectionBFlowLayout

/**初始化布局*/
- (void)prepareLayout{
    [super prepareLayout];
    [self setupLayout];
}

- (void)setupLayout{
    CGFloat itemWidth = Player_ScreenWidth/3-10;
    CGFloat itemHeight = itemWidth*4/3;
    
    self.itemSize = CGSizeMake(itemWidth, itemHeight);
    
    self.minimumInteritemSpacing = 5;
    
    self.minimumLineSpacing = 5;
    
    self.sectionInset = UIEdgeInsetsMake(10, 5, 10, 5);
    
}

@end
