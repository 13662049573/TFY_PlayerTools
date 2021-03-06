//
//  TFY_CollectionBCell.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/20.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "TFY_CollectionBCell.h"

@interface TFY_CollectionBCell ()
TFY_PROPERTY_STRONG UIImageView *coverImageView;
@end

@implementation TFY_CollectionBCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.contentView addSubview:self.coverImageView];
        [self.coverImageView tfy_AutoSize:0 top:0 right:0 bottom:0];
    }
    return self;
}

-(void)setListModel:(TFY_ListModel *)listModel{
    _listModel = listModel;
    [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:_listModel.image_small] placeholderImage:[UIImage imageNamed:@"loading_bgView"]];
}

- (UIImageView *)coverImageView{
    if (!_coverImageView) {
        _coverImageView = UIImageViewSet();
        _coverImageView.makeChain
        .userInteractionEnabled(YES)
        .makeTag(100);
    }
    return _coverImageView;
}

- (void)playBtnClick:(UIButton *)sender {
    if (self.playBlock) {
        self.playBlock(sender);
    }
}
@end
