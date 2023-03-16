//
//  TFYDouyinCollectionViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYDouyinCollectionViewController.h"
#import "TFYDouyinCollectionViewCell.h"
#import "TFYTableData.h"
#import "UIView+PlayerFrame.h"
#import "TFYDouYinControlView.h"
#import "TFYDouYinCellDelegate.h"
#import "TFYCustomControlView.h"

static NSString * const reuseIdentifier = @"collectionViewCell";

@interface TFYDouyinCollectionViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,TFYDouYinCellDelegate>

@property (nonatomic, strong) NSMutableArray <TFYTableData *>*dataSource;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) TFY_PlayerController *player;
@property (nonatomic, strong) TFYDouYinControlView *controlView;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) TFYCustomControlView *fullControlView;

@end

@implementation TFYDouyinCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.backBtn];
    [self requestData];
    
    /// playerManager
    TFY_AVPlayerManager *playerManager = [[TFY_AVPlayerManager alloc] init];
    
    /// player的tag值必须在cell里设置
    self.player = [TFY_PlayerController playerWithScrollView:self.collectionView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    self.player.shouldAutoPlay = YES;
    self.player.allowOrentitaionRotation = NO;
    self.player.disablePanMovingDirection = PlayerDisablePanMovingDirectionAll;
    /// 1.0是消失100%时候
    self.player.playerDisapperaPercent = 1.0;
    
    @player_weakify(self)
    self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        @player_strongify(self)
        if (isFullScreen) {
            self.player.disablePanMovingDirection = PlayerDisablePanMovingDirectionNone;
        } else {
            self.player.disablePanMovingDirection = PlayerDisablePanMovingDirectionAll;
        }
        self.player.controlView.hidden = YES;
    };
    
    self.player.orientationDidChanged = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        @player_strongify(self)
        self.player.controlView.hidden = NO;
        if (isFullScreen) {
            self.player.controlView = self.fullControlView;
        } else {
            self.player.controlView = self.controlView;
        }
    };
    
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @player_strongify(self)
        [self.player.currentPlayerManager replay];
    };
    
    /// 停止的时候找出最合适的播放
    self.player.tfy_scrollViewDidEndScrollingCallback = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        [self playTheVideoAtIndexPath:indexPath];
    };
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.backBtn.frame = CGRectMake(15, CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame), 36, 36);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    @player_weakify(self)
    [self.player tfy_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @player_strongify(self)
        [self playTheVideoAtIndexPath:indexPath];
    }];
}

#pragma mark - 转屏和状态栏

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - private method

- (void)requestData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    self.dataSource = @[].mutableCopy;
    NSArray *videoList = [rootDict objectForKey:@"list"];
    for (NSDictionary *dataDic in videoList) {
        TFYTableData *data = [[TFYTableData alloc] init];
        [data setValuesForKeysWithDictionary:dataDic];
        [self.dataSource addObject:data];
    }
}

- (void)playTheIndex:(NSInteger)index {
    @player_weakify(self)
    /// 指定到某一行播放
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
    [self.player tfy_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @player_strongify(self)
        [self playTheVideoAtIndexPath:indexPath];
    }];
    /// 如果是最后一行，去请求新数据
    if (index == self.dataSource.count-1) {
        /// 加载下一页数据
        [self requestData];
        [self.collectionView reloadData];
    }
}

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    TFYTableData *data = self.dataSource[indexPath.row];
    [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:data.video_url]];
    [self.controlView resetControlView];
    [self.controlView showCoverViewWithUrl:data.thumbnail_url];
    [self.fullControlView showTitle:@"custom landscape controlView" coverURLString:data.thumbnail_url fullScreenMode:FullScreenModeLandscape];
}

- (void)backClick:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
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

#pragma mark - TFYDouYinCellDelegate

- (void)tfy_douyinRotation {
    UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
    if (self.player.isFullScreen) {
        orientation = UIInterfaceOrientationPortrait;
    } else {
        orientation = UIInterfaceOrientationLandscapeRight;
    }
    [self.player rotateToOrientation:orientation animated:YES completion:nil];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TFYDouyinCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.data = self.dataSource[indexPath.row];
    cell.delegate = self;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath];
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemWidth = self.view.frame.size.width;
        CGFloat itemHeight = self.view.frame.size.height;
        layout.itemSize = CGSizeMake(itemWidth, itemHeight);
        layout.sectionInset = UIEdgeInsetsZero;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        if (self.scrollViewDirection == PlayerScrollViewDirectionVertical) {
            layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        } else if (self.scrollViewDirection == PlayerScrollViewDirectionHorizontal) {
            layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        }
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        /// 横向滚动 这行代码必须写
        _collectionView.tfy_scrollViewDirection = self.scrollViewDirection;
        [_collectionView registerClass:[TFYDouyinCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
        _collectionView.pagingEnabled = YES;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.scrollsToTop = NO;
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _collectionView;
}

- (TFYDouYinControlView *)controlView {
    if (!_controlView) {
        _controlView = [TFYDouYinControlView new];
    }
    return _controlView;
}

- (TFYCustomControlView *)fullControlView {
    if (!_fullControlView) {
        _fullControlView = [[TFYCustomControlView alloc] init];
    }
    return _fullControlView;
}

- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"icon_titlebar_whiteback"] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

@end
