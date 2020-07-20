//
//  TFY_LightTableViewCell.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/19.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_LightTableViewCell.h"

@interface TFY_LightTableViewCell ()
@property (nonatomic, strong) UIImageView *coverImageView,*headImageView,*bgImgView;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UILabel *nickNameLabel,*titleLabel;
@property (nonatomic, strong) UIView *effectView,*fullMaskView;
@property (nonatomic, weak) id<TableViewCellDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *indexPath;
@end

@implementation TFY_LightTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
       [self.contentView addSubview:self.headImageView];
       self.headImageView.tfy_LeftSpace(20).tfy_TopSpace(10).tfy_size(35, 35);
       
       [self.contentView addSubview:self.nickNameLabel];
       self.nickNameLabel.tfy_LeftSpaceToView(10, self.headImageView).tfy_CenterYToView(0, self.headImageView).tfy_RightSpace(20).tfy_Height(30);
       
        [self.contentView addSubview:self.titleLabel];
        self.titleLabel.tfy_LeftSpaceEqualView(self.headImageView).tfy_TopSpaceToView(10, self.headImageView).tfy_RightSpaceEqualView(self.nickNameLabel).tfy_Height(40);
        
       [self.contentView addSubview:self.bgImgView];
       self.bgImgView.tfy_LeftSpace(0).tfy_TopSpaceToView(10, self.titleLabel).tfy_RightSpace(0).tfy_BottomSpace(0);
       
       [self.bgImgView addSubview:self.effectView];
       self.effectView.tfy_SizeEqualView(self.bgImgView);
       
       [self.contentView addSubview:self.coverImageView];
        self.coverImageView.tfy_LeftSpace(0).tfy_TopSpaceEqualView(self.bgImgView).tfy_RightSpace(0);
       
       [self.coverImageView addSubview:self.playBtn];
       self.playBtn.tfy_Center(0, 0).tfy_size(44, 44);
       
        [self.contentView addSubview:self.fullMaskView];
        self.fullMaskView.tfy_LeftSpace(0).tfy_TopSpaceEqualView(self.bgImgView).tfy_RightSpace(0).tfy_BottomSpace(0);
        
    }
    return self;
}

-(void)setListModel:(TFY_ListModel *)listModel{
    _listModel = listModel;
    
    [self.headImageView sd_setImageWithURL:[NSURL URLWithString:_listModel.head] placeholderImage:[UIImage imageNamed:@"defaultUserIcon"]];
    
    [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:_listModel.thumbnail_url] placeholderImage:[UIImage imageNamed:@"loading_bgView"]];
    
    self.nickNameLabel.tfy_text(_listModel.nick_name);
    
    self.titleLabel.tfy_text(_listModel.title);
    
    self.coverImageView.tfy_Height(_listModel.video_height);
}

- (void)setDelegate:(id<TableViewCellDelegate>)delegate withIndexPath:(NSIndexPath *)indexPath {
    self.delegate = delegate;
    self.indexPath = indexPath;
}

- (void)setNormalMode {
    self.fullMaskView.hidden = YES;
}

- (void)showMaskView {
    [UIView animateWithDuration:0.3 animations:^{
        self.fullMaskView.alpha = 1;
    }];
}

- (void)hideMaskView {
    [UIView animateWithDuration:0.3 animations:^{
        self.fullMaskView.alpha = 0;
    }];
}

- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = tfy_imageView();
        _coverImageView.userInteractionEnabled = YES;
        _coverImageView.tag = 200;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _coverImageView;
}

- (UIView *)fullMaskView {
    if (!_fullMaskView) {
        _fullMaskView = [UIView new];
        _fullMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        _fullMaskView.userInteractionEnabled = NO;
    }
    return _fullMaskView;
}
-(UIImageView *)headImageView{
    if (!_headImageView) {
        _headImageView = tfy_imageView();
    }
    return _headImageView;
}

-(UIImageView *)bgImgView{
    if (!_bgImgView) {
        _bgImgView = tfy_imageView();
    }
    return _bgImgView;
}

-(UILabel *)nickNameLabel{
    if (!_nickNameLabel) {
        _nickNameLabel = tfy_label();
        _nickNameLabel.tfy_textcolor(LCColor_B1, 1).tfy_fontSize([UIFont systemFontOfSize:14 weight:UIFontWeightRegular]).tfy_alignment(0).tfy_numberOfLines(0);
    }
    return _nickNameLabel;
}

- (UILabel *)titleLabel{
    if (!_titleLabel) {
        _titleLabel = tfy_label();
        _titleLabel.tfy_textcolor(LCColor_B1, 1).tfy_fontSize([UIFont systemFontOfSize:14 weight:UIFontWeightBold]).tfy_alignment(0).tfy_numberOfLines(0);
    }
    return _titleLabel;
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
