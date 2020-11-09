//
//  TFY_AutoPlayerCell.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/17.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_AutoPlayerCell.h"
#import "profileView.h"
#import "HelpherderView.h"

@interface TFY_AutoPlayerCell ()
@property(nonatomic , strong)profileView *profile_image;

@property(nonatomic , strong)UILabel *text_label;

@property(nonatomic , strong)UIImageView *bimageuri;

@property(nonatomic , strong)UIImageView *video_play;

@property(nonatomic , strong)HelpherderView *butom_View;

@property (nonatomic, strong) UIView *fullMaskView;

@property (nonatomic, strong) UIButton *playBtn;
@end

@implementation TFY_AutoPlayerCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
         [self.contentView addSubview:self.profile_image];
       self.profile_image.tfy_LeftSpace(0).tfy_TopSpace(0).tfy_RightSpace(0).tfy_Height(60);
       
       [self.contentView addSubview:self.text_label];
       self.text_label.tfy_LeftSpace(20).tfy_TopSpaceToView(0, self.profile_image).tfy_RightSpace(20).tfy_HeightAuto();
       
       [self.contentView addSubview:self.bimageuri];
       self.bimageuri.tfy_LeftSpace(20).tfy_TopSpaceToView(10, self.text_label).tfy_RightSpace(20).tfy_HeightAuto();
       
       [self.bimageuri addSubview:self.video_play];
       self.video_play.tfy_Center(0, 0).tfy_size(71, 71);
       
       [self.contentView addSubview:self.butom_View];
       self.butom_View.tfy_LeftSpace(0).tfy_TopSpaceToView(0, self.bimageuri).tfy_RightSpace(0).tfy_Height(40);
   
       [self.contentView addSubview:self.playBtn];
       self.playBtn.tfy_Center(0, 0).tfy_size(40, 40);
       
    }
    return self;
}

-(void)setListModel:(TFY_ListModel *)listModel{
    _listModel = listModel;
    
    self.profile_image.models = _listModel;
       
   self.text_label.makeChain.text(_listModel.text);
   
   self.bimageuri.tfy_Height(self.videoHeight);
   
    [self.bimageuri sd_setImageWithURL:[NSURL URLWithString:_listModel.bimageuri] placeholderImage:[UIImage imageNamed:@"defaultUserIcon"]];
   
   self.butom_View.models = _listModel;
    
}

- (BOOL)isVerticalVideo {
    return _listModel.width < _listModel.height;
}

- (CGFloat)videoHeight {
    CGFloat videoHeight;
    if (self.isVerticalVideo) {
        videoHeight = TFY_Width_W() * 0.6 * self.listModel.height/self.listModel.width;
    } else {
        videoHeight = TFY_Width_W() * self.listModel.height/self.listModel.width;
    }
    return videoHeight;
}

-(profileView *)profile_image{
    if (!_profile_image) {
        _profile_image = [profileView new];
    }
    return _profile_image;
}

-(UILabel *)text_label{
    if (!_text_label) {
        _text_label = UILabelSet();
        _text_label.makeChain
        .textColor([UIColor tfy_colorWithHex:LCColor_B1])
        .font([UIFont systemFontOfSize:15 weight:UIFontWeightLight])
        .textAlignment(NSTextAlignmentCenter);
    }
    return _text_label;
}

-(UIImageView *)bimageuri{
    if (!_bimageuri) {
        _bimageuri = UIImageViewSet();
        _bimageuri.makeChain
        .makeTag(100)
        .contentMode(UIViewContentModeScaleAspectFit)
        .userInteractionEnabled(YES);
    }
    return _bimageuri;
}

-(UIImageView *)video_play{
    if (!_video_play) {
        _video_play = UIImageViewSet();
        _video_play.makeChain
        .image([UIImage imageNamed:@"video-play"]);
    }
    return _video_play;
}

-(HelpherderView *)butom_View{
    if (!_butom_View) {
        _butom_View = [HelpherderView new];
    }
    return _butom_View;
}

-(UIButton *)playBtn{
    if (!_playBtn) {
        _playBtn = UIButtonSet();
        _playBtn.makeChain
        .image([UIImage imageNamed:@""], UIControlStateNormal)
        .addTarget(self, @selector(playBtnClick:), UIControlEventTouchUpInside);
    }
    return _playBtn;
}

- (void)playBtnClick:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(tfy_playTheVideoAtIndexPath:)]) {
        [self.delegate tfy_playTheVideoAtIndexPath:self.indexPath];
    }
}
@end
