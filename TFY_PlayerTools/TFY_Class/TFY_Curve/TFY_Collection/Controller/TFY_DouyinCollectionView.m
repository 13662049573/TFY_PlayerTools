//
//  TFY_DouyinCollectionView.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_DouyinCollectionView.h"
#import "TFY_DouyinCollectionFlowLayout.h"
#import "TFY_DouyinCollectionViewCell.h"
#import "TFY_DouYinPlayerView.h"
@interface TFY_DouyinCollectionView ()<UICollectionViewDelegate,UICollectionViewDataSource>
TFY_PROPERTY_STRONG BaseCollectionView *collectionView;
TFY_PROPERTY_STRONG TFY_DouYinPlayerView *controlView;
TFY_PROPERTY_STRONG TFY_DouyinCollectionFlowLayout *layout;
@end

@implementation TFY_DouyinCollectionView

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
    // Do any additional setup after loading the view.
    [self.view addSubview:self.collectionView];
    [self.collectionView tfy_AutoSize:0 top:0 right:0 bottom:0];
    
    self.player = [TFY_PlayerController playerWithScrollView:self.collectionView containerViewTag:100];
    self.player.controlView = self.controlView;
    self.player.shouldAutoPlay = YES;
    self.player.disablePanMovingDirection = PlayerDisablePanMovingDirectionAll;
    /// 1.0是消失100%时候
    self.player.playerDisapperaPercent = 1.0;
    
    @weakify(self)
    self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        @strongify(self)
        [self setNeedsStatusBarAppearanceUpdate];
        self.collectionView.scrollsToTop = !isFullScreen;
        if (isFullScreen) {
            self.player.disablePanMovingDirection = PlayerDisablePanMovingDirectionNone;
        } else {
            self.player.disablePanMovingDirection = PlayerDisablePanMovingDirectionAll;
        }
    };
    
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @strongify(self)
        [self.player.currentPlayerManager replay];
    };
    
    [self requestData:^(id  _Nonnull x) {
        [self.collectionView reloadData];
    }];
    
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.playermodels.list.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TFY_DouyinCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TFY_DouyinCollectionViewCell" forIndexPath:indexPath];
    cell.listModel = self.playermodels.list[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
}



-(void)setScrollDirection:(UICollectionViewScrollDirection)scrollDirection{
    _scrollDirection = scrollDirection;
    self.layout.scrollDirection = _scrollDirection;
}


- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop {
    [self.player playTheIndexPath:indexPath scrollToTop:scrollToTop];
    [self.controlView resetControlView];
    TFY_ListModel *data = self.playermodels.list[indexPath.row];
    UIViewContentMode imageMode;
    if (data.width >= data.height) {
        imageMode = UIViewContentModeScaleAspectFit;
    } else {
        imageMode = UIViewContentModeScaleAspectFill;
    }
    [self.controlView showCoverViewWithUrl:data.image_small withImageMode:imageMode];
}

- (void)playTheIndex:(NSInteger)index {
    @weakify(self)
    /// 指定到某一行播放
    [self.collectionView reloadData];[self.collectionView layoutIfNeeded];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    
    [self.collectionView tfy_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @strongify(self)
        [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
    }];
    /// 如果是最后一行，去请求新数据
    if (index == self.playermodels.list.count-1) {
        /// 加载下一页数据
        [self requestData:^(id  _Nonnull x) {
            [self.collectionView reloadData];
        }];
    }
}


- (BaseCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[BaseCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        
        [_collectionView registerClass:@"TFY_DouyinCollectionViewCell" herder_registerClass:@"" fooder_registerClass:@""];
        
        /// 停止的时候找出最合适的播放
        @weakify(self)
        _collectionView.tfy_scrollViewDidStopScrollCallback = ^(NSIndexPath * _Nonnull indexPath) {
            @strongify(self)
            [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
        };
    }
    return _collectionView;
}

- (TFY_DouyinCollectionFlowLayout *)layout{
    if (!_layout) {
        _layout = [TFY_DouyinCollectionFlowLayout new];
        _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return _layout;
}

- (TFY_DouYinPlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_DouYinPlayerView new];
    }
    return _controlView;
}

#pragma mark - UIScrollViewDelegate  列表播放必须实现

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
@end
