//
//  LM_TabBarController.m
//  Femalepregnancy
//
//  Created by tiandengyou on 2019/11/28.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "LM_TabBarController.h"
#import "HomeViewController.h"
#import "MineViewController.h"
@interface LM_TabBarController ()<TfySY_TabBarDelegate>

@end

@implementation LM_TabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 添加子VC
    [self addChildViewControllers];
   
    UIImage *images = [UIImage tfy_createImage:[UIColor tfy_colorWithHex:LCColor_B7]];
    [self.tabBar setShadowImage:images];
    
}

- (void)addChildViewControllers{
   
    NSArray<NSDictionary *>*VCArray = @[
    [self controller:HomeViewController.new normalImg:@"default_measure" selectImg:@"sel_measure" itemTitle:@"样式1"],
    [self controller:MineViewController.new normalImg:@"calendar" selectImg:@"calendar1" itemTitle:@"样式2"],
    ];

    NSMutableArray *tabBarConfs = @[].mutableCopy;
    NSMutableArray *tabBarVCs = @[].mutableCopy;
    [VCArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        TfySY_TabBarConfigModel *model = [TfySY_TabBarConfigModel new];
        model.itemTitle = [obj objectForKey:@"itemTitle"];
        model.selectImageName = [obj objectForKey:@"selectImg"];
        model.normalImageName = [obj objectForKey:@"normalImg"];
        model.normalColor = [UIColor tfy_colorWithHex:LCColor_A4];
        model.selectColor = [UIColor tfy_colorWithHex:LCColor_A5];
        UIViewController *vc = [obj objectForKey:@"vc"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [tabBarVCs addObject:nav];
        [tabBarConfs addObject:model];
    }];
    self.ControllerArray = tabBarVCs;
    self.tfySY_TabBar = [[TfySY_TabBar alloc] initWithTabBarConfig:tabBarConfs];
    self.tfySY_TabBar.backgroundColor = [UIColor whiteColor];
    self.tfySY_TabBar.delegate = self;
    [self.tabBar addSubview:self.tfySY_TabBar];

}

-(NSDictionary *)controller:(UIViewController*)vc normalImg:(NSString *)normalImg selectImg:(NSString *)selectImg itemTitle:(NSString *)itemTitle{
    NSDictionary *dict = @{@"vc":vc,@"normalImg":normalImg,@"selectImg":selectImg,@"itemTitle":itemTitle};
    return dict;
}

- (void)TfySY_TabBar:(TfySY_TabBar *)tabbar selectIndex:(NSInteger)index{
    [self setSelectedIndex:index];
}


@end
