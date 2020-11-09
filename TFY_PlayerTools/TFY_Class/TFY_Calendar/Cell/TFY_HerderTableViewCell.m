//
//  TFY_HerderTableViewCell.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_HerderTableViewCell.h"

@interface TFY_HerderTableViewCell ()
TFY_PROPERTY_STRONG UIImageView *vido_imageView;
TFY_PROPERTY_STRONG UILabel *nick_Label;
@end

@implementation TFY_HerderTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [self.contentView addSubview:self.vido_imageView];
        self.vido_imageView.tfy_LeftSpace(10).tfy_TopSpace(5).tfy_BottomSpace(5).tfy_Width(100);
        
        [self.contentView addSubview:self.nick_Label];
        self.nick_Label.tfy_LeftSpaceToView(10, self.vido_imageView).tfy_TopSpaceEqualView(self.vido_imageView).tfy_BottomSpaceEqualView(self.vido_imageView).tfy_RightSpace(10);
    }
    return self;
}

-(void)setListModel:(TFY_ListModel *)listModel{
    _listModel = listModel;
    
    self.nick_Label.makeChain.text(_listModel.name);
    
    [self.vido_imageView sd_setImageWithURL:[NSURL URLWithString:_listModel.image_small] placeholderImage:[UIImage imageNamed:@"loading_bgView"]];
}

-(UILabel *)nick_Label {
    if (!_nick_Label) {
        _nick_Label = UILabelSet();
        _nick_Label.makeChain
        .textColor([UIColor tfy_colorWithHex:LCColor_B1])
        .numberOfLines(0)
        .textAlignment(NSTextAlignmentCenter)
        .font([UIFont systemFontOfSize:15 weight:UIFontWeightBold]);
    }
    return _nick_Label;
}

-(UIImageView *)vido_imageView{
    if (!_vido_imageView) {
        _vido_imageView = UIImageViewSet();
        _vido_imageView.makeChain
        .userInteractionEnabled(YES);
    }
    return _vido_imageView;
}

@end
