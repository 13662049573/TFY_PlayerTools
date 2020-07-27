//
//  TFY_LightController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/19.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_LightController.h"
#import "TFY_LightTableViewCell.h"

@interface TFY_LightController ()<UITableViewDelegate,UITableViewDataSource,TableViewCellDelegate>
TFY_CATEGORY_STRONG_PROPERTY BaseTableView *tableView3;
TFY_CATEGORY_STRONG_PROPERTY TFY_PlayerView *controlView;
@end

@implementation TFY_LightController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView3];
    [self.tableView3 tfy_AutoSize:0 top:0 right:0 bottom:0];
    
    self.player = [TFY_PlayerController playerWithScrollView:self.tableView3 containerViewTag:200];
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
        self.tableView3.scrollsToTop = !isFullScreen;
    };
    
    [self requestData:^(id  _Nonnull x) {
        [self.tableView3 reloadData];
    }];
}


- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
        _controlView.fastViewAnimated = YES;
        _controlView.horizontalPanShowControlView = NO;
    }
    return _controlView;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.playermodels.list.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [TFY_LightTableViewCell tfy_CellHeightForIndexPath:indexPath tableVView:tableView];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *identfier = [NSString stringWithFormat:@"%ld,%ld",indexPath.row,indexPath.section];
    TFY_LightTableViewCell *cell = [TFY_LightTableViewCell cellFromCodeWithTableView:tableView identifier:identfier];
    
    [cell setDelegate:self withIndexPath:indexPath];
    
    cell.listModel = self.playermodels.list[indexPath.row];
    
    return cell;
}

- (void)tfy_playTheVideoAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath scrollToTop:YES];
}

- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop {
    if (scrollToTop) {
        /// 自定义滑动动画时间
        [self.tableView tfy_scrollToRowAtIndexPath:indexPath animateWithDuration:0.8 completionHandler:^{
            [self.player playTheIndexPath:indexPath];
        }];
    } else {
        [self.player playTheIndexPath:indexPath];
    }
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
    @weakify(self)
    [scrollView tfy_filterShouldPlayCellWhileScrolling:^(NSIndexPath *indexPath) {
        if ([indexPath compare:self.tableView3.tfy_shouldPlayIndexPath] != NSOrderedSame) {
            @strongify(self)
            /// 显示黑色蒙版
            TFY_LightTableViewCell *cell1 = [self.tableView3 cellForRowAtIndexPath:self.tableView3.tfy_shouldPlayIndexPath];
            [cell1 showMaskView];
            /// 隐藏黑色蒙版
            TFY_LightTableViewCell *cell = [self.tableView3 cellForRowAtIndexPath:indexPath];
            [cell hideMaskView];
        }
    }];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [scrollView tfy_scrollViewWillBeginDragging];
}

- (BaseTableView *)tableView3 {
    if (!_tableView3) {
        _tableView3 = [[BaseTableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView3.delegate = self;
        _tableView3.dataSource = self;
        /// 停止的时候找出最合适的播放
        @weakify(self)
        _tableView3.tfy_scrollViewDidStopScrollCallback = ^(NSIndexPath * _Nonnull indexPath) {
            @strongify(self)
            if (!self.player.playingIndexPath) {
                [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
            }
        };
        /// 明暗回调
       _tableView3.tfy_shouldPlayIndexPathCallback = ^(NSIndexPath * _Nonnull indexPath) {
           @strongify(self)
           if ([indexPath compare:self.tableView3.tfy_shouldPlayIndexPath] != NSOrderedSame) {
               /// 显示黑色蒙版
               TFY_LightTableViewCell *cell1 = [self.tableView3 cellForRowAtIndexPath:self.tableView3.tfy_shouldPlayIndexPath];
               [cell1 showMaskView];
               /// 隐藏黑色蒙版
               TFY_LightTableViewCell *cell = [self.tableView3 cellForRowAtIndexPath:indexPath];
               [cell hideMaskView];
           }
       };
    }
    return _tableView3;
}
@end
