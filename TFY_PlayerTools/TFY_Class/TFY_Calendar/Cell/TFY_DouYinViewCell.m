//
//  TFY_DouYinViewCell.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/19.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_DouYinViewCell.h"

@interface TFY_DouYinViewCell ()
@property (nonatomic, strong) UIImageView *coverImageView;

@property (nonatomic, strong) UIButton *likeBtn;

@property (nonatomic, strong) UIButton *commentBtn;

@property (nonatomic, strong) UIButton *shareBtn;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIImage *placeholderImage;

@property (nonatomic, strong) UIImageView *bgImgView;

@property (nonatomic, strong) UIView *effectView;
@end

@implementation TFY_DouYinViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
       self.selectionStyle = UITableViewCellSelectionStyleNone;
        
       [self.contentView addSubview:self.bgImgView];
       [self.bgImgView tfy_AutoSize:0 top:0 right:0 bottom:0];
        
       [self.bgImgView addSubview:self.effectView];
       [self.effectView tfy_AutoSize:0 top:0 right:0 bottom:0];
        
       [self.contentView addSubview:self.coverImageView];
       [self.coverImageView tfy_AutoSize:0 top:0 right:0 bottom:0];
        
       [self.contentView addSubview:self.titleLabel];
        self.titleLabel.tfy_LeftSpace(20).tfy_BottomSpace(0).tfy_RightSpace(20).tfy_Height(TFY_kBottomBarHeight);
    
       [self.contentView addSubview:self.shareBtn];
        self.shareBtn.tfy_RightSpace(20).tfy_BottomSpaceToView(-10, self.titleLabel).tfy_size(60, 60);
        
       [self.contentView addSubview:self.commentBtn];
        self.commentBtn.tfy_RightSpaceEqualView(self.shareBtn).tfy_BottomSpaceToView(-20, self.shareBtn).tfy_size(60, 60);
        
       [self.contentView addSubview:self.likeBtn];
        self.likeBtn.tfy_RightSpaceEqualView(self.commentBtn).tfy_BottomSpaceToView(-20, self.commentBtn).tfy_size(60, 60);
    }
    return self;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont systemFontOfSize:15];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UIButton *)likeBtn {
    if (!_likeBtn) {
        _likeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_likeBtn setImage:[UIImage imageNamed:@"like"] forState:UIControlStateNormal];
    }
    return _likeBtn;
}


- (UIButton *)commentBtn {
    if (!_commentBtn) {
        _commentBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_commentBtn setImage:[UIImage imageNamed:@"comment"] forState:UIControlStateNormal];
    }
    return _commentBtn;
}

- (UIButton *)shareBtn {
    if (!_shareBtn) {
        _shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareBtn setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
    }
    return _shareBtn;
}

- (UIImage *)placeholderImage {
    if (!_placeholderImage) {
        _placeholderImage = [TFY_ITools imageWithColor:[UIColor colorWithRed:220/255.0 green:220/255.0 blue:220/255.0 alpha:1] size:CGSizeMake(1, 1)];
    }
    return _placeholderImage;
}

-(void)setListModel:(TFY_ListModel *)listModel{
    _listModel = listModel;
    
    if (_listModel.thumbnail_width >= _listModel.thumbnail_height) {
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.coverImageView.clipsToBounds = NO;
    } else {
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.coverImageView.clipsToBounds = YES;
    }
    [self.coverImageView setImageWithURLString:_listModel.thumbnail_url placeholder:[UIImage imageNamed:@"loading_bgView"]];
    [self.bgImgView setImageWithURLString:_listModel.thumbnail_url placeholder:[UIImage imageNamed:@"loading_bgView"]];
    self.titleLabel.text = _listModel.title;
    
}


- (UIImageView *)coverImageView {
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        _coverImageView.userInteractionEnabled = YES;
        _coverImageView.tag = 100;
    }
    return _coverImageView;
}

- (UIImageView *)bgImgView {
    if (!_bgImgView) {
        _bgImgView = [[UIImageView alloc] init];
        _bgImgView.userInteractionEnabled = YES;
    }
    return _bgImgView;
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

@end
