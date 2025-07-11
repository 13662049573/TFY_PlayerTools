//
//  UIImageView+PlayerImageView.m
//  TFY_PlayerTools
//
//  Created by 田风有 on 2020/7/17.
//  Copyright © 2020 田风有. All rights reserved.
//

#import "UIImageView+PlayerImageView.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import "TFY_PlayerPerformanceOptimizer.h"

@implementation PlayerImageDownloader

- (void)startDownloadImageWithUrl:(NSString *_Nullable)url
                         progress:(DownloadProgressBlock)progress
                         finished:(DownLoadDataCallBack)finished {
    self.progressBlock = progress;
    self.callbackOnFinished = finished;
    
    if ([NSURL URLWithString:url] == nil) {
        if (finished) { finished(nil,nil); }
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                       timeoutInterval:60];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    self.session = [NSURLSession sessionWithConfiguration:config
                                                 delegate:self
                                            delegateQueue:queue];
    NSURLSessionDownloadTask *task = [self.session downloadTaskWithRequest:request];
    [task resume];
    self.task = task;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSData *data = [NSData dataWithContentsOfURL:location];
    
    if (self.progressBlock) {
        self.progressBlock(self.totalLength, self.currentLength);
    }
    
    if (self.callbackOnFinished) {
        self.callbackOnFinished(data, nil);
        
        // 防止重复调用
        self.callbackOnFinished = nil;
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    self.currentLength = totalBytesWritten;
    self.totalLength = totalBytesExpectedToWrite;
    
    if (self.progressBlock) {
        self.progressBlock(self.totalLength, self.currentLength);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if ([error code] != NSURLErrorCancelled) {
        if (self.callbackOnFinished) {
            self.callbackOnFinished(nil, error);
        }
        self.callbackOnFinished = nil;
    }
}

@end

@interface NSString (md5)

+ (NSString *)player_cachedFileNameForKey:(NSString *)key;
+ (NSString *)player_cachePath;
+ (NSString *)player_keyForRequest:(NSURLRequest *)request;

@end

@implementation NSString (md5)

+ (NSString *)player_keyForRequest:(NSURLRequest *)request{
    return request.URL.absoluteString;
}

+ (NSString *)player_cachePath {
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *directoryPath = [NSString stringWithFormat:@"%@/%@/%@",cachePath,@"default",@"com.hackemist.SDWebImageCache.default"];
    return directoryPath;
}

+ (NSString *)player_cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], r[16], r[17], r[18], r[19], r[20],
                          r[21], r[22], r[23], r[24], r[25], r[26], r[27], r[28], r[29], r[30], r[31],
                          [[key pathExtension] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", [key pathExtension]]];
    
    return filename;
}

@end

@interface UIApplication (PlayerCacheImage)

@property (nonatomic, strong, readonly) NSMutableDictionary *player_cacheFaileTimes;

- (UIImage *)player_cacheImageForRequest:(NSURLRequest *)request;
- (void)player_cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request;
- (void)player_cacheFailRequest:(NSURLRequest *)request;
- (NSUInteger)player_failTimesForRequest:(NSURLRequest *)request;

@end

@implementation UIApplication (PlayerCacheImage)

- (NSMutableDictionary *)player_cacheFaileTimes {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, _cmd);
    if (!dict) {
        dict = [[NSMutableDictionary alloc] init];
    }
    return dict;
}

- (void)setPlayer_cacheFaileTimes:(NSMutableDictionary *)player_cacheFaileTimes {
    objc_setAssociatedObject(self, @selector(player_cacheFaileTimes), player_cacheFaileTimes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)player_clearCache {
    [self.player_cacheFaileTimes removeAllObjects];
    self.player_cacheFaileTimes = nil;
}

- (void)player_clearDiskCaches {
    NSString *directoryPath = [NSString player_cachePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        dispatch_queue_t ioQueue = dispatch_queue_create("com.hackemist.SDWebImageCache", DISPATCH_QUEUE_SERIAL);
        dispatch_async(ioQueue, ^{
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:&error];
            [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];
        });
    }
    [self player_clearCache];
}

- (UIImage *)player_cacheImageForRequest:(NSURLRequest *)request {
    if (request) {
        NSString *directoryPath = [NSString player_cachePath];
        NSString *path = [NSString stringWithFormat:@"%@/%@", directoryPath, [NSString player_cachedFileNameForKey:[NSString player_keyForRequest:request]]];
        return [UIImage imageWithContentsOfFile:path];
    }
    return nil;
}

