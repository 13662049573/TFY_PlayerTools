//
//  BaseViewController.m
//  Thermometer
//
//  Created by tiandengyou on 2019/10/17.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()<UITableViewDelegate,UITableViewDataSource>

@end

@implementation BaseViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [TFY_CommonUtils BackstatusBarStyle:0];
    NSString *className = NSStringFromClass([self class]);
    if ([className hasPrefix:@"UI"] == NO) {
//        if ([className isEqualToString:@"LM_HomeController"] || [className isEqualToString:@"LM_CurveController"] || [className isEqualToString:@"LM_CalendarController"] || [className isEqualToString:@"LM_KnowledgeController"] || [className isEqualToString:@"LM_LoginController"] || [className isEqualToString:@"LM_HealthController"]) {
//
//            [TFY_CommonUtils BackstatusBarStyle:1];
//        }
//        else{
//            [TFY_CommonUtils BackstatusBarStyle:0];
//        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = false;
    self.view.backgroundColor = [UIColor tfy_colorWithHex:LCColor_B7];
}

/*不传数据，直接push到下一个界面*/
-(void)push:(NSString*)controllerName{
    if (![TFY_CommonUtils judgeIsEmptyWithString:controllerName]) {
        Class class=NSClassFromString(controllerName);
        UIViewController *controller=[[class alloc] init];
        controller.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:controller animated:true];
    }
}

-(void)presenting:(NSString *)controllerName{
    if (![TFY_CommonUtils judgeIsEmptyWithString:controllerName]) {
        Class class=NSClassFromString(controllerName);
        UIViewController *controller=[[class alloc] init];
        controller.hidesBottomBarWhenPushed = YES;
        TFY_NavigationController *nav = [self navcontroller:controller];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
}

/*关闭界面，返回上一级*/
-(void)pop{
    if (self.presentingViewController){
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

/*返回到固定界面*/
-(void)popToController:(NSString*)controllerName{
    if (![TFY_CommonUtils judgeIsEmptyWithString:controllerName]) {
        Class class=NSClassFromString(controllerName);
        id controller=[[class alloc] init];
        NSArray *temArray = self.navigationController.viewControllers;
        for(UIViewController *temVC in temArray)
        {
            if ([temVC isKindOfClass:[controller class]])
            {
                [self.navigationController popToViewController:temVC animated:YES];
            }
        }
    }
}

/*返回到主界面*/
-(void)popToRoot{
    [self.navigationController popToRootViewControllerAnimated:true];
}
/**
 *  跳过方法实现
 */
-(void)taoguoClick{
    [TFY_CommonUtils saveIntValueInUD:0 forKey:@"Switch"];
//    TFY_APPDelegate.window.rootViewController = [LM_TabBarController new];
}

/**
 *  token 失效  直接跳转到登录界面
 */
-(void)loginController{
    [TFY_CommonUtils saveBoolValueInUD:NO forKey:@"isCompanion"];
//    TFY_NavigationController *nav = [self navcontroller:[LM_LoginController new]];
//    TFY_APPDelegate.window.rootViewController = nav;
}

- (BaseTableView *)tableView{
    if (!_tableView) {
        if (@available(iOS 13.0, *)) {
            _tableView = [[BaseTableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
        } else {
            _tableView = [[BaseTableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        }
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.dataSouceArr.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return [UIView new];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 10;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [UITableViewCell cellFromCodeWithTableView:tableView];
    
    cell.textLabel.text = self.dataSouceArr[indexPath.section];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{}


@end