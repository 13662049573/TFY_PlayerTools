//
//  BaseViewController.h
//  Thermometer
//
//  Created by tiandengyou on 2019/10/17.
//  Copyright © 2019 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseTableView.h"
#import "BaseCollectionView.h"
NS_ASSUME_NONNULL_BEGIN

@interface BaseViewController : UIViewController

@property(nonatomic , strong)BaseTableView *tableView;

@property(nonatomic , strong)NSArray *dataSouceArr;

/*不传数据，直接push到下一个界面*/
-(void)push:(NSString*)controllerName;
/**弹出界面*/
-(void)presenting:(NSString *)controllerName;
/*关闭界面，返回上一级*/
-(void)pop;
/*返回到固定界面*/
-(void)popToController:(NSString*)controllerName;
/*返回到主界面*/
-(void)popToRoot;
/***   调到首页*/
-(void)taoguoClick;
/***  token 失效  直接跳转到登录界面*/
-(void)loginController;

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
