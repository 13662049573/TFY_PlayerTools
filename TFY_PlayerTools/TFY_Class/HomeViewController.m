//
//  HomeViewController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "HomeViewController.h"
#import "TFYDouYinViewController.h"
#import "TFYTableSectionModel.h"
#import "TFYDouyinCollectionViewController.h"

static NSString *kIdentifier = @"kIdentifier";

@interface HomeViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray <TFYTableSectionModel *>*datas;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"TFYPlayer";
    [self.view addSubview:self.tableView];
    self.datas = @[].mutableCopy;
    [self.datas addObject:[TFYTableSectionModel sectionModeWithTitle:@"播放器样式（Player style）" items:[self createItemsByPlayerType]]];
    [self.datas addObject:[TFYTableSectionModel sectionModeWithTitle:@"UITableView样式（TableView style）" items:[self createItemsByTableView]]];
    [self.datas addObject:[TFYTableSectionModel sectionModeWithTitle:@"UICollectionView样式（CollectionView style）" items:[self createItemsByCollectionView]]];
    [self.datas addObject:[TFYTableSectionModel sectionModeWithTitle:@"旋转类型（Rotation type）" items:[self createItemsByRotationType]]];
    [self.datas addObject:[TFYTableSectionModel sectionModeWithTitle:@"自定义（Custom）" items:[self createItemsByCustom]]];
    [self.datas addObject:[TFYTableSectionModel sectionModeWithTitle:@"其他（Other）" items:[self createItemsByOther]]];
}

- (NSArray <TFYTableItem *>*)createItemsByPlayerType {
    return @[[TFYTableItem itemWithTitle:@"普通样式,画中画" subTitle:@"Normal style" viewControllerName:@"TFYNormalViewController"],
             [TFYTableItem itemWithTitle:@"UITableView样式" subTitle:@"UITableView style" viewControllerName:@"TFYAutoPlayerViewController"],
             [TFYTableItem itemWithTitle:@"UICollectionView样式" subTitle:@"UICollectionView style" viewControllerName:@"TFYCollectionViewController"],
             [TFYTableItem itemWithTitle:@"UIScrollView样式" subTitle:@"UIScrollView style" viewControllerName:@"TFYScrollViewViewController"]];
}

- (NSArray <TFYTableItem *>*)createItemsByTableView {
    return @[[TFYTableItem itemWithTitle:@"点击播放" subTitle:@"Click to play" viewControllerName:@"TFYNotAutoPlayViewController"],
             [TFYTableItem itemWithTitle:@"自动播放" subTitle:@"Auto play" viewControllerName:@"TFYAutoPlayerViewController"],
             [TFYTableItem itemWithTitle:@"列表明暗播放" subTitle:@"Light and dark style" viewControllerName:@"TFYLightTableViewController"],
             [TFYTableItem itemWithTitle:@"微信朋友圈" subTitle:@"wechat friend circle style" viewControllerName:@"TFYWChatViewController"],
             [TFYTableItem itemWithTitle:@"混合cell样式" subTitle:@"Mix cell style" viewControllerName:@"TFYMixViewController"],
             [TFYTableItem itemWithTitle:@"小窗播放" subTitle:@"Small view style" viewControllerName:@"TFYSmallPlayViewController"],
             [TFYTableItem itemWithTitle:@"抖音样式" subTitle:@"Douyin style" viewControllerName:@"TFYDouYinViewController"],
             [TFYTableItem itemWithTitle:@"HeaderView样式" subTitle:@"Table header style" viewControllerName:@"TFYTableHeaderViewController"]];
}

- (NSArray <TFYTableItem *>*)createItemsByCollectionView {
    return @[[TFYTableItem itemWithTitle:@"抖音个人主页" subTitle:@"Douyin homepage" viewControllerName:@"TFYCollectionViewListController"],
             [TFYTableItem itemWithTitle:@"横向滚动抖音" subTitle:@"Horizontal Douyin style" viewControllerName:@"TFYDouyinCollectionViewController"],
             [TFYTableItem itemWithTitle:@"竖向滚动抖音" subTitle:@"Vertical Douyin style" viewControllerName:@"TFYDouyinCollectionViewController"],
             [TFYTableItem itemWithTitle:@"横向滚动CollectionView" subTitle:@"Horizontal CollectionView" viewControllerName:@"TFYHorizontalCollectionViewController"]];
}

- (NSArray <TFYTableItem *>*)createItemsByRotationType {
    return @[[TFYTableItem itemWithTitle:@"旋转类型" subTitle:@"Rotation type" viewControllerName:@"TFYRotationViewController"],
             [TFYTableItem itemWithTitle:@"旋转键盘" subTitle:@"Rotation keyboard" viewControllerName:@"TFYKeyboardViewController"],
             [TFYTableItem itemWithTitle:@"全屏播放" subTitle:@"Fullscreen play" viewControllerName:@"TFYFullScreenViewController"]];
}

- (NSArray <TFYTableItem *>*)createItemsByCustom {
    return @[[TFYTableItem itemWithTitle:@"自定义控制层" subTitle:@"Custom ControlView" viewControllerName:@"TFYCustomControlViewViewController"]];
}

- (NSArray <TFYTableItem *>*)createItemsByOther {
    return @[[TFYTableItem itemWithTitle:@"广告" subTitle:@"Advertising" viewControllerName:@"TFYADViewController"]];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.datas.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas[section].items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentifier];
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    TFYTableItem *itme = self.datas[indexPath.section].items[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@（%@）",itme.title,itme.subTitle];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.datas[section].title;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    TFYTableItem *itme = self.datas[indexPath.section].items[indexPath.row];
    NSString *vcString = itme.viewControllerName;
    UIViewController *viewController = [[NSClassFromString(vcString) alloc] init];
    if ([vcString isEqualToString:@"TFYDouYinViewController"]) {
        [(TFYDouYinViewController *)viewController playTheIndex:0];
    }
    viewController.navigationItem.title = itme.title;
    viewController.hidesBottomBarWhenPushed = YES;
    
    if ([vcString isEqualToString:@"TFYDouyinCollectionViewController"] && [itme.title isEqualToString:@"横向滚动抖音"]) {
        TFYDouyinCollectionViewController *douyinVC = (TFYDouyinCollectionViewController *)viewController;
        douyinVC.scrollViewDirection = PlayerScrollViewDirectionHorizontal;
    }
    if ([vcString isEqualToString:@"TFYFullScreenViewController"]) {
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:viewController animated:NO completion:nil];
    } else {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, TFY_kNavBarHeight(), TFY_Width_W(), TFY_Height_H()-TFY_kNavBarHeight()-TFY_kBottomBarHeight()) style:UITableViewStylePlain];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kIdentifier];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 44;
    }
    return _tableView;
}


@end
