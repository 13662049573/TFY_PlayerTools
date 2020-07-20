//
//  UIImageView+PlayerImageView.h
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/17.
//  Copyright © 2020 田风有. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef void (^DownLoadDataCallBack)(NSData *data, NSError *error);
typedef void (^DownloadProgressBlock)(unsigned long long total, unsigned long long current);

@interface PlayerImageDownloader : NSObject<NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDownloadTask *task;

@property (nonatomic, assign) unsigned long long totalLength;
@property (nonatomic, assign) unsigned long long currentLength;

@property (nonatomic, copy) DownloadProgressBlock progressBlock;
@property (nonatomic, copy) DownLoadDataCallBack callbackOnFinished;

- (void)startDownloadImageWithUrl:(NSString *)url
                         progress:(DownloadProgressBlock)progress
                         finished:(DownLoadDataCallBack)finished;

@end

typedef void (^PlayerImageBlock)(UIImage *image);

@interface UIImageView (PlayerImageView)

@property (nonatomic, copy) PlayerImageBlock completion;

@property (nonatomic, strong) PlayerImageDownloader *imageDownloader;

@property (nonatomic, assign) NSUInteger attemptToReloadTimesForFailedURL;

@property (nonatomic, assign) BOOL shouldAutoClipImageToViewSize;

- (void)setImageWithURLString:(NSString *)url placeholderImageName:(NSString *)placeholderImageName;

- (void)setImageWithURLString:(NSString *)url placeholder:(UIImage *)placeholderImage;

- (void)setImageWithURLString:(NSString *)url
                  placeholder:(UIImage *)placeholderImage
                   completion:(void (^)(UIImage *image))completion;

- (void)setImageWithURLString:(NSString *)url
         placeholderImageName:(NSString *)placeholderImageName
                   completion:(void (^)(UIImage *image))completion;
@end

NS_ASSUME_NONNULL_END
