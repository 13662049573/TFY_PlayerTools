//
//  BaseTableView.m
//  Thermometer
//
//  Created by tiandengyou on 2019/10/18.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "BaseTableView.h"


@interface BaseTableView ()
TFY_CATEGORY_STRONG_PROPERTY UIView *back_View;
@end

@implementation BaseTableView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.showsVerticalScrollIndicator=NO;
        self.showsHorizontalScrollIndicator=NO;
        self.separatorInset= UIEdgeInsetsMake(0,20,0,20);
        self.separatorColor = [UIColor tfy_ColorWithHexString:@"E8E8E8"];
        self.estimatedRowHeight=0;
        self.rowHeight=UITableViewAutomaticDimension;
        self.estimatedSectionFooterHeight = 0;
        self.estimatedSectionHeaderHeight = 0;
        self.pagingEnabled = YES;
        self.scrollsToTop = NO;
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        if (@available(iOS 13.0, *)) {
            self.automaticallyAdjustsScrollIndicatorInsets = NO;
        }
        self.backgroundColor = [UIColor tfy_colorWithHex:LCColor_B5];
        self.fillet_bool = NO;
    }
    return self;
}

-(void)setFillet_bool:(BOOL)fillet_bool{
    _fillet_bool = fillet_bool;
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.fillet_bool) {
        // 圆角弧度半径
        CGFloat cornerRadius = 6.f;
        // 设置cell的背景色为透明，如果不设置这个的话，则原来的背景色不会被覆盖
        cell.backgroundColor = UIColor.clearColor;
        
        // 创建一个shapeLayer
        CAShapeLayer *layer = [[CAShapeLayer alloc] init];
        CAShapeLayer *backgroundLayer = [[CAShapeLayer alloc] init]; //显示选中
        // 创建一个可变的图像Path句柄，该路径用于保存绘图信息
        CGMutablePathRef pathRef = CGPathCreateMutable();
        // 获取cell的size
        // 第一个参数,是整个 cell 的 bounds, 第二个参数是距左右两端的距离,第三个参数是距上下两端的距离
        CGRect bounds = CGRectInset(cell.bounds, 10, 0);
        
        // CGRectGetMinY：返回对象顶点坐标
        // CGRectGetMaxY：返回对象底点坐标
        // CGRectGetMinX：返回对象左边缘坐标
        // CGRectGetMaxX：返回对象右边缘坐标
        // CGRectGetMidX: 返回对象中心点的X坐标
        // CGRectGetMidY: 返回对象中心点的Y坐标
        
        // 这里要判断分组列表中的第一行，每组section的第一行，每组section的中间行
        // CGPathAddRoundedRect(pathRef, nil, bounds, cornerRadius, cornerRadius);
        if (indexPath.row == 0) {
            // 初始起点为cell的左下角坐标
            CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds));
            // 起始坐标为左下角，设为p，（CGRectGetMinX(bounds), CGRectGetMinY(bounds)）为左上角的点，设为p1(x1,y1)，(CGRectGetMidX(bounds), CGRectGetMinY(bounds))为顶部中点的点，设为p2(x2,y2)。然后连接p1和p2为一条直线l1，连接初始点p到p1成一条直线l，则在两条直线相交处绘制弧度为r的圆角。
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds), CGRectGetMidX(bounds), CGRectGetMinY(bounds), cornerRadius);
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
            // 终点坐标为右下角坐标点，把绘图信息都放到路径中去,根据这些路径就构成了一块区域了
            CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
            
        } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section]-1) {
            // 初始起点为cell的左上角坐标
            CGPathMoveToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMinY(bounds));
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMinX(bounds), CGRectGetMaxY(bounds), CGRectGetMidX(bounds), CGRectGetMaxY(bounds), cornerRadius);
            CGPathAddArcToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds), CGRectGetMaxX(bounds), CGRectGetMidY(bounds), cornerRadius);
            // 添加一条直线，终点坐标为右下角坐标点并放到路径中去
            CGPathAddLineToPoint(pathRef, nil, CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
        } else {
            // 添加cell的rectangle信息到path中（不包括圆角）
            CGPathAddRect(pathRef, nil, bounds);
        }
        // 把已经绘制好的可变图像路径赋值给图层，然后图层根据这图像path进行图像渲染render
        layer.path = pathRef;
        backgroundLayer.path = pathRef;
        // 注意：但凡通过Quartz2D中带有creat/copy/retain方法创建出来的值都必须要释放
        CFRelease(pathRef);
        // 按照shape layer的path填充颜色，类似于渲染render
        // layer.fillColor = [UIColor colorWithWhite:1.f alpha:0.8f].CGColor;
        layer.fillColor = [UIColor whiteColor].CGColor;
        // view大小与cell一致
        UIView *roundView = [[UIView alloc] initWithFrame:bounds];
        // 添加自定义圆角后的图层到roundView中
        [roundView.layer insertSublayer:layer atIndex:0];
        roundView.backgroundColor = UIColor.clearColor;
        // cell的背景view
        cell.backgroundView = roundView;
        
        // 以上方法存在缺陷当点击cell时还是出现cell方形效果，因此还需要添加以下方法
        // 如果你 cell 已经取消选中状态的话,那以下方法是不需要的.
        UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:bounds];
        backgroundLayer.fillColor = [UIColor cyanColor].CGColor;
        [selectedBackgroundView.layer insertSublayer:backgroundLayer atIndex:0];
        selectedBackgroundView.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = selectedBackgroundView;
        cell.layer.masksToBounds = YES;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section{
    if (self.fillet_bool) {
        view.tintColor = [UIColor tfy_colorWithHex:@"F3F3F7"];
    }
}

//下拉刷新
-(void)addharder
{
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
//    // 隐藏时间
    header.lastUpdatedTimeLabel.hidden = NO;
//    // 隐藏状态
    header.stateLabel.hidden = NO;
    
    self.mj_header= header;
    
    [self.mj_header beginRefreshing];
}

- (void)loadNewData{};

-(void)addfooter{
    MJRefreshBackNormalFooter *footer=[MJRefreshBackNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadfooter)];
    // 隐藏状态
    footer.stateLabel.hidden = NO;
    
    self.mj_footer =footer;
}

-(void)loadfooter{};

@end
