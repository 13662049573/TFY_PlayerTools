//
//  TFY_PlayerConstants.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFY_PlayerConstants.h"

NSString *const TFYPlayerLogPrefix = @"TFY_PlayerController:";

// MARK: - Timing Constants Implementation
const TFYPlayerTimingConstants TFYPlayerTiming = {
    .pipDelay = 0.1,
    .pipCheckDelay = 0.5,
    .pipRetryDelay = 0.5,
    .pipRestartDelay = 0.1,
    .observerTimeout = 10.0
};

// MARK: - Retry Constants Implementation  
const TFYPlayerRetryConstants TFYPlayerRetry = {
    .maxPipRetryCount = 5,
    .maxObserverRetryCount = 3
};

// MARK: - UI Constants Implementation
const TFYPlayerUIConstants TFYPlayerUI = {
    .defaultPlayerApperaPercent = 0.0,
    .defaultPlayerDisapperaPercent = 0.5,
    .defaultAutoHiddenTimeInterval = 2.5,
    .defaultAutoFadeTimeInterval = 0.25
};

// MARK: - Volume Slider Class Name
NSString *const TFYPlayerVolumeSliderClassName = @"MPVolumeSlider";

// MARK: - KVO Context
static void *_TFYPlayerPipItemContext = &_TFYPlayerPipItemContext;
void *const TFYPlayerPipItemContext = &_TFYPlayerPipItemContext; 