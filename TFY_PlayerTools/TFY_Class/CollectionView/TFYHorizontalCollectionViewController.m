//
//  TFYHorizontalCollectionViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYHorizontalCollectionViewController.h"
#import "TFYCollectionViewCell.h"
#import "TFYTableData.h"
#import "UIView+PlayerFrame.h"

static NSString * const reuseIdentifier = @"collectionViewCell";

@interface TFYHorizontalCollectionViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) NSMutableArray <TFYTableData *>*dataSource;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) TFY_PlayerController *player;
@property (nonatomic, strong) TFY_PlayerControlView *controlView;
@property (nonatomic, strong) UILabel *markLabel;

@end

@implementation TFYHorizontalCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.markLabel];
    [self.view addSubview:self.collectionView];
    [self requestData];
    
    /// playerManager
    TFY_AVPlayerManager *playerManager = [[TFY_AVPlayerManager alloc] init];
    
    /// player的tag值必须在cell里设置
    self.player = [TFY_PlayerController playerWithScrollView:self.collectionView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    self.player.shouldAutoPlay = YES;
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
    CGFloat width = self.view.frame.size.width;
    CGFloat height = width*9/16;
    CGFloat y = 0;
    self.collectionView.frame = CGRectMake(0, y, width, height);
    self.collectionView.center = self.view.center;
    
    self.markLabel.frame = CGRectMake(0, self.collectionView.frame.origin.y-50, 100, 20);
    self.markLabel.player_centerX = self.view.player_centerX;
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
    return UIStatusBarStyleDefault;
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

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    TFYTableData *data = self.dataSource[indexPath.row];
    [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:data.video_url]];
    [self.controlView showTitle:data.title
                 coverURLString:data.thumbnail_url
                 fullScreenMode:FullScreenModeLandscape];
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

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TFYCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.data = self.dataSource[indexPath.row];
    @player_weakify(self)
    cell.playBlock = ^(UIButton *sender) {
        @player_strongify(self)
        [self playTheVideoAtIndexPath:indexPath];
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath];
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat itemWidth = self.view.frame.size.width;
        CGFloat itemHeight = itemWidth*9/16;
        layout.itemSize = CGSizeMake(itemWidth, itemHeight);
        layout.sectionInset = UIEdgeInsetsZero;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        /// 横向滚动 这行代码必须写
        _collectionView.tfy_scrollViewDirection = PlayerScrollViewDirectionHorizontal;
        [_collectionView registerClass:[TFYCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
        _collectionView.pagingEnabled = YES;
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _collectionView;
}

- (TFY_PlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerControlView new];
        _controlView.fastViewAnimated = YES;
        _controlView.effectViewShow = NO;
        _controlView.customDisablePanMovingDirection = YES;
    }
    return _controlView;
}

- (UILabel *)markLabel {
    if (!_markLabel) {
        _markLabel = [UILabel new];
        _markLabel.text = @"请横向滚动";
    }
    return _markLabel;
}


@end
