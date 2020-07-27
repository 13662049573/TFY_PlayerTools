//
//  HelpherderView.m
//  TFY_AutoLMTools
//
//  Created by 田风有 on 2019/6/11.
//  Copyright © 2019 恋机科技. All rights reserved.
//

#import "HelpherderView.h"

@interface HelpherderView ()
@property(nonatomic , strong)TFY_StackView *stackView;

@property(nonatomic , strong)UIButton *button;
@end

@implementation HelpherderView

-(instancetype)initWithFrame:(CGRect)frame{
    if (self=[super initWithFrame:frame]) {
        
        [self addSubview:self.stackView];
        [self.stackView tfy_AutoSize:0 top:0 right:0 bottom:0];
        
        NSArray *imgeArr = @[@"mainCellDing",@"mainCellCai",@"mainCellComment",@"mainCellShare"];
        NSArray *SelectedArr = @[@"mainCellDingClick",@"mainCellCaiClick",@"mainCellCommentClick",@"mainCellShareClick"];
        [imgeArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            UIButton *button = tfy_button().tfy_font([UIFont systemFontOfSize:13 weight:UIFontWeightMedium]).tfy_textcolor(@"666666",UIControlStateNormal).tfy_action(self,@selector(buttonClick:),UIControlEventTouchUpInside).tfy_image(obj,UIControlStateNormal).tfy_backgroundColor(@"ffffff",1).tfy_image(SelectedArr[idx],UIControlStateSelected);
            button.tag = idx+1;
            button.titleLabel.adjustsFontSizeToFitWidth = YES;
            [button tfy_layouEdgeInsetsPosition:ButtonPositionImageLeft_titleRight spacing:5];
            self.button = button;
            [self.stackView addSubview:button];
        }];
        
        [self.stackView tfy_StartLayout];
    }
    return self;
}

-(void)setModels:(TFY_ListModel *)models{
    _models = models;
    UIButton *btn1 = (UIButton *)[self viewWithTag:self.button.tag-3];
    btn1.tfy_text(_models.love,UIControlStateNormal);

    UIButton *btn2 = (UIButton *)[self viewWithTag:self.button.tag-2];
    btn2.tfy_text(_models.hate,UIControlStateNormal);

    UIButton *btn3 = (UIButton *)[self viewWithTag:self.button.tag-1];
    btn3.tfy_text(_models.comment,UIControlStateNormal);

    UIButton *btn4 = (UIButton *)[self viewWithTag:self.button.tag];
    btn4.tfy_text(_models.repost,UIControlStateNormal);
    
}

-(void)buttonClick:(UIButton *)btn{
    if (btn.tag==1) {
        UIButton *btn1 = (UIButton *)[self viewWithTag:btn.tag];
        btn1.selected = !btn1.selected;
        if (btn1.selected) {
            [TFY_ProgressHUD showSuccessWithStatus:@"谢谢你的点赞!"];
        }
        else{
           [TFY_ProgressHUD showSuccessWithStatus:@"取消点赞!"];
        }
    }
    else if (btn.tag==2){
        
        UIButton *btn2 = (UIButton *)[self viewWithTag:btn.tag];
        btn2.selected = !btn2.selected;
        if (btn2.selected) {
            [TFY_ProgressHUD showSuccessWithStatus:@"差评!"];
        }
        else{
            [TFY_ProgressHUD showSuccessWithStatus:@"取消差评!"];
        }
    }
    else if (btn.tag==3){
        
        UIButton *btn3 = (UIButton *)[self viewWithTag:btn.tag];
        btn3.selected = !btn3.selected;
        if (btn3.selected) {
            [TFY_ProgressHUD showSuccessWithStatus:@"留言!"];
        }
        else{
           [TFY_ProgressHUD showSuccessWithStatus:@"不留言!"];
        }
    }
    else if (btn.tag ==4){
        
        UIButton *btn4 = (UIButton *)[self viewWithTag:btn.tag];
        btn4.selected = !btn4.selected;
        if (btn4.selected) {
            [TFY_ProgressHUD showSuccessWithStatus:@"分享最新消息!"];
        }
        else{
           [TFY_ProgressHUD showSuccessWithStatus:@"取消最新消息!"];
        }
    }
}

-(TFY_StackView *)stackView{
    if (!_stackView) {
        _stackView = [TFY_StackView new];
        _stackView.backgroundColor = [UIColor tfy_colorWithHex:@"C5CEDA"];
        _stackView.tfy_Edge = UIEdgeInsetsMake(1, 1, 1, 1);
        _stackView.tfy_Orientation = Horizontal;// 自动横向垂直混合布局
        _stackView.tfy_HSpace = 1;
        _stackView.tfy_VSpace = 1;
    }
    return _stackView;
}

@end
