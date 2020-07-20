//
//  TFY_RootModel.h
//  TFY_CodeBuilder
//
//  Created by 田风有 on 2020/07/17.
//  Copyright © 2020 TFY_CodeBuilder. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TFY_PageModel;
@class TFY_ListModel;

@interface PlayerCommand : NSObject
TFY_CATEGORY_STRONG_PROPERTY RACCommand *playerCommand;
@end



@interface TFY_RootModel : NSObject

/**
 * page: page 
 */
@property (nonatomic, strong) TFY_PageModel *page;
/**
 * list: list 
 */
@property (nonatomic, strong) NSArray <TFY_ListModel *> *list;

@end



@interface TFY_ListModel : NSObject

/**
 * has_agree: 0 
 */
@property (nonatomic, copy) NSString *has_agree;
/**
 * head: head 
 */
@property (nonatomic, copy) NSString *head;
/**
 * video_width: 240 
 */
@property (nonatomic, assign) CGFloat video_width;
/**
 * origin_video_url: origin_video_url 
 */
@property (nonatomic, copy) NSString *origin_video_url;
/**
 * video_size: 3612804 
 */
@property (nonatomic, assign) CGFloat video_size;
/**
 * post_num: 156 
 */
@property (nonatomic, assign) NSInteger post_num;
/**
 * first_post_id: 119310484126 
 */
@property (nonatomic, assign) NSInteger first_post_id;
/**
 * agree_num: 714 
 */
@property (nonatomic, assign) NSInteger agree_num;
/**
 * play_count: 278486 
 */
@property (nonatomic, assign) NSInteger play_count;
/**
 * nick_name: 紫枫 
 */
@property (nonatomic, copy) NSString *nick_name;
/**
 * forum_id: 0 
 */
@property (nonatomic, assign) NSInteger forum_id;
/**
 * thread_id: 5661313780 
 */
@property (nonatomic, assign) NSInteger thread_id;
/**
 * extra: extra 
 */
@property (nonatomic, copy) NSString *extra;
/**
 * video_md5: video_md5 
 */
@property (nonatomic, copy) NSString *video_md5;
/**
 * create_time: 1524382168 
 */
@property (nonatomic, copy) NSString *create_time;
/**
 * freq_num: 24205 
 */
@property (nonatomic, copy) NSString *freq_num;
/**
 * source: 131027 
 */
@property (nonatomic, copy) NSString *source;
/**
 * thumbnail_width: 240 
 */
@property (nonatomic, assign) CGFloat thumbnail_width;
/**
 * video_duration: 44 
 */
@property (nonatomic, assign) CGFloat video_duration;
/**
 * video_height: 176 
 */
@property (nonatomic, assign) CGFloat video_height;
/**
 * thumbnail_url: thumbnail_url 
 */
@property (nonatomic, copy) NSString *thumbnail_url;
/**
 * thumbnail_height: 176 
 */
@property (nonatomic, assign) CGFloat thumbnail_height;
/**
 * video_length: 3612804 
 */
@property (nonatomic, assign) NSInteger video_length;
/**
 * video_type: 2 
 */
@property (nonatomic, assign) NSInteger video_type;
/**
 * cover_text:  
 */
@property (nonatomic, copy) NSString *cover_text;
/**
 * video_log_id: video_log_id 
 */
@property (nonatomic, copy) NSString *video_log_id;
/**
 * auditing: 0 
 */
@property (nonatomic, copy) NSString *auditing;
/**
 * video_url: video_url 
 */
@property (nonatomic, copy) NSString *video_url;
/**
 * share_num: 262 
 */
@property (nonatomic, assign) NSInteger share_num;
/**
 * title: title 
 */
@property (nonatomic, copy) NSString *title;
/**
 * weight: weight 
 */
@property (nonatomic, copy) NSString *weight;
/**
 * format_matched: 1 
 */
@property (nonatomic, copy) NSString *format_matched;
/**
 * abtest_tag: tag_15 
 */
@property (nonatomic, copy) NSString *abtest_tag;

@end


@interface TFY_PageModel : NSObject

/**
 * pn: 1 
 */
@property (nonatomic, assign) NSInteger pn;
/**
 * rn: 21 
 */
@property (nonatomic, assign) NSInteger rn;

@end

