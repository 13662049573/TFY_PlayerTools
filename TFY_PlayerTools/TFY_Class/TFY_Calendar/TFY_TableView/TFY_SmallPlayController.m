//
//  TFY_SmallPlayController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/19.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_SmallPlayController.h"
#import "TFY_AutoPlayerCell.h"

@interface TFY_SmallPlayController ()<UITableViewDelegate,UITableViewDataSource,TableViewCellDelegate>
TFY_CATEGORY_STRONG_PROPERTY BaseTableView *tableView4;
TFY_CATEGORY_STRONG_PROPERTY TFY_PlayerView *controlView;
@end

@implementation TFY_SmallPlayController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    @weakify(self)
    [self.tableView4 tfy_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @strongify(self)
        [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
    }];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView4];
    [self.tableView4 tfy_AutoSize:0 top:0 right:0 bottom:0];
    
    self.player = [TFY_PlayerController playerWithScrollView:self.tableView4 containerViewTag:100];
    self.player.controlView = self.controlView;
    // 1.0是完全消失的时候
    self.player.playerDisapperaPercent = 1.0;
    // 0.0是刚开始显示的时候
    self.player.playerApperaPercent = 0.0;
    // 移动网络依然自动播放
    self.player.WWANAutoPlay = YES;
    
     @weakify(self)
   self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
       @strongify(self)
       [self setNeedsStatusBarAppearanceUpdate];
       [UIViewController attemptRotationToDeviceOrientation];
       self.tableView4.scrollsToTop = !isFullScreen;
   };
   
   self.player.playerDidToEnd = ^(id  _Nonnull asset) {
       @strongify(self)
       [self.controlView resetControlView];
       [self.player stopCurrentPlayingCell];
   };
 
   // 以下设置滑出屏幕后不停止播放
   self.player.stopWhileNotVisible = NO;
   
   CGFloat margin = 20;
   CGFloat w = Player_ScreenWidth/2;
   CGFloat h = w * 9/16;
   CGFloat x = Player_ScreenWidth - w - margin;
   CGFloat y = Player_ScreenHeight - h - margin;
   self.player.smallFloatView.frame = CGRectMake(x, y, w, h);
    
    [self requestData:^(id  _Nonnull x) {
        [self.tableView4 reloadData];
    }];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (!parent) {
        self.tableView4.delegate = nil;
        [self.player stopCurrentPlayingCell];
    }
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

- (BaseTableView *)tableView4 {
    if (!_tableView4) {
        _tableView4 = [[BaseTableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView4.delegate = self;
        _tableView4.dataSource = self;
        /// 停止的时候找出最合适的播放
        @weakify(self)
        _tableView4.tfy_scrollViewDidStopScrollCallback = ^(NSIndexPath * _Nonnull indexPath) {
            @strongify(self)
            if (!self.player.playingIndexPath) {
                [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
            }
        };
    }
    return _tableView4;
}

- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
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
