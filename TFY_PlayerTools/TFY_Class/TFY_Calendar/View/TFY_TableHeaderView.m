//
//  TFY_TableHeaderView.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_TableHeaderView.h"

@interface TFY_TableHeaderView ()
@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) NSIndexPath *indexPath;
@end

@implementation TFY_TableHeaderView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.tag = 100;
        [self addSubview:self.coverImageView];
        [self.coverImageView tfy_AutoSize:0 top:0 right:0 bottom:0];
        
        [self.coverImageView addSubview:self.playBtn];
        self.playBtn.tfy_Center(0, 0).tfy_size(44, 44);
    
    }
    return self;
}



- (void)playBtnClick:(UIButton *)sender {
    if (self.playCallback) {
        self.playCallback();
    }
}
#pragma mark - getter

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamed:@"new_allPlay_44x44_"] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(playBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.userInteractionEnabled = YES;
        _coverImageView.tag = 100;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        _coverImageView.clipsToBounds = YES;
        _coverImageView.image = [UIImage imageNamed:@"loading_bgView"];
    }
    return _coverImageView;
}

@end
