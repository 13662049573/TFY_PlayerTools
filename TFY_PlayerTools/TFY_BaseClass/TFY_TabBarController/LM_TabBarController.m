//
//  LM_TabBarController.m
//  Femalepregnancy
//
//  Created by tiandengyou on 2019/11/28.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "LM_TabBarController.h"
#import "LX_HomeController.h"
#import "LX_CurveController.h"
#import "LX_MineController.h"
#import "LX_CalendarController.h"

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
    TFY_NavigationController *vc1 = [self navcontroller:[LX_HomeController new]];
    TFY_NavigationController *vc2 = [self navcontroller:[LX_CalendarController new]];
    TFY_NavigationController *vc3 = [self navcontroller:[LX_CurveController new]];
    TFY_NavigationController *vc5 = [self navcontroller:[LX_MineController new]];
   
    NSArray<NSDictionary *>*VCArray = @[
    [self controller:vc1 normalImg:@"default_measure" selectImg:@"sel_measure" itemTitle:@"样式1"],
    [self controller:vc2 normalImg:@"calendar" selectImg:@"calendar1" itemTitle:@"样式2"],
    [self controller:vc3 normalImg:@"default_report" selectImg:@"sel_report" itemTitle:@"样式3"],
    [self controller:vc5 normalImg:@"default_user" selectImg:@"sel_user" itemTitle:@"样式4"]
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
        [tabBarVCs addObject:vc];
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
