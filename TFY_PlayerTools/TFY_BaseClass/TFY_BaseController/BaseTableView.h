//
//  BaseTableView.h
//  Thermometer
//
//  Created by tiandengyou on 2019/10/18.
//  Copyright © 2019 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseTableView : UITableView
/**
 * 是否开启圆角 默认 NO
 */
TFY_CATEGORY_ASSIGN_PROPERTY BOOL fillet_bool;
/***是否开启默认图片*/
TFY_CATEGORY_ASSIGN_PROPERTY BOOL default_picture;
/**
 *  下拉加载
 */
-(void)addharder;
/**
 *  下拉需要加载数据调用这个方法
 */
- (void)loadNewData;
/**
 *  上拉加载
 */
-(void)addfooter;
/**
 *  上拉需要加载数据调用这个方法
 */
-(void)loadfooter;

@end

NS_ASSUME_NONNULL_END
