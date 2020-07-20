//
//  TFY_CollectionBController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_CollectionBController.h"
#import "TFY_CollectionBFlowLayout.h"
#import "TFY_CollectionBCell.h"
#import "TFY_DouyinCollectionView.h"

@interface TFY_CollectionBController ()<UICollectionViewDelegate,UICollectionViewDataSource>
TFY_CATEGORY_STRONG_PROPERTY BaseCollectionView *collectionView;
TFY_CATEGORY_STRONG_PROPERTY TFY_PlayerView *controlView;
@end

@implementation TFY_CollectionBController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"点击跳转播放";
    
    [self.view addSubview:self.collectionView];
    [self.collectionView tfy_AutoSize:0 top:0 right:0 bottom:0];
    
    [self requestData:^(id  _Nonnull x) {
        [self.collectionView reloadData];
    }];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.playermodels.list.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TFY_CollectionBCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TFY_CollectionBCell" forIndexPath:indexPath];
    
    cell.listModel = self.playermodels.list[indexPath.row];
   
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    TFY_DouyinCollectionView *douyiin = [TFY_DouyinCollectionView new];
    [douyiin playTheIndex:indexPath.item];
    douyiin.scrollDirection = UICollectionViewScrollDirectionVertical;
    [self.navigationController pushViewController:douyiin animated:YES];
}


- (BaseCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[BaseCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[TFY_CollectionBFlowLayout new]];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        
        [_collectionView registerClass:@"TFY_CollectionBCell" herder_registerClass:@"" fooder_registerClass:@""];
    }
    return _collectionView;
}

- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
    }
    return _controlView;
}

@end
