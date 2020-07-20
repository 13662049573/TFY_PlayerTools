//
//  TFY_CollectionCell.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/18.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_CollectionCell.h"

@interface TFY_CollectionCell ()
@property (nonatomic, strong) UIImageView *coverImageView,*bgImgView;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIView *effectView;
@end

@implementation TFY_CollectionCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.bgImgView];
        [self.bgImgView  tfy_AutoSize:0 top:0 right:0 bottom:0];
        
        [self.bgImgView addSubview:self.effectView];
        self.effectView.tfy_SizeEqualView(self.bgImgView);
        
        [self.contentView addSubview:self.coverImageView];
        [self.coverImageView tfy_AutoSize:0 top:0 right:0 bottom:0];
        
        [self.coverImageView addSubview:self.playBtn];
        self.playBtn.tfy_Center(0, 0).tfy_size(44, 44);
    }
    return self;
}

-(void)setListModel:(TFY_ListModel *)listModel{
    _listModel = listModel;
    
    [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:_listModel.thumbnail_url] placeholderImage:[UIImage imageNamed:@"loading_bgView"]];
    
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = tfy_imageView();
        _coverImageView.userInteractionEnabled = YES;
        _coverImageView.tag = 100;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _coverImageView;
}
-(UIImageView *)bgImgView{
    if (!_bgImgView) {
        _bgImgView = tfy_imageView();
    }
    return _bgImgView;
}
- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = tfy_button();
        _playBtn.tfy_image(@"new_allPlay_44x44_", UIControlStateNormal).tfy_action(self, @selector(playBtnClick:), UIControlEventTouchUpInside);
    }
    return _playBtn;
}
- (UIView *)effectView {
    if (!_effectView) {
        if (@available(iOS 8.0, *)) {
            UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        } else {
            UIToolbar *effectView = [[UIToolbar alloc] init];
            effectView.barStyle = UIBarStyleBlackTranslucent;
            _effectView = effectView;
        }
    }
    return _effectView;
}
- (void)playBtnClick:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(tfy_playTheVideoAtIndexPath:)]) {
        [self.delegate tfy_playTheVideoAtIndexPath:self.indexPath];
    }
}

@end
