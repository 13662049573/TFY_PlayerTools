//
//  TFY_LandscapeRotationManager_iOS16.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2023/3/16.
//  Copyright © 2023 田风有. All rights reserved.
//

#import "TFY_LandscapeRotationManager_iOS16.h"

@implementation TFY_LandscapeRotationManager_iOS16
@synthesize landscapeViewController = _landscapeViewController;

- (TFY_LandscapeViewController *)landscapeViewController {
    if (!_landscapeViewController) {
        _landscapeViewController = [[TFY_LandscapeViewController alloc] init];
    }
    return _landscapeViewController;
}

- (void)setNeedsUpdateOfSupportedInterfaceOrientations {
    if (@available(iOS 16.0, *)) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 160000
        UIWindow *keyWindow = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                keyWindow = scene.windows.firstObject;
                break;
            }
        }
        [keyWindow.rootViewController setNeedsUpdateOfSupportedInterfaceOrientations];
        [self.window.rootViewController setNeedsUpdateOfSupportedInterfaceOrientations];
#else
        UIWindow *keyWindow = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                keyWindow = scene.windows.firstObject;
                break;
            }
        }
        [(id)keyWindow.rootViewController setNeedsUpdateOfSupportedInterfaceOrientations];
        [(id)self.window.rootViewController setNeedsUpdateOfSupportedInterfaceOrientations];
#endif
    }
}

- (void)interfaceOrientation:(UIInterfaceOrientation)orientation completion:(void(^ __nullable)(void))completion {
    [super interfaceOrientation:orientation completion:completion];
    UIInterfaceOrientation fromOrientation = [self getCurrentOrientation];
    UIInterfaceOrientation toOrientation = orientation;
    
    UIWindow *sourceWindow = self.containerView.window;
    CGRect sourceFrame = [self.containerView convertRect:self.containerView.bounds toView:sourceWindow];
    CGRect screenBounds = UIScreen.mainScreen.bounds;
    CGFloat maxSize = MAX(screenBounds.size.width, screenBounds.size.height);
    CGFloat minSize = MIN(screenBounds.size.width, screenBounds.size.height);
  
    self.contentView.autoresizingMask = UIViewAutoresizingNone;
    if (toOrientation == UIInterfaceOrientationPortrait) {
        self.contentView.bounds = CGRectMake(0, 0, maxSize, minSize);
        self.contentView.center = CGPointMake(minSize * 0.5, maxSize * 0.5);
        self.contentView.transform = [self getRotationTransform:fromOrientation];
        [sourceWindow addSubview:self.contentView];
        [sourceWindow makeKeyAndVisible];
        [self.contentView layoutIfNeeded];
        self.window.hidden = YES;
    } else if (fromOrientation == UIInterfaceOrientationPortrait || self.contentView.superview != self.landscapeViewController.view) {
        self.contentView.frame = sourceFrame;
        [sourceWindow addSubview:self.contentView];
        [self.contentView layoutIfNeeded];
        if (!self.window.isKeyWindow) {
            self.window.hidden = NO;
            [self.window makeKeyAndVisible];
        }
    }
    [self setNeedsUpdateOfSupportedInterfaceOrientations];

    CGRect rotationBounds = CGRectZero;
    CGPoint rotationCenter = CGPointZero;
    
    if (UIInterfaceOrientationIsLandscape(toOrientation)) {
        rotationBounds = CGRectMake(0, 0, maxSize, minSize);
        rotationCenter = (fromOrientation == UIInterfaceOrientationPortrait || self.contentView.superview != self.landscapeViewController.view) ? CGPointMake(minSize * 0.5,  maxSize * 0.5): CGPointMake(maxSize * 0.5, minSize * 0.5);
    }
    
    // transform
    CGAffineTransform rotationTransform = CGAffineTransformIdentity;
    if (fromOrientation == UIInterfaceOrientationPortrait) {
        rotationTransform = [self getRotationTransform:toOrientation];
    }
    
    self.currentOrientation = toOrientation;
    if (self.orientationWillChange) self.orientationWillChange(toOrientation);
    if (self.disableAnimations) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }
    [UIView animateWithDuration:0.3 animations:^{
        if (toOrientation == UIInterfaceOrientationPortrait) {
            [self.contentView setTransform:rotationTransform];
            self.contentView.frame = sourceFrame;
        } else {
            [self.contentView setTransform:rotationTransform];
            [self.contentView setBounds:rotationBounds];
            [self.contentView setCenter:rotationCenter];
        }
        [self.contentView layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (self.disableAnimations) {
            [CATransaction commit];
        }
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if (toOrientation == UIInterfaceOrientationPortrait) {
            [self.containerView addSubview:self.contentView];
            self.contentView.frame = self.containerView.bounds;
        } else {
            [self setNeedsUpdateOfSupportedInterfaceOrientations];
            self.contentView.transform = CGAffineTransformIdentity;
            [self.landscapeViewController.view addSubview:self.contentView];
            self.contentView.frame = self.window.bounds;
            [self.contentView layoutIfNeeded];
        }
        if (self.orientationDidChanged) self.orientationDidChanged(toOrientation);
        if (completion) completion();
    }];
}


- (UIView *)fullScreenContainerView {
    return self.landscapeViewController.view;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {
    if (window == self.window) {
        return 1 << self.currentOrientation;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (CGAffineTransform)getRotationTransform:(UIInterfaceOrientation)orientation {
    CGAffineTransform rotationTransform = CGAffineTransformIdentity;
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        rotationTransform = CGAffineTransformMakeRotation(-M_PI_2);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        rotationTransform = CGAffineTransformMakeRotation(M_PI_2);
    }
    return rotationTransform;
}

@end
