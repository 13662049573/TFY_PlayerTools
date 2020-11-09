//
//  TFY_TableHeaderController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_TableHeaderController.h"
#import "TFY_TableHeaderView.h"
#import "TFY_HerderTableViewCell.h"

@interface TFY_TableHeaderController ()<UITableViewDelegate,UITableViewDataSource>
TFY_PROPERTY_STRONG BaseTableView *tableView6;
TFY_PROPERTY_STRONG TFY_PlayerView *controlView;
TFY_PROPERTY_STRONG TFY_TableHeaderView *headerView;
@end

@implementation TFY_TableHeaderController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.tableView6];
    [self.tableView6 tfy_AutoSize:0 top:0 right:0 bottom:0];
 
    self.player = [TFY_PlayerController playerWithScrollView:self.tableView6 containerView:self.headerView.coverImageView];
    self.player.playerDisapperaPercent = 1.0;
    self.player.playerApperaPercent = 0.0;
    self.player.stopWhileNotVisible = NO;
    CGFloat margin = 20;
    CGFloat w = Player_ScreenWidth/2;
    CGFloat h = w * 9/16;
    CGFloat x = Player_ScreenWidth - w - margin;
    CGFloat y = Player_ScreenHeight - h - margin;
    self.player.smallFloatView.frame = CGRectMake(x, y, w, h);
    self.player.controlView = self.controlView;
    
    @weakify(self)
    self.player.orientationWillChange = ^(TFY_PlayerController * _Nonnull player, BOOL isFullScreen) {
        @strongify(self)
        [self setNeedsStatusBarAppearanceUpdate];
        [UIViewController attemptRotationToDeviceOrientation];
        self.tableView6.scrollsToTop = !isFullScreen;
    };
    
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @strongify(self)
        [self.player stopCurrentPlayingCell];
    };
    
    [self requestData:^(id  _Nonnull x) {
        [self.tableView6 reloadData];
    }];
    
    [self playTheIndex:0];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [scrollView tfy_scrollViewDidScroll];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.playermodels.list.count;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    self.headerView = [[TFY_TableHeaderView alloc] initWithFrame:CGRectMake(0, 0, Player_ScreenWidth, Player_ScreenWidth*9/16)];
    @weakify(self)
    self.headerView.playCallback = ^{
       @strongify(self)
       [self playTheIndex:0];
    };
    return self.headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return Player_ScreenWidth*9/16;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 130;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *identfier = [NSString stringWithFormat:@"%ld,%ld",indexPath.row,indexPath.section];
    TFY_HerderTableViewCell *cell = [TFY_HerderTableViewCell tfy_cellFromCodeWithTableView:tableView identifier:identfier];
    
    cell.listModel = self.playermodels.list[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self playTheIndex:indexPath.row];
}

#pragma mark - private

- (void)playTheIndex:(NSInteger)index {
    /// 在这里判断能否播放。。。
    TFY_ListModel *listModel = self.playermodels.list[index];
    
    TFY_PlayerVideoModel *player = [TFY_PlayerVideoModel new];
    player.tfy_url = listModel.videouri;
    self.player.assetUrlModel = player;
    
    [self.controlView showTitle:listModel.screen_name coverURLString:listModel.image_small fullScreenMode:FullScreenModeLandscape];
    
    if (self.tableView.contentOffset.y > self.headerView.frame.size.height) {
        [self.player addPlayerViewToKeyWindow];
    } else {
        [self.player addPlayerViewToContainerView:self.headerView.coverImageView];
    }
}

- (BaseTableView *)tableView6 {
    if (!_tableView6) {
        _tableView6 = [[BaseTableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView6.delegate = self;
        _tableView6.dataSource = self;
    }
    return _tableView6;
}

- (TFY_PlayerView *)controlView {
    if (!_controlView) {
        _controlView = [TFY_PlayerView new];
        _controlView.fastViewAnimated = YES;
        _controlView.prepareShowLoading = YES;
    }
    return _controlView;
}

@end
