//
//  TFY_ModelKit.h
//  TFY_Model
//
//  Created by 田风有 on 2020/9/9.
//  Copyright © 2020 恋机科技. All rights reserved.
//  最新版本号: 2.8.0

#import <Foundation/Foundation.h>

#if __has_include(<TFY_ModelKit/TFY_ModelKit.h>)

FOUNDATION_EXPORT double TFY_ModelVersionNumber;
FOUNDATION_EXPORT const unsigned char TFY_ModelVersionString[];

#import <TFY_Model/NSObject+TFY_Model.h>
#import <TFY_Model/TFY_ModelSqlite.h>

#else

#import "NSObject+TFY_Model.h"
#import "TFY_ModelSqlite.h"

#endif
