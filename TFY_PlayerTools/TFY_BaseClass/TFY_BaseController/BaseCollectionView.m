//
//  BaseCollectionView.m
//  Thermometer
//
//  Created by tiandengyou on 2019/10/18.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "BaseCollectionView.h"

@implementation BaseCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout{
    if (self=[super initWithFrame:frame collectionViewLayout:layout]) {
       self.backgroundColor = [UIColor tfy_colorWithHex:LCColor_B5];
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.pagingEnabled = YES;
        self.scrollsToTop = NO;
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        if (@available(iOS 13.0, *)) {
            self.automaticallyAdjustsScrollIndicatorInsets = NO;
        }
    }
    return self;
}


-(void)registerClass:(NSString *)cellClass herder_registerClass:(NSString *)viewClass  fooder_registerClass:(NSString *)viewClass2{
    
    if (![TFY_CommonUtils judgeIsEmptyWithString:cellClass]) {
        Class class_cell = NSClassFromString(cellClass);
        [self registerClass:class_cell forCellWithReuseIdentifier:cellClass];
    }
    Class class_register = NSClassFromString(viewClass);
    if (![TFY_CommonUtils judgeIsEmptyWithString:viewClass]) {
        [self registerClass:class_register forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:viewClass];
    }
    Class class_register2 = NSClassFromString(viewClass2);
    if (![TFY_CommonUtils judgeIsEmptyWithString:viewClass2]) {
        [self registerClass:class_register2 forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:viewClass2];
    }
}

//下拉刷新
-(void)addharder
{
    MJRefreshStateHeader *header = [MJRefreshStateHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
//    // 隐藏时间
//    header.lastUpdatedTimeLabel.hidden = NO;
//    // 隐藏状态
//    header.stateLabel.hidden = NO;
    
    self.mj_header= header;
    
    [self.mj_header beginRefreshing];
}

- (void)loadNewData{}

-(void)addfooter{
    MJRefreshBackStateFooter *footer=[MJRefreshBackStateFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadfooter)];
    // 隐藏状态
    footer.stateLabel.hidden = YES;
    
    self.mj_footer =footer;
}

-(void)loadfooter{}

- (void)setNoMoreData:(BOOL)noMoreData{
    
    if (noMoreData) {
        [self.mj_footer endRefreshingWithNoMoreData];
    }
    else{
        [self.mj_footer resetNoMoreData];
    }
}

@end
