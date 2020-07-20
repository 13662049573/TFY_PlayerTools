//
//  TFY_CollectionController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/18.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_CollectionController.h"
#import "TFY_CollectionCell.h"

@interface TFY_CollectionController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionCellDelegate>
TFY_CATEGORY_STRONG_PROPERTY BaseCollectionView *collectionView;
TFY_CATEGORY_STRONG_PROPERTY TFY_PlayerView *controlView;
@end

@implementation TFY_CollectionController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    @weakify(self)
    [self.collectionView tfy_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @strongify(self)
        [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.collectionView];
    [self.collectionView tfy_AutoSize:0 top:0 right:0 bottom:0];
    
    self.player = [TFY_PlayerController playerWithScrollView:self.collectionView containerViewTag:100];
    self.player.controlView = self.controlView;
    self.player.shouldAutoPlay = YES;
    @weakify(self)
    self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        @strongify(self)
        [self setNeedsStatusBarAppearanceUpdate];
        self.collectionView.scrollsToTop = !isFullScreen;
    };
    
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @strongify(self)
        if (self.player.playingIndexPath.row < self.urls.count - 1 && !self.player.isFullScreen) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.player.playingIndexPath.row+1 inSection:0];
            [self playTheVideoAtIndexPath:indexPath scrollToTop:YES];
        } else if (self.player.isFullScreen) {
            [self.player enterFullScreen:NO animated:YES];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.player.orientationObserver.duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.player stopCurrentPlayingCell];
            });
        }
    };
    
    [self requestData:^(id  _Nonnull x) {
        [self.collectionView reloadData];
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.playermodels.list.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TFY_CollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TFY_CollectionCell" forIndexPath:indexPath];
    
    cell.delegate = self;
    
    cell.indexPath = indexPath;
    
    cell.listModel = self.playermodels.list[indexPath.row];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
}

- (void)tfy_playTheVideoAtIndexPath:(NSIndexPath *)indexPath{
    [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
}

- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop {
    [self.player playTheIndexPath:indexPath scrollToTop:scrollToTop];
}

#pragma mark - UIScrollViewDelegate 列表播放必须实现

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [scrollView tfy_scrollViewDidEndDecelerating];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [scrollView tfy_scrollViewDidEndDraggingWillDecelerate:decelerate];
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [scrollView tfy_scrollViewDidScrollToTop];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [scrollView tfy_scrollViewDidScroll];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [scrollView tfy_scrollViewWillBeginDragging];
}


- (BaseCollectionView *)collectionView {
    if (!_collectionView) {
       UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
       CGFloat margin = 5;
       CGFloat itemWidth = self.view.frame.size.width;
       CGFloat itemHeight = itemWidth*9/16 + 30;
       layout.itemSize = CGSizeMake(itemWidth, itemHeight);
       layout.sectionInset = UIEdgeInsetsMake(10, margin, 10, margin);
       layout.minimumLineSpacing = 5;
       layout.minimumInteritemSpacing = 5;
        _collectionView = [[BaseCollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        [_collectionView registerClass:@"TFY_CollectionCell" herder_registerClass:@"" fooder_registerClass:@""];
        @weakify(self)
        _collectionView.tfy_scrollViewDidStopScrollCallback = ^(NSIndexPath * _Nonnull indexPath) {
           @strongify(self)
           [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
        };
    }
    return _collectionView;
}


@end
