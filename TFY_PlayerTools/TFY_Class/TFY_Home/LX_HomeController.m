//
//  LX_HomeController.m
//  LX_Player
//
//  Created by 田风有 on 2020/7/16.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "LX_HomeController.h"


@interface LX_HomeController ()
TFY_CATEGORY_STRONG_PROPERTY UIButton *player_Btn;
@end

@implementation LX_HomeController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"播放器样式（Player style）";
    
    self.dataSouceArr = @[@"普通样式",@"UITableView样式",@"UICollectionView样式",@"UIScrollView样式"];
    
    [self.view addSubview:self.tableView];
    [self.tableView tfy_AutoSize:0 top:0 right:0 bottom:0];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section==0) {
        [self push:@"TFY_NoramlController"];
    } else if (indexPath.section==1) {
        [self push:@"TFY_AutoPlayerController"];
    } else if (indexPath.section==2) {
        [self push:@"TFY_CollectionController"];
    } else if (indexPath.section==3) {
        [self push:@"TFY_ScrollViewController"];
    }
}

@end
