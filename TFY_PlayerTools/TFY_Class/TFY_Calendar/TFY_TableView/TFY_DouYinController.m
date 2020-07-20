//
//  TFY_DouYinController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/19.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_DouYinController.h"
#import "TFY_DouYinPlayerView.h"
#import "TFY_DouYinViewCell.h"
@interface TFY_DouYinController ()<UITableViewDelegate,UITableViewDataSource>
TFY_CATEGORY_STRONG_PROPERTY BaseTableView *tableView5;
TFY_CATEGORY_STRONG_PROPERTY TFY_DouYinPlayerView *controlView;
@property (nonatomic, strong) UIButton *backBtn;
@end

@implementation TFY_DouYinController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    @weakify(self)
    [self.tableView5 tfy_filterShouldPlayCellWhileScrolled:^(NSIndexPath *indexPath) {
        @strongify(self)
        [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController tfy_navigationBarTransparent];
    
    [self.view addSubview:self.tableView5];
    [self.tableView5 tfy_AutoSize:0 top:0 right:0 bottom:0];
    
    self.player = [TFY_PlayerController playerWithScrollView:self.tableView5 containerViewTag:100];
    self.player.disableGestureTypes = PlayerDisableGestureTypesDoubleTap | PlayerDisableGestureTypesPan | PlayerDisableGestureTypesPinch;
    self.player.controlView = self.controlView;
    self.player.allowOrentitaionRotation = NO;
    self.player.WWANAutoPlay = YES;
    /// 1.0是完全消失时候
    self.player.playerDisapperaPercent = 1.0;
    
    @weakify(self)
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @strongify(self)
        [self.player.currentPlayerManager replay];
    };
    
    self.player.presentationSizeChanged = ^(id<TFY_PlayerMediaPlayback>  _Nonnull asset, CGSize size) {
        @strongify(self)
        if (size.width >= size.height) {
            self.player.currentPlayerManager.scalingMode = PlayerScalingModeAspectFit;
        } else {
            self.player.currentPlayerManager.scalingMode = PlayerScalingModeAspectFill;
        }
    };
    
    [self requestData:^(id  _Nonnull x) {
        [self.tableView5 reloadData];
    }];
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.playermodels.list.count;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return Player_ScreenHeight;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *identfier = [NSString stringWithFormat:@"%ld,%ld",(long)indexPath.row,(long)indexPath.section];
    TFY_DouYinViewCell *cell = [TFY_DouYinViewCell cellFromCodeWithTableView:tableView identifier:identfier];
    
    cell.listModel = self.playermodels.list[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
}

- (void)playTheVideoAtIndexPath:(NSIndexPath *)indexPath scrollToTop:(BOOL)scrollToTop {
    [self.player playTheIndexPath:indexPath scrollToTop:scrollToTop];
    [self.controlView resetControlView];
    TFY_ListModel *listModel = self.playermodels.list[indexPath.row];
    UIViewContentMode imageMode;
    if (listModel.thumbnail_width >= listModel.thumbnail_height) {
        imageMode = UIViewContentModeScaleAspectFit;
    } else {
        imageMode = UIViewContentModeScaleAspectFill;
    }
    [self.controlView showCoverViewWithUrl:listModel.thumbnail_url withImageMode:imageMode];
}


- (TFY_DouYinPlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_DouYinPlayerView new];
    }
    return _controlView;
}

- (BaseTableView *)tableView5 {
    if (!_tableView5) {
        _tableView5 = [[BaseTableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView5.pagingEnabled = YES;
        _tableView5.delegate = self;
        _tableView5.dataSource = self;
        _tableView5.scrollsToTop = NO;
        /// 停止的时候找出最合适的播放
        @weakify(self)
        _tableView5.tfy_scrollViewDidStopScrollCallback = ^(NSIndexPath * _Nonnull indexPath) {
            @strongify(self)
            if (self.player.playingIndexPath) return;
            if (indexPath.row == self.playermodels.list.count-1) {
                /// 加载下一页数据
                [self requestData:^(id  _Nonnull x) {
                    [self.tableView5 reloadData];
                }];
                self.player.assetUrlMododels = self.urls;
            }
            [self playTheVideoAtIndexPath:indexPath scrollToTop:NO];
        };
    }
    return _tableView5;
}

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
