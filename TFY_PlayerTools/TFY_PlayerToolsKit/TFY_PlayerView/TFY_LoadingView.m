//
//  TFY_LoadingView.m
//  TFY_PlayerView
//
//  Created by 田风有 on 2019/6/30.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "TFY_LoadingView.h"
#import "TFY_PlayerPerformanceOptimizer.h"

@interface TFY_LoadingView ()
@property (nonatomic, strong, readonly) CAShapeLayer *shapeLayer;
@property (nonatomic, assign, getter=isAnimating) BOOL animating;
@property (nonatomic, assign) BOOL strokeShow;
@end

@implementation TFY_LoadingView
@synthesize lineColor = _lineColor;
@synthesize shapeLayer = _shapeLayer;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initialize];
}

- (void)initialize {
    [self.layer addSublayer:self.shapeLayer];
    self.duration = 1;
    self.lineWidth = 1;
    self.lineColor = [UIColor whiteColor];
    self.userInteractionEnabled = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = MIN(self.bounds.size.width, self.bounds.size.height);
    CGFloat height = width;
    self.shapeLayer.frame = CGRectMake(0, 0, width, height);
    
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat radius = MIN(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) / 2) - self.shapeLayer.lineWidth / 2;
    CGFloat startAngle = (CGFloat)(0);
    CGFloat endAngle = (CGFloat)(2*M_PI);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    self.shapeLayer.path = path.CGPath;
}

- (void)startAnimating {
    if (self.animating) return;
    self.animating = YES;
    
    // 检查性能优化器设置
    TFY_PlayerPerformanceOptimizer *optimizer = [TFY_PlayerPerformanceOptimizer sharedOptimizer];
    BOOL shouldOptimizeAnimation = !optimizer.animationOptimizationEnabled;
    
    // 使用CADisplayLink确保动画同步
    if (self.animType == LoadingTypeFadeOut) {
        [self fadeOutShow];
    } else {
        CABasicAnimation *rotationAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnim.toValue = [NSNumber numberWithFloat:2 * M_PI];
        rotationAnim.duration = shouldOptimizeAnimation ? self.duration * 1.5 : self.duration; // 低性能设备减慢动画
        rotationAnim.repeatCount = CGFLOAT_MAX;
        rotationAnim.removedOnCompletion = NO;
        // 优化动画性能
        rotationAnim.fillMode = kCAFillModeForwards;
        rotationAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        [self.shapeLayer addAnimation:rotationAnim forKey:@"rotation"];
    }
    
    if (self.hidesWhenStopped) {
        self.hidden = NO;
    }
}

- (void)stopAnimating {
    if (!self.animating) return;
    self.animating = NO;
    
    // 使用更平滑的停止方式
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.shapeLayer removeAllAnimations];
    [CATransaction commit];
    
    if (self.hidesWhenStopped) {
        self.hidden = YES;
    }
}

- (void)fadeOutShow {
    // 优化动画组合
    CABasicAnimation *headAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
    headAnimation.duration = self.duration / 1.5f;
    headAnimation.fromValue = @(0.f);
    headAnimation.toValue = @(0.25f);
    headAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation *tailAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    tailAnimation.duration = self.duration / 1.5f;
    tailAnimation.fromValue = @(0.f);
    tailAnimation.toValue = @(1.f);
    tailAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation *endHeadAnimation = [CABasicAnimation animationWithKeyPath:@"strokeStart"];
    endHeadAnimation.beginTime = self.duration / 1.5f;
    endHeadAnimation.duration = self.duration / 3.0f;
    endHeadAnimation.fromValue = @(0.25f);
    endHeadAnimation.toValue = @(1.f);
    endHeadAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CABasicAnimation *endTailAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    endTailAnimation.beginTime = self.duration / 1.5f;
    endTailAnimation.duration = self.duration / 3.0f;
    endTailAnimation.fromValue = @(1.f);
    endTailAnimation.toValue = @(1.f);
    endTailAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    CAAnimationGroup *animations = [CAAnimationGroup animation];
    [animations setDuration:self.duration];
    [animations setAnimations:@[headAnimation, tailAnimation, endHeadAnimation, endTailAnimation]];
    animations.repeatCount = INFINITY;
    animations.removedOnCompletion = NO;
    animations.fillMode = kCAFillModeForwards;
    [self.shapeLayer addAnimation:animations forKey:@"strokeAnim"];
    
    if (self.hidesWhenStopped) {
        self.hidden = NO;
    }
}

#pragma mark - setter and getter

- (CAShapeLayer *)shapeLayer {
    if (!_shapeLayer) {
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.strokeColor = self.lineColor.CGColor;
        _shapeLayer.fillColor = [UIColor clearColor].CGColor;
        _shapeLayer.strokeStart = 0.1;
        _shapeLayer.strokeEnd = 1;
        _shapeLayer.lineCap = @"round";
        _shapeLayer.anchorPoint = CGPointMake(0.5, 0.5);
    }
    return _shapeLayer;
}

- (UIColor *)lineColor {
    if (!_lineColor) {
        return [UIColor whiteColor];
    }
    return _lineColor;
}

- (void)setLineWidth:(CGFloat)lineWidth {
    _lineWidth = lineWidth;
    self.shapeLayer.lineWidth = lineWidth;
}

- (void)setLineColor:(UIColor *)lineColor {
    if (!lineColor) return;
    _lineColor = lineColor;
    self.shapeLayer.strokeColor = lineColor.CGColor;
}

- (void)setHidesWhenStopped:(BOOL)hidesWhenStopped {
    _hidesWhenStopped = hidesWhenStopped;
    self.hidden = !self.isAnimating && hidesWhenStopped;
}

@end
