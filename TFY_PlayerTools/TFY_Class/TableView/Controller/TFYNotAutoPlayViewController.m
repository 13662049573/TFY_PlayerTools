//
//  TFYNotAutoPlayViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYNotAutoPlayViewController.h"
#import "TFYTableViewCell.h"
#import "TFYTableData.h"
#import "TFYPlayerDetailViewController.h"

static NSString *kIdentifier = @"kIdentifier";

@interface TFYNotAutoPlayViewController ()<UITableViewDelegate,UITableViewDataSource,TFYTableViewCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) TFY_PlayerController *player;
@property (nonatomic, strong) TFY_PlayerControlView *controlView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation TFYNotAutoPlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    [self requestData];

    /// playerManager
    TFY_AVPlayerManager *playerManager = [[TFY_AVPlayerManager alloc] init];
    
    /// player的tag值必须在cell里设置
    self.player = [TFY_PlayerController playerWithScrollView:self.tableView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    self.player.shouldAutoPlay = NO;
    /// 1.0是完全消失的时候
    self.player.playerDisapperaPercent = 1.0;

    @player_weakify(self)
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @player_strongify(self)
        [self.player stopCurrentPlayingCell];
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.player.viewControllerDisappear = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.player.viewControllerDisappear = YES;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat h = CGRectGetMaxY(self.view.frame);
    self.tableView.frame = CGRectMake(0, y, self.view.frame.size.width, h-y);
}

- (void)requestData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    self.dataSource = @[].mutableCopy;
    NSArray *videoList = [rootDict objectForKey:@"list"];
    for (NSDictionary *dataDic in videoList) {
        TFYTableData *data = [[TFYTableData alloc] init];
        [data setValuesForKeysWithDictionary:dataDic];
        TFYTableViewCellLayout *layout = [[TFYTableViewCellLayout alloc] initWithData:data];
        [self.dataSource addObject:layout];
    }
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
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

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TFYTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];
    [cell setDelegate:self withIndexPath:indexPath];
    cell.layout = self.dataSource[indexPath.row];
    [cell setNormalMode];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /// 如果正在播放的index和当前点击的index不同，则停止当前播放的index
    if (self.player.playingIndexPath != indexPath) {
        [self.player stopCurrentPlayingCell];
    }
    /// 如果没有播放，则点击进详情页会自动播放
    if (!self.player.currentPlayerManager.isPlaying) {
        [self playTheVideoAtIndexPath:indexPath];
    }
    /// 到详情页
    TFYPlayerDetailViewController *detailVC = [TFYPlayerDetailViewController new];
    detailVC.player = self.player;
    /// 详情页返回的回调
    detailVC.detailVCPopCallback = ^{
        if (self.player.currentPlayerManager.playState == PlayerPlayStatePlayStopped) {
            [self.player stopCurrentPlayingCell];
        } else {
            [self.player addPlayerViewToCell];
        }
    };
    /// 详情页点击播放的回调
    detailVC.detailVCPlayCallback = ^{
        [self tfy_playTheVideoAtIndexPath:indexPath];
    };
    [self.navigationController pushViewController:detailVC animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    TFYTableViewCellLayout *layout = self.dataSource[indexPath.row];
    return layout.height;
}

#pragma mark - TFYTableViewCellDelegate

- (void)tfy_playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath];
}

#pragma mark - private method

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    TFYTableViewCellLayout *layout = self.dataSource[indexPath.row];
    [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:layout.data.video_url]];
    [self.controlView showTitle:layout.data.title
                 coverURLString:layout.data.thumbnail_url
                 fullScreenMode:layout.isVerticalVideo?FullScreenModePortrait:FullScreenModeLandscape];
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_tableView registerClass:[TFYTableViewCell class] forCellReuseIdentifier:kIdentifier];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
    }
    return _tableView;
}

- (TFY_PlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerControlView new];
        _controlView.prepareShowLoading = YES;
        _controlView.prepareShowControlView = YES;
        _controlView.showCustomStatusBar = YES;
    }
    return _controlView;
}


@end