- (NSUInteger)player_failTimesForRequest:(NSURLRequest *)request {
    NSNumber *faileTimes = [self.player_cacheFaileTimes objectForKey:[NSString player_cachedFileNameForKey:[NSString player_keyForRequest:request]]];
    if (faileTimes && [faileTimes respondsToSelector:@selector(integerValue)]) {
        return faileTimes.integerValue;
    }
    return 0;
}

- (void)player_cacheFailRequest:(NSURLRequest *)request {
    NSNumber *faileTimes = [self.player_cacheFaileTimes objectForKey:[NSString player_cachedFileNameForKey:[NSString player_keyForRequest:request]]];
    NSUInteger times = 0;
    if (faileTimes && [faileTimes respondsToSelector:@selector(integerValue)]) {
        times = [faileTimes integerValue];
    }
    
    times++;
    
    [self.player_cacheFaileTimes setObject:@(times) forKey:[NSString player_cachedFileNameForKey:[NSString player_keyForRequest:request]]];
}

- (void)player_cacheImage:(UIImage *)image forRequest:(NSURLRequest *)request {
    if (!image || !request) { return; }
    
    NSString *directoryPath = [NSString player_cachePath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) { return; }
    }
    
    NSString *path = [NSString stringWithFormat:@"%@/%@", directoryPath, [NSString player_cachedFileNameForKey:[NSString player_keyForRequest:request]]];
    NSData *data = UIImagePNGRepresentation(image);
    if (data) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
    }
}

@end

@implementation UIImageView (PlayerImageView)

#pragma mark - getter

- (PlayerImageBlock)completion
{
    return objc_getAssociatedObject(self, _cmd);
}

- (PlayerImageDownloader *)imageDownloader
{
    return objc_getAssociatedObject(self, _cmd);
}

- (NSUInteger)attemptToReloadTimesForFailedURL
{
    NSUInteger count = [objc_getAssociatedObject(self, _cmd) integerValue];
    if (count == 0) {  count = 2; }
    return count;
}

- (BOOL)shouldAutoClipImageToViewSize
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

#pragma mark - setter

