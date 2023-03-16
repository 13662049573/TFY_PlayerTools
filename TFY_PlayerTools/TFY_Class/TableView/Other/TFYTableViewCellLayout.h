//
//  TFYTableViewCellLayout.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFYTableData.h"
NS_ASSUME_NONNULL_BEGIN

@interface TFYTableViewCellLayout : NSObject
@property (nonatomic, strong) TFYTableData *data;
@property (nonatomic, readonly) CGRect headerRect;
@property (nonatomic, readonly) CGRect nickNameRect;
@property (nonatomic, readonly) CGRect videoRect;
@property (nonatomic, readonly) CGRect playBtnRect;
@property (nonatomic, readonly) CGRect titleLabelRect;
@property (nonatomic, readonly) CGRect maskViewRect;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) BOOL isVerticalVideo;

- (instancetype)initWithData:(TFYTableData *)data;

- (instancetype)initWXData:(TFYTableData *)data;
@end

NS_ASSUME_NONNULL_END
