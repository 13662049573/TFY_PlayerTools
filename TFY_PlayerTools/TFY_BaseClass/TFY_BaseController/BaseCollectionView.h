//
//  BaseCollectionView.h
//  Thermometer
//
//  Created by tiandengyou on 2019/10/18.
//  Copyright © 2019 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BaseCollectionView : UICollectionView

-(void)registerClass:(NSString *)cellClass herder_registerClass:(NSString *)viewClass fooder_registerClass:(NSString *)viewClass2;
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
/**
 *  有数据是否加载显示文字
 */
- (void)setNoMoreData:(BOOL)noMoreData;
@end

NS_ASSUME_NONNULL_END
