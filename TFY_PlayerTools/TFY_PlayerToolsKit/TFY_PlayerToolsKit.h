//
//  TFY_PlayerToolsKit.h
//  TFY_PlayerView
//
//  Created by 田风有 on 2019/7/1.
//  Copyright © 2019 田风有. All rights reserved.
//  最新版本号：2.2.1 -> 2.2.2

/**
 * TFY_PlayerToolsKit - 播放器工具包主头文件
 * 
 * 功能说明：
 * 这是播放器工具包的主要入口文件，包含了所有核心组件的头文件引用。
 * 开发者只需要导入此文件即可使用播放器工具包的所有功能。
 * 
 * 主要组件：
 * - TFY_PlayerController: 播放器控制器，负责播放逻辑管理
 * - TFY_PlayerPerformanceOptimizer: 播放器性能优化器
 * - TFY_PlayerView: 播放器视图组件
 * 
 * 使用方式：
 * #import "TFY_PlayerToolsKit.h"
 */

#ifndef TFY_PlayerToolsKit_h
#define TFY_PlayerToolsKit_h

// 播放器控制器 - 核心播放逻辑管理
#import "TFY_PlayerController.h"

// 播放器性能优化器 - 内存和性能优化
#import "TFY_PlayerPerformanceOptimizer.h"

// 播放器视图组件 - UI界面管理
#import "TFY_PlayerView.h"

#endif /* TFY_PlayerToolsKit_h */
