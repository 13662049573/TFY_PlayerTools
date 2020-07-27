//
//  TFY_RootModel.h
//  TFY_CodeBuilder
//
//  Created by 田风有 on 2020/07/17.
//  Copyright © 2020 TFY_CodeBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TFY_ListModel;
@class TFY_InfoModel;

@interface PlayerCommand : NSObject
TFY_CATEGORY_CHAIN_PROPERTY NSString *maxtime;

TFY_CATEGORY_STRONG_PROPERTY RACCommand *playerCommand;

TFY_CATEGORY_STRONG_PROPERTY RACCommand *maxtimehelpCommand;
@end



@interface TFY_RootModel : NSObject

/**
 * info: info
 */
@property (nonatomic, strong) TFY_InfoModel *info;
/**
 * list: list
 */
@property (nonatomic, strong) NSArray <TFY_ListModel *> *list;

@end



@interface TFY_InfoModel : NSObject

/**
 * maxid:
 */
@property (nonatomic, copy) NSString *maxid;
/**
 * vendor: sheep
 */
@property (nonatomic, copy) NSString *vendor;
/**
 * count: 2000
 */
@property (nonatomic, assign) NSInteger count;
/**
 * maxtime:
 */
@property (nonatomic, copy) NSString *maxtime;
/**
 * page: 100
 */
@property (nonatomic, assign) NSInteger page;

@end



@interface TFY_ListModel : NSObject

/**
 * cache_version: 2
 */
@property (nonatomic, assign) NSInteger cache_version;
/**
 * created_at: created_at
 */
@property (nonatomic, copy) NSString *created_at;
/**
 * 31470784: 31470784
 */
@property (nonatomic, assign) NSInteger item_Id;
/**
 * is_gif: 0
 */
@property (nonatomic, copy) NSString *is_gif;
/**
 * voicetime: 0
 */
@property (nonatomic, copy) NSString *voicetime;
/**
 * image2: image2
 */
@property (nonatomic, copy) NSString *image2;
/**
 * voicelength: 0
 */
@property (nonatomic, assign) NSInteger voicelength;
/**
 * playfcount: 2148
 */
@property (nonatomic, copy) NSString *playfcount;
/**
 * repost: 14
 */
@property (nonatomic, copy) NSString *repost;
/**
 * bimageuri: bimageuri
 */
@property (nonatomic, copy) NSString *bimageuri;
/**
 * image1: image1
 */
@property (nonatomic, copy) NSString *image1;
/**
 * text: text
 */
@property (nonatomic, copy) NSString *text;
/**
 * theme_type: 1
 */
@property (nonatomic, assign) NSInteger theme_type;
/**
 * hate: 29
 */
@property (nonatomic, copy) NSString *hate;
/**
 * image0: image0
 */
@property (nonatomic, copy) NSString *image0;
/**
 * comment: 26
 */
@property (nonatomic, copy) NSString *comment;
/**
 * passtime: passtime
 */
@property (nonatomic, copy) NSString *passtime;
/**
 * ding: 259
 */
@property (nonatomic, assign) NSInteger ding;
/**
 * type: 41
 */
@property (nonatomic, copy) NSString *type;
/**
 * playcount: 6322
 */
@property (nonatomic, copy) NSString *playcount;
/**
 * tag:
 */
@property (nonatomic, copy) NSString *tag;
/**
 * cdn_img: cdn_img
 */
@property (nonatomic, copy) NSString *cdn_img;
/**
 * theme_name: 搞笑视频
 */
@property (nonatomic, copy) NSString *theme_name;
/**
 * create_time: create_time
 */
@property (nonatomic, copy) NSString *create_time;
/**
 * favourite: 12
 */
@property (nonatomic, copy) NSString *favourite;
/**
 * name: 孤傲猎人
 */
@property (nonatomic, copy) NSString *name;
/**
 * height: 960
 */
@property (nonatomic, assign) CGFloat height;
/**
 * status: 4
 */
@property (nonatomic, assign) NSInteger status;
/**
 * videotime: 25
 */
@property (nonatomic, assign) CGFloat videotime;
/**
 * bookmark: 12
 */
@property (nonatomic, assign) NSInteger bookmark;
/**
 * cai: 29
 */
@property (nonatomic, assign) NSInteger cai;
/**
 * screen_name: 孤傲猎人
 */
@property (nonatomic, copy) NSString *screen_name;
/**
 * profile_image: profile_image
 */
@property (nonatomic, copy) NSString *profile_image;
/**
 * love: 259
 */
@property (nonatomic, copy) NSString *love;
/**
 * user_id: 22281854
 */
@property (nonatomic, assign) NSInteger user_id;
/**
 * theme_id: 58191
 */
@property (nonatomic, assign) NSInteger theme_id;
/**
 * original_pid: 0
 */
@property (nonatomic, copy) NSString *original_pid;
/**
 * t: 1594729625
 */
@property (nonatomic, assign) NSInteger t;
/**
 * image_small: image_small
 */
@property (nonatomic, copy) NSString *image_small;
/**
 * weixin_url: weixin_url
 */
@property (nonatomic, copy) NSString *weixin_url;
/**
 * voiceuri:
 */
@property (nonatomic, copy) NSString *voiceuri;
/**
 * videouri: videouri
 */
@property (nonatomic, copy) NSString *videouri;
/**
 * width: 544
 */
@property (nonatomic, assign) CGFloat width;

@end


