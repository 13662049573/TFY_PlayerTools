//
//  TFYTableHeaderViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYTableHeaderViewController.h"
#import "TFYPlayerDetailViewController.h"
#import "TFYTableHeaderView.h"
#import "TFYTableData.h"
#import "TFYOtherCell.h"
#import "TFY_ITools.h"
#import "TFY_PlayerTool.h"
#import "TFY_PlayerControlView.h"
static NSString *kIdentifier = @"kIdentifier";

@interface TFYTableHeaderViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) TFYTableHeaderView *headerView;
@property (nonatomic, strong) TFY_PlayerController *player;
@property (nonatomic, strong) TFY_PlayerControlView *controlView;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation TFYTableHeaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    
    [self requestData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // 在视图出现后设置tableHeaderView，避免布局警告
    if (!self.tableView.tableHeaderView) {
        [self setupPlayerAndHeader];
    }
}

- (void)setupPlayerAndHeader {
    self.tableView.tableHeaderView = self.headerView;
    self.headerView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width*9/16);
    
    /// playerManager
    TFY_AVPlayerManager *playerManager = [[TFY_AVPlayerManager alloc] init];
    /// player的tag值必须在cell里设置
    self.player = [TFY_PlayerController playerWithScrollView:self.tableView playerManager:playerManager containerView:self.headerView.coverImageView];
    self.player.playerDisapperaPercent = 1.0;
    self.player.playerApperaPercent = 0.0;
    self.player.stopWhileNotVisible = NO;
    CGFloat margin = 20;
    CGFloat w = TFY_PLAYER_ScreenW/2;
    CGFloat h = w * 9/16;
    CGFloat x = TFY_PLAYER_ScreenH - w - margin;
    CGFloat y = TFY_PLAYER_ScreenH - h - margin;
    self.player.smallFloatView.frame = CGRectMake(x, y, w, h);
    self.player.controlView = self.controlView;
    
    @player_weakify(self)
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @player_strongify(self)
        [self.player stopCurrentPlayingCell];
    };
    
    [self playTheIndex:0];
}

- (void)requestData {
    self.dataSource = @[].mutableCopy;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *rootDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    
    NSArray *videoList = [rootDict objectForKey:@"list"];
    for (NSDictionary *dataDic in videoList) {
        TFYTableData *data = [[TFYTableData alloc] init];
        [data setValuesForKeysWithDictionary:dataDic];
        [self.dataSource addObject:data];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    CGFloat h = CGRectGetMaxY(self.view.frame);
    self.tableView.frame = CGRectMake(0, y, self.view.frame.size.width, h-y);
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [scrollView tfy_scrollViewDidScroll];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TFYOtherCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];
    cell.textLabel.text = [NSString stringWithFormat:@"点击播放第%zd个视频",indexPath.row + 1];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheIndex:indexPath.row];
}

#pragma mark - private

- (void)playTheIndex:(NSInteger)index {
    /// 在这里判断能否播放。。。
    TFYTableData *data = self.dataSource[index];
    self.player.currentPlayerManager.assetURL = [NSURL URLWithString:data.video_url];
    [self.controlView showTitle:data.title coverURLString:data.thumbnail_url fullScreenMode:FullScreenModeLandscape];
    
    if (self.tableView.contentOffset.y > self.headerView.frame.size.height) {
        [self.player addPlayerViewToSmallFloatView];
    } else {
        [self.player addPlayerViewToContainerView:self.headerView.coverImageView];
    }
}

#pragma mark - getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_tableView registerClass:[TFYOtherCell class] forCellReuseIdentifier:kIdentifier];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        if (@available(iOS 11.0, *)) {
            _tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.rowHeight = 100;
    }
    return _tableView;
}

- (TFY_PlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerControlView new];
        _controlView.fastViewAnimated = YES;
        _controlView.prepareShowLoading = YES;
    }
    return _controlView;
}

- (TFYTableHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[TFYTableHeaderView alloc] init];
        @player_weakify(self)
        _headerView.playCallback = ^{
            @player_strongify(self)
            [self playTheIndex:0];
        };
    }
    return _headerView;
}

@end
