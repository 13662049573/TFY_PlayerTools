//
//  TFYTableSectionModel.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TFYTableItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *viewControllerName;

+ (instancetype)itemWithTitle:(NSString *)title subTitle:(NSString *)subTitle viewControllerName:(NSString *)name;

@end

@interface TFYTableSectionModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray <TFYTableItem *>*items;

+ (instancetype)sectionModeWithTitle:(NSString *)title items:(NSArray <TFYTableItem *>*)items;

@end

NS_ASSUME_NONNULL_END
