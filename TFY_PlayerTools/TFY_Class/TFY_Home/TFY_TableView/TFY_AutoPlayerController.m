//
//  TFY_AutoPlayerController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/17.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_AutoPlayerController.h"
#import "TFY_AutoPlayerCell.h"

@interface TFY_AutoPlayerController ()<UITableViewDelegate,UITableViewDataSource,TableViewCellDelegate>
TFY_CATEGORY_STRONG_PROPERTY BaseTableView *tableView2;
TFY_CATEGORY_STRONG_PROPERTY TFY_PlayerView *controlView;
@end

@implementation TFY_AutoPlayerController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    @weakify(self)
    [self.tableView2 tfy_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @strongify(self)
        [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView2];
    [self.tableView2 tfy_AutoSize:0 top:0 right:0 bottom:0];
    
    self.player = [TFY_PlayerController playerWithScrollView:self.tableView2 containerViewTag:100];
    self.player.controlView = self.controlView;
    /// 0.8是消失80%时候，默认0.5
    self.player.playerDisapperaPercent = 0.8;
    /// 移动网络依然自动播放
    self.player.WWANAutoPlay = YES;
    @weakify(self)
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @strongify(self)
        if (self.player.playingIndexPath.row < self.urls.count - 1) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.player.playingIndexPath.row+1 inSection:0];
            [self playTheVideoAtIndexPath:indexPath scrollToTop:YES];
        } else {
            [self.player stopCurrentPlayingCell];
        }
    };
    
    self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        @strongify(self)
        [self setNeedsStatusBarAppearanceUpdate];
        [UIViewController attemptRotationToDeviceOrientation];
        self.tableView2.scrollsToTop = !isFullScreen;
    };
    
    [self requestData:^(id  _Nonnull x) {
        [self.tableView2 reloadData];
    }];
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.playermodels.list.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    TFY_ListModel *listmodel = self.playermodels.list[indexPath.row];
    return listmodel.video_height+130;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *identfier = [NSString stringWithFormat:@"%ld,%ld",indexPath.row,indexPath.section];
    TFY_AutoPlayerCell *cell = [TFY_AutoPlayerCell cellFromCodeWithTableView:tableView identifier:identfier];
    
    cell.indexPath = indexPath;
    
    cell.listModel = self.playermodels.list[indexPath.row];
    
    cell.delegate = self;
    
    return cell;
}

- (void)tfy_playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
}

- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop {
    [self.player playTheIndexPath:indexPath scrollToTop:scrollToTop];
}

- (BaseTableView *)tableView2 {
    if (!_tableView2) {
        _tableView2 = [[BaseTableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView2.delegate = self;
        _tableView2.dataSource = self;
        /// 停止的时候找出最合适的播放
        @weakify(self)
        _tableView2.tfy_scrollViewDidStopScrollCallback = ^(NSIndexPath * _Nonnull indexPath) {
            @strongify(self)
            if (!self.player.playingIndexPath) {
                [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
            }
        };
    }
    return _tableView2;
}

- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
        _controlView.fastViewAnimated = YES;
        _controlView.horizontalPanShowControlView = NO;
        _controlView.prepareShowLoading = YES;
    }
    return _controlView;
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
@end
