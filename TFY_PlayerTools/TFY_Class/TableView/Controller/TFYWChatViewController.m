//
//  TFYWChatViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYWChatViewController.h"
#import "TFYTableViewCell.h"
#import "TFYTableData.h"
#import <AVFoundation/AVFoundation.h>
#import "TFYWeChatControlView.h"

static NSString *kIdentifier = @"kIdentifier";

@interface TFYWChatViewController ()<UITableViewDelegate,UITableViewDataSource,TFYTableViewCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) TFY_PlayerController *player;
@property (nonatomic, strong) TFYWeChatControlView *controlView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation TFYWChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    [self.view addSubview:self.tableView];
    [self requestData];
    
    TFY_AVPlayerManager *playerManager = [[TFY_AVPlayerManager alloc] init];
    playerManager.scalingMode = PlayerScalingModeAspectFill;

    
    /// player的tag值必须在cell里设置
    self.player = [TFY_PlayerController playerWithScrollView:self.tableView playerManager:playerManager containerViewTag:kPlayerViewTag];
    self.player.controlView = self.controlView;
    /// 0.4是消失40%时候
    self.player.playerDisapperaPercent = 0.4;
    /// 0.6是出现60%时候
    self.player.playerApperaPercent = 0.6;
    /// 移动网络依然自动播放
    self.player.WWANAutoPlay = YES;
    /// 续播
    self.player.resumePlayRecord = YES;
    /// 禁止掉滑动手势
    self.player.disableGestureTypes = PlayerDisableGestureTypesPan;
    /// 竖屏的全屏
    self.player.orientationObserver.fullScreenMode = FullScreenModePortrait;
    /// 隐藏全屏的状态栏
    self.player.orientationObserver.fullScreenStatusBarHidden = YES;
    self.player.orientationObserver.fullScreenStatusBarAnimation = UIStatusBarAnimationNone;

    /// 全屏的填充模式（全屏填充、按视频大小填充）
    self.player.orientationObserver.portraitFullScreenMode = PortraitFullScreenModeScaleAspectFit;
    /// 禁用竖屏全屏的手势（点击、拖动手势）
    self.player.orientationObserver.disablePortraitGestureTypes = DisablePortraitGestureTypesNone;

    @player_weakify(self)
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @player_strongify(self)
        [self.player.currentPlayerManager replay];
    };
    
    /// 停止的时候找出最合适的播放
    self.player.tfy_scrollViewDidEndScrollingCallback = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        if (!self.player.playingIndexPath) {
            [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
        }
    };
    
    /// 滑动中找到适合的就自动播放
    /// 如果是停止后再寻找播放可以忽略这个回调
    /// 如果在滑动中就要寻找到播放的indexPath，并且开始播放，那就要这样写
    self.player.tfy_playerShouldPlayInScrollView = ^(NSIndexPath * _Nonnull indexPath) {
        @player_strongify(self)
        if ([indexPath compare:self.player.playingIndexPath] != NSOrderedSame) {
            [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
        }
    };
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat h = CGRectGetMaxY(self.view.frame);
    self.tableView.frame = CGRectMake(0, y, self.view.frame.size.width, h-y);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    @player_weakify(self)
    [self.player tfy_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @player_strongify(self)
        [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
    }];
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
        TFYTableViewCellLayout *layout = [[TFYTableViewCellLayout alloc] initWXData:data];
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
    cell.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    [cell setDelegate:self withIndexPath:indexPath];
    cell.layout = self.dataSource[indexPath.row];
    [cell setNormalMode];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    TFYTableViewCellLayout *layout = self.dataSource[indexPath.row];
    return layout.height;
}

#pragma mark - TFYTableViewCellDelegate

- (void)tfy_playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath scrollAnimated:NO];
    [self.player enterPortraitFullScreen:YES animated:YES];
}

#pragma mark - private method

/// play the video
- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath scrollAnimated:(BOOL)animated {
    TFYTableViewCellLayout *layout = self.dataSource[indexPath.row];
    if (animated) {
         [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:layout.data.video_url] scrollPosition:PlayerScrollViewScrollPositionCenteredVertically animated:YES];
     } else {
         [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:layout.data.video_url]];
     }
    
    [self.controlView showCoverViewWithUrl:layout.data.thumbnail_url];
    CGSize videoSize = CGSizeMake(layout.data.video_width, layout.data.video_height);
    self.player.currentPlayerManager.presentationSize = videoSize;
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

- (TFYWeChatControlView *)controlView {
    if (!_controlView) {
        _controlView = [TFYWeChatControlView new];
    }
    return _controlView;
}



@end
