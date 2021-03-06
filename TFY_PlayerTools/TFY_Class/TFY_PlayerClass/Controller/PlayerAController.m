//
//  PlayerAController.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/17.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "PlayerAController.h"

@interface PlayerAController ()

TFY_PROPERTY_STRONG NSMutableArray *urlArray;

TFY_PROPERTY_STRONG NSString *ids;

TFY_PROPERTY_ASSIGN NSInteger seekpalyertime;

TFY_PROPERTY_ASSIGN NSTimeInterval delay;
@end

@implementation PlayerAController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.player.viewControllerDisappear = NO;
    
    [self AppDelegateenablePortrait:YES lockedScreen:NO];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
     self.player.viewControllerDisappear = YES;
    
    [self AppDelegateenablePortrait:NO lockedScreen:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.playermodels = [TFY_RootModel new];
    
    [self addDeviceOrientationObserver];
}

- (void)requestData:(void (^)(id x))nextBlock {
    PlayerCommand *comd = [PlayerCommand new];
    [[comd.playerCommand execute:@1] subscribeNext:^(id  _Nullable x) {
       
        TFY_RootModel *models = x;
        self.urls = NSMutableArray.array;
        
        [models.list enumerateObjectsUsingBlock:^(TFY_ListModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            TFY_PlayerVideoModel *model = [TFY_PlayerVideoModel new];
            model.tfy_url = obj.videouri;
            [self.urls addObject:model];
            
        }];
        
        self.player.assetUrlMododels = self.urls;
        
        self.playermodels = models;
        
        nextBlock(models);
        
    }];
}

- (void)addDeviceOrientationObserver {
    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)AppDelegateenablePortrait:(BOOL)enablebool lockedScreen:(BOOL)lockedScreen{
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.enablePortrait = enablebool;
    delegate.lockedScreen = lockedScreen;
}

-(void)handleDeviceOrientationChange{
    if (self.player.lockedScreen) {
        [self AppDelegateenablePortrait:YES lockedScreen:YES];
    }
    else{
       [self AppDelegateenablePortrait:YES lockedScreen:NO];
    }
}
-(UIImageView *)imageViews{
    if (!_imageViews) {
        _imageViews = UIImageViewSet();
        [_imageViews sd_setImageWithURL:[NSURL URLWithString:kVideoCover] placeholderImage:[UIImage imageNamed:@"loading_bgView"]];
    }
    return _imageViews;
}

-(void)seekpalyertimeClick{
    [self.player seekToTime:self.seekpalyertime completionHandler:^(BOOL finished) {
        [self.player.currentPlayerManager play];
    }];
}

@end
