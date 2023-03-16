//
//  TFYTableSectionModel.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFYTableSectionModel.h"

@implementation TFYTableItem

+ (instancetype)itemWithTitle:(NSString *)title subTitle:(NSString *)subTitle viewControllerName:(NSString *)name {
    TFYTableItem *model = [[self alloc] init];
    model.title = title;
    model.subTitle = subTitle;
    model.viewControllerName = name;
    return model;
}

@end

@implementation TFYTableSectionModel

+ (instancetype)sectionModeWithTitle:(NSString *)title items:(NSArray <TFYTableItem *>*)items {
    TFYTableSectionModel *sectionModel = [[self alloc] init];
    sectionModel.title = title;
    sectionModel.items = items;
    return sectionModel;
}

@end
