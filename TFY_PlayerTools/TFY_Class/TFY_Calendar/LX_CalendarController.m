//
//  LX_CalendarController.m
//  LX_Player
//
//  Created by 田风有 on 2020/7/16.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "LX_CalendarController.h"

@interface LX_CalendarController ()

@end

@implementation LX_CalendarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"UITableView样式（TableView style）";
    
    self.dataSouceArr = @[@"点击播放",@"自动播放",@"列表明暗播放",@"小窗播放",@"抖音样式",@"HeaderView样式"];
    
    [self.view addSubview:self.tableView];
    [self.tableView tfy_AutoSize:0 top:0 right:0 bottom:0];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section==0) {
        [self push:@"TFY_NotAutoPlayController"];
    } else if (indexPath.section==1) {
        [self push:@"TFY_AutoPlayerController"];
    } else if (indexPath.section==2) {
        [self push:@"TFY_LightController"];
    } else if (indexPath.section==3) {
        [self push:@"TFY_SmallPlayController"];
    } else if (indexPath.section==4) {
        [self push:@"TFY_DouYinController"];
    } else if (indexPath.section==5) {
        [self push:@"TFY_TableHeaderController"];
    }
}


@end
