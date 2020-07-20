//
//  LX_CurveController.m
//  LX_Player
//
//  Created by 田风有 on 2020/7/16.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "LX_CurveController.h"
#import "TFY_DouyinCollectionView.h"

@interface LX_CurveController ()

@end

@implementation LX_CurveController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"UICollectionView样式（CollectionView style）";
    
    self.dataSouceArr = @[@"抖音个人主页",@"横向滚动抖音",@"竖向滚动抖音"];
    
    [self.view addSubview:self.tableView];
    [self.tableView tfy_AutoSize:0 top:0 right:0 bottom:0];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        [self push:@"TFY_CollectionBController"];
    } else if (indexPath.section == 1) {
        [self push:@"TFY_DouyinCollectionView"];
    } else if (indexPath.section == 2) {
        TFY_DouyinCollectionView *douyiin = [TFY_DouyinCollectionView new];
        douyiin.scrollDirection = UICollectionViewScrollDirectionVertical;
        [self.navigationController pushViewController:douyiin animated:YES];
    } 
}


@end
