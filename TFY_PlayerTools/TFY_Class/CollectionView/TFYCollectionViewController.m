//
//  TFYCollectionViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYCollectionViewController.h"
#import "TFYCollectionViewCell.h"
#import "TFYTableData.h"
#import "UIView+PlayerFrame.h"

static NSString * const reuseIdentifier = @"collectionViewCell";

@interface TFYCollectionViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) NSMutableArray <TFYTableData *>*dataSource;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) TFY_PlayerController *player;
@property (nonatomic, strong) TFY_PlayerControlView *controlView;

@end

@implementation TFYCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    [self requestData];
    
    /// playerManager
    TFY_AVPlayerManager *playerManager = [[TFY_AVPlayerManager alloc] init];
    
    /// player的tag值必须在cell里设置
    self.player = [TFY_PlayerController playerWithScrollView:self.collectionView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    self.player.shouldAutoPlay = YES;
    
    @player_weakify(self)
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @player_strongify(self)
        if (self.player.playingIndexPath.row < self.dataSource.count - 1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.player.playingIndexPath.row+1 inSection:0];
            [self playTheVideoAtIndexPath:indexPath scrollAnimated:YES];
        } else {
            [self.player.currentPlayerManager replay];
        }
    };
    
    /// 停止的时候找出最合适的播放
    self.player.tfy_scrollViewDidEndScrollingCallback = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
    };
    
    /*
     
    /// 滑动中找到适合的就自动播放
    /// 如果是停止后再寻找播放可以忽略这个回调
    /// 如果在滑动中就要寻找到播放的indexPath，并且开始播放，那就要这样写
    self.player.tfy_playerShouldPlayInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        if ([indexPath compare:self.player.playingIndexPath] != NSOrderedSame) {
            [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
        }
    };
     
    */
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.collectionView.frame = self.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    @player_weakify(self)
    [self.player tfy_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @player_strongify(self)
        [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
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
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath scrollAnimated:(BOOL)animated {
    TFYTableData *data = self.dataSource[indexPath.row];
    if (animated) {
        [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:data.video_url] scrollPosition:PlayerScrollViewScrollPositionCenteredVertically animated:YES];
    } else {
        [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:data.video_url]];
    }
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
        [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        CGFloat margin = 5;
        CGFloat itemWidth = self.view.frame.size.width;
        CGFloat itemHeight = itemWidth*9/16 + 30;
        layout.itemSize = CGSizeMake(itemWidth, itemHeight);
        layout.sectionInset = UIEdgeInsetsMake(10, margin, 10, margin);
        layout.minimumLineSpacing = 5;
        layout.minimumInteritemSpacing = 5;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        [_collectionView registerClass:[TFYCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    }
    return _collectionView;
}

- (TFY_PlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerControlView new];
    }
    return _controlView;
}


@end
