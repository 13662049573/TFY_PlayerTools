//
//  TFY_ShaperLayerChainModel.m
//  TFY_LayoutCategoryUtil
//
//  Created by tiandengyou on 2020/3/30.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_ShaperLayerChainModel.h"
#define TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(TFY_Method,TFY_ParaType) TFY_CATEGORY_CHAIN_LAYERCLASS_IMPLEMENTATION(TFY_Method,TFY_ParaType, TFY_ShaperLayerChainModel *, CAShapeLayer)
@implementation TFY_ShaperLayerChainModel

TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(path, CGPathRef)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(fillColor, CGColorRef)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(fillRule, CAShapeLayerFillRule)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(strokeColor, CGColorRef)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(strokeStart, CGFloat)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(strokeEnd, CGFloat)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(lineWidth, CGFloat)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(miterLimit, CGFloat)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(lineCap, CAShapeLayerLineCap)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(lineJoin, CAShapeLayerLineJoin)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(lineDashPhase, CGFloat)
TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION(lineDashPattern, NSArray<NSNumber *> *)
@end
TFY_CATEGORY_LAYER_IMPLEMENTATION(CAShapeLayer, TFY_ShaperLayerChainModel)
#undef TFY_CATEGORY_CHAIN_SHAPERLAYER_IMPLEMENTATION