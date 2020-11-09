//
//  TFY_LightTableViewCell.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/19.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_LightTableViewCell.h"
#import "profileView.h"
#import "HelpherderView.h"

@interface TFY_LightTableViewCell ()
@property(nonatomic , strong)profileView *profile_image;

@property(nonatomic , strong)UILabel *text_label;

@property(nonatomic , strong)UIImageView *bimageuri;

@property(nonatomic , strong)UIImageView *video_play;

@property(nonatomic , strong)HelpherderView *butom_View;

@property (nonatomic, strong) UIView *fullMaskView;

@property (nonatomic, strong) UIButton *playBtn;

@property (nonatomic, weak) id<TableViewCellDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *indexPath;
@end

@implementation TFY_LightTableViewCell

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
           
           [self.contentView addSubview:self.fullMaskView];
           self.fullMaskView.tfy_LeftSpace(20).tfy_TopSpaceToView(10, self.text_label).tfy_RightSpace(20).tfy_BottomSpaceToView(0, self.butom_View);
        
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

- (void)setDelegate:(id<TableViewCellDelegate>)delegate withIndexPath:(NSIndexPath *)indexPath {
    self.delegate = delegate;
    self.indexPath = indexPath;
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

- (void)setNormalMode {
    self.fullMaskView.hidden = YES;
    
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
        .font([UIFont systemFontOfSize:15 weight:UIFontWeightBold])
        .textAlignment(NSTextAlignmentCenter);
    }
    return _text_label;
}

-(UIImageView *)bimageuri{
    if (!_bimageuri) {
        _bimageuri = UIImageViewSet();
        _bimageuri.makeChain
        .makeTag(111).contentMode(UIViewContentModeScaleAspectFit).userInteractionEnabled(YES);
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
- (UIView *)fullMaskView {
    if (!_fullMaskView) {
        _fullMaskView = [UIView new];
        _fullMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        _fullMaskView.userInteractionEnabled = NO;
    }
    return _fullMaskView;
}

-(UIButton *)playBtn{
    if (!_playBtn) {
        _playBtn = UIButtonSet();
        _playBtn.makeChain
        .image([UIImage imageNamed:@""], UIControlStateNormal).addTarget(self, @selector(playBtnClick:), UIControlEventTouchUpInside);
    }
    return _playBtn;
}
- (void)playBtnClick:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(tfy_playTheVideoAtIndexPath:)]) {
        [self.delegate tfy_playTheVideoAtIndexPath:self.indexPath];
    }
}
@end
