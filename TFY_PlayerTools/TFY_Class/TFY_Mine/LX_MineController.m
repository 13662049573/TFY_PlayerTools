//
//  LX_MineController.m
//  LX_Player
//
//  Created by 田风有 on 2020/7/16.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "LX_MineController.h"

@interface LX_MineController ()

@end

@implementation LX_MineController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"旋转类型（Rotation type）";
    
    self.dataSouceArr = @[@"旋转类型",@"旋转键盘",@"全屏播放",@"自定义控制层",@"广告"];
    
    [self.view addSubview:self.tableView];
    [self.tableView tfy_AutoSize:0 top:0 right:0 bottom:0];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        [self push:@"TFY_RotationController"];
    } else if (indexPath.section == 1) {
        [self push:@"TFY_KeyboardController"];
    } else if (indexPath.section == 2) {
        [self push:@"TFY_FullScreenController"];
    } else if (indexPath.section == 3) {
        [self push:@"TFY_CustomControlController"];
    } else if (indexPath.section == 4) {
        [self push:@"TFY_ADViewController"];
    }
}

@end
