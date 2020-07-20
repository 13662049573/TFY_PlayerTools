//
//  TFY_PlayerToolsKitHeader.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/16.
//  Copyright © 2020 田风有. All rights reserved.
//  最新版本号：2.0.2


#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double TFY_AutoLayoutVersionNumber;

FOUNDATION_EXPORT const unsigned char TFY_AutoLayoutVersionString[];

#define TFY_AutoLayoutKitRelease 0

#if TFY_AutoLayoutKitRelease

#import <TFY_PlayerTool/TFY_PlayerToolsHeader.h>
#import <TFY_PlayerView/TFY_PlayerView.h>


#else

#import "TFY_PlayerToolsHeader.h"
#import "TFY_PlayerView.h"

#endif

