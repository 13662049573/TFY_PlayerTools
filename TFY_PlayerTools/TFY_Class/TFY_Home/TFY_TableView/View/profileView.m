//
//  profileView.m
//  TFY_AutoLMTools
//
//  Created by 田风有 on 2019/6/14.
//  Copyright © 2019 恋机科技. All rights reserved.
//

#import "profileView.h"

@interface profileView ()
@property(nonatomic , strong)UIImageView *profile_image;

@property(nonatomic , strong)UILabel *name_label;

@property(nonatomic , strong)UILabel *time_label;

@property(nonatomic , strong)UIImageView *images;
@end

@implementation profileView

-(instancetype)initWithFrame:(CGRect)frame{
    if (self=[super initWithFrame:frame]) {
        
        [self addSubview:self.profile_image];
        self.profile_image.tfy_LeftSpace(20).tfy_CenterY(0).tfy_size(40, 40);
        
        [self addSubview:self.name_label];
        self.name_label.tfy_LeftSpaceToView(10, self.profile_image).tfy_TopSpace(10).tfy_RightSpace(100).tfy_Height(20);
        
        [self addSubview:self.time_label];
        self.time_label.tfy_LeftSpaceToView(10, self.profile_image).tfy_TopSpaceToView(0, self.name_label).tfy_RightSpace(100).tfy_BottomSpace(0);
        
        [self addSubview:self.images];
        self.images.tfy_RightSpace(20).tfy_CenterY(0).tfy_size(24, 20);
        
    }
    return self;
}

-(void)setModels:(TFY_ListModel *)models{
    _models = models;
   
    [self.profile_image tfy_setImageWithURLString:_models.profile_image placeholderImageName:@""];
    
    self.name_label.tfy_text(_models.name);

    self.time_label.tfy_text([NSDate timeInfoWithDateString:_models.passtime]);
}

-(UIImageView *)profile_image{
    if (!_profile_image) {
        _profile_image = tfy_imageView().tfy_cornerRadius(20);
    }
    return _profile_image;
}

-(UILabel *)name_label{
    if (!_name_label) {
        _name_label = tfy_label().tfy_textcolor(LCColor_B1, 1).tfy_alignment(0).tfy_fontSize([UIFont systemFontOfSize:14 weight:UIFontWeightHeavy]);
    }
    return _name_label;
}

-(UILabel *)time_label{
    if (!_time_label) {
        _time_label = tfy_label().tfy_textcolor(LCColor_B3, 1).tfy_alignment(0).tfy_fontSize([UIFont systemFontOfSize:12 weight:UIFontWeightBold]);
    }
    return _time_label;
}

-(UIImageView *)images{
    if (!_images) {
        _images = tfy_imageView().tfy_imge(@"cellmorebtnnormal");
    }
    return _images;
}
@end
