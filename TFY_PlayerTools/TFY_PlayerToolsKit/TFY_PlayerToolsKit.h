//
//  TFY_PlayerToolsKit.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/9/9.
//  Copyright © 2020 田风有. All rights reserved.
//  最新版本号：2.1.4

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double TFY_PlayerToolsKitVersionNumber;

FOUNDATION_EXPORT const unsigned char TFY_PlayerToolsKitVersionString[];

#define TFY_PlayerToolsKitRelease 0

#if TFY_PlayerToolsKitRelease

#import <TFY_PlayerTool/TFY_PlayerToolsHeader.h>
#import <TFY_PlayerView/TFY_PlayerView.h>

#else

#import "TFY_PlayerToolsHeader.h"
#import "TFY_PlayerView.h"

#endif