- (void)setCompletion:(PlayerImageBlock)completion
{
    objc_setAssociatedObject(self, @selector(completion), completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setImageDownloader:(PlayerImageDownloader *)imageDownloader
{
    objc_setAssociatedObject(self, @selector(imageDownloader), imageDownloader, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setAttemptToReloadTimesForFailedURL:(NSUInteger)attemptToReloadTimesForFailedURL
{
    objc_setAssociatedObject(self, @selector(attemptToReloadTimesForFailedURL), @(attemptToReloadTimesForFailedURL), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setShouldAutoClipImageToViewSize:(BOOL)shouldAutoClipImageToViewSize
{
    objc_setAssociatedObject(self, @selector(shouldAutoClipImageToViewSize), @(shouldAutoClipImageToViewSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - public method

- (void)setImageWithURLString:(NSString *)url
         placeholderImageName:(NSString *)placeholderImageName {
    return [self setImageWithURLString:url placeholderImageName:placeholderImageName completion:nil];
}

- (void)setImageWithURLString:(NSString *)url placeholder:(UIImage *)placeholderImage {
    return [self setImageWithURLString:url placeholder:placeholderImage completion:nil];
}

- (void)setImageWithURLString:(NSString *_Nullable)url
         placeholderImageName:(NSString *_Nullable)placeholderImage
                   completion:(void (^ _Nullable)(UIImage *_Nullable image))completion {
    NSString *path = [[NSBundle mainBundle] pathForResource:placeholderImage ofType:nil];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    if (image == nil) { image = [UIImage imageNamed:placeholderImage]; }
    
    [self setImageWithURLString:url placeholder:image completion:completion];
}

- (void)setImageWithURLString:(NSString *_Nullable)url
                  placeholder:(UIImage *_Nullable)placeholderImageName
                   completion:(void (^ _Nullable)(UIImage *_Nullable image))completion {
    [self.layer removeAllAnimations];
    self.completion = completion;
    
    if (url == nil || [url isKindOfClass:[NSNull class]] || (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"])) {
        [self setImage:placeholderImageName isFromCache:YES];
        
        if (completion) {
            self.completion(self.image);
        }
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self downloadWithReqeust:request holder:placeholderImageName];
}

#pragma mark - private method

- (void)downloadWithReqeust:(NSURLRequest *)theRequest holder:(UIImage *)holder {
    UIImage *cachedImage = [[UIApplication sharedApplication] player_cacheImageForRequest:theRequest];
    
    if (cachedImage) {
        [self setImage:cachedImage isFromCache:YES];
        if (self.completion) {
            self.completion(cachedImage);
        }
        return;
    }
    
    [self setImage:holder isFromCache:YES];
    
    if ([[UIApplication sharedApplication] player_failTimesForRequest:theRequest] >= self.attemptToReloadTimesForFailedURL) {
        return;
    }
    
    [self cancelRequest];
    self.imageDownloader = nil;
    
    __weak __typeof(self) weakSelf = self;
    
    self.imageDownloader = [[PlayerImageDownloader alloc] init];
    [self.imageDownloader startDownloadImageWithUrl:theRequest.URL.absoluteString progress:nil finished:^(NSData *data, NSError *error) {
        // success
        if (data != nil && error == nil) {
            // 使用高质量队列进行图片处理
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                UIImage *image = [UIImage imageWithData:data];
                UIImage *finalImage = image;
                
                if (image) {
                    if (weakSelf.shouldAutoClipImageToViewSize) {
                        // 检查是否真的需要裁剪，避免不必要的计算
                        CGSize viewSize = weakSelf.frame.size;
                        if (!CGSizeEqualToSize(viewSize, CGSizeZero) && 
                            (fabs(viewSize.width - image.size.width) > 1.0 || 
                             fabs(viewSize.height - image.size.height) > 1.0)) {
                            finalImage = [self clipImage:image toSize:viewSize isScaleToMax:YES];
                        }
                    }
                    
                    // 异步缓存图片
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                        [[UIApplication sharedApplication] player_cacheImage:finalImage forRequest:theRequest];
                    });
                } else {
                    [[UIApplication sharedApplication] player_cacheFailRequest:theRequest];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong __typeof(weakSelf) strongSelf = weakSelf;
                    if (strongSelf && finalImage) {
                        [strongSelf setImage:finalImage isFromCache:NO];
                        
                        if (strongSelf.completion) {
                            strongSelf.completion(strongSelf.image);
                        }
                    } else if (strongSelf) {// error data
                        if (strongSelf.completion) {
                            strongSelf.completion(strongSelf.image);
                        }
                    }
                });
            });
        } else { // error
            [[UIApplication sharedApplication] player_cacheFailRequest:theRequest];
            
            if (weakSelf.completion) {
                weakSelf.completion(weakSelf.image);
            }
        }
    }];
}

- (void)setImage:(UIImage *)image isFromCache:(BOOL)isFromCache {
    // 避免重复设置相同的图片
    if (self.image == image) {
        return;
    }
    
    self.image = image;
    if (!isFromCache && image) {
        // 只有在图片真正改变时才添加动画
        CATransition *animation = [CATransition animation];
        [animation setDuration:0.2f]; // 进一步减少动画时间
        [animation setType:kCATransitionFade];
        animation.removedOnCompletion = YES;
        [self.layer addAnimation:animation forKey:@"transition"];
    }
}

- (void)cancelRequest {
    [self.imageDownloader.task cancel];
    self.imageDownloader = nil; // 立即释放
}

// 优化图片裁剪方法，添加缓存机制
- (UIImage *)clipImage:(UIImage *)image toSize:(CGSize)size isScaleToMax:(BOOL)isScaleToMax {
    // 如果尺寸相同，直接返回原图
    if (CGSizeEqualToSize(image.size, size)) {
        return image;
    }
    
    // 使用性能优化器的全局缓存
    TFY_PlayerPerformanceOptimizer *optimizer = [TFY_PlayerPerformanceOptimizer sharedOptimizer];
    
    NSString *cacheKey = [NSString stringWithFormat:@"clip_%.0fx%.0f_%.0fx%.0f_%d", 
                         image.size.width, image.size.height, 
                         size.width, size.height, isScaleToMax];
    
    UIImage *cachedImage = [optimizer.globalCache objectForKey:cacheKey];
    if (cachedImage) {
        return cachedImage;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    
    CGSize aspectFitSize = CGSizeZero;
    if (image.size.width != 0 && image.size.height != 0) {
        CGFloat rateWidth = size.width / image.size.width;
        CGFloat rateHeight = size.height / image.size.height;
        
        CGFloat rate = isScaleToMax ? MAX(rateHeight, rateWidth) : MIN(rateHeight, rateWidth);
        aspectFitSize = CGSizeMake(image.size.width * rate, image.size.height * rate);
    }
    
    [image drawInRect:CGRectMake(0, 0, aspectFitSize.width, aspectFitSize.height)];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 使用性能优化器缓存处理后的图片
    if (finalImage && optimizer.imageCacheOptimizationEnabled) {
        NSUInteger cost = (NSUInteger)(finalImage.size.width * finalImage.size.height * 4);
        [optimizer.globalCache setObject:finalImage forKey:cacheKey cost:cost];
    }
    
    return finalImage;
}

@end
