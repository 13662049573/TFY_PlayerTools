//
//  TFY_NetworkSpeedMonitor.m
//  TFY_PlayerView
//
//  Created by 田风有 on 2019/6/30.
//  Copyright © 2019 田风有. All rights reserved.
//

#import "TFY_NetworkSpeedMonitor.h"
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <net/if_dl.h>

NSString *const DownloadNetworkSpeedNotificationKey = @"DownloadNetworkSpeedNotificationKey";
NSString *const UploadNetworkSpeedNotificationKey   = @"UploadNetworkSpeedNotificationKey";
NSString *const NetworkSpeedNotificationKey         = @"NetworkSpeedNotificationKey";

@interface TFY_NetworkSpeedMonitor ()
{
    // 总网速
    uint32_t _iBytes;
    uint32_t _oBytes;
    uint32_t _allFlow;
    
    // wifi网速
    uint32_t _wifiIBytes;
    uint32_t _wifiOBytes;
    uint32_t _wifiFlow;
    
    // 3G网速
    uint32_t _wwanIBytes;
    uint32_t _wwanOBytes;
    uint32_t _wwanFlow;
}

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) dispatch_source_t speedTimer;
@property (nonatomic, strong) dispatch_queue_t speedQueue;
@property (nonatomic, strong) NSString *lastDownloadSpeed;
@property (nonatomic, strong) NSString *lastUploadSpeed;

@end

@implementation TFY_NetworkSpeedMonitor

- (instancetype)init {
    if (self = [super init]) {
        _iBytes = _oBytes = _allFlow = _wifiIBytes = _wifiOBytes = _wifiFlow = _wwanIBytes = _wwanOBytes = _wwanFlow = 0;
        _speedQueue = dispatch_queue_create("com.tfy.networkspeed", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    [self stopNetworkSpeedMonitor];
}

// 开始监听网速 - 使用GCD定时器替代NSTimer
- (void)startNetworkSpeedMonitor {
    if (_speedTimer) {
        [self stopNetworkSpeedMonitor];
    }
    
    _speedTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _speedQueue);
    dispatch_source_set_timer(_speedTimer, dispatch_time(DISPATCH_TIME_NOW, 0), 1.0 * NSEC_PER_SEC, 0.1 * NSEC_PER_SEC);
    
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_speedTimer, ^{
        [weakSelf checkNetworkSpeed];
    });
    
    dispatch_resume(_speedTimer);
}

// 停止监听网速
- (void)stopNetworkSpeedMonitor {
    if (_speedTimer) {
        dispatch_source_cancel(_speedTimer);
        _speedTimer = nil;
    }
    if ([_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
}

// 优化字符串格式化，使用缓存避免重复计算
- (NSString *)stringWithbytes:(int)bytes {
    static NSCache *formatCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatCache = [[NSCache alloc] init];
        formatCache.countLimit = 100; // 限制缓存大小
    });
    
    NSString *key = [@(bytes) stringValue];
    NSString *cached = [formatCache objectForKey:key];
    if (cached) {
        return cached;
    }
    
    NSString *result;
    if (bytes < 1024) { // B
        result = [NSString stringWithFormat:@"%dB", bytes];
    } else if (bytes >= 1024 && bytes < 1024 * 1024) { // KB
        result = [NSString stringWithFormat:@"%.0fKB", (double)bytes / 1024];
    } else if (bytes >= 1024 * 1024 && bytes < 1024 * 1024 * 1024) { // MB
        result = [NSString stringWithFormat:@"%.1fMB", (double)bytes / (1024 * 1024)];
    } else { // GB
        result = [NSString stringWithFormat:@"%.1fGB", (double)bytes / (1024 * 1024 * 1024)];
    }
    
    [formatCache setObject:result forKey:key];
    return result;
}

- (void)checkNetworkSpeed {
    struct ifaddrs *ifa_list = 0, *ifa;
    if (getifaddrs(&ifa_list) == -1) return;
    
    uint32_t iBytes = 0;
    uint32_t oBytes = 0;
    uint32_t allFlow = 0;
    uint32_t wifiIBytes = 0;
    uint32_t wifiOBytes = 0;
    uint32_t wifiFlow = 0;
    uint32_t wwanIBytes = 0;
    uint32_t wwanOBytes = 0;
    uint32_t wwanFlow = 0;
    
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
        if (AF_LINK != ifa->ifa_addr->sa_family) continue;
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING)) continue;
        if (ifa->ifa_data == 0) continue;
        
        // network
        if (strncmp(ifa->ifa_name, "lo", 2)) {
            struct if_data* if_data = (struct if_data*)ifa->ifa_data;
            iBytes += if_data->ifi_ibytes;
            oBytes += if_data->ifi_obytes;
            allFlow = iBytes + oBytes;
        }
        
        //wifi
        if (!strcmp(ifa->ifa_name, "en0")) {
            struct if_data* if_data = (struct if_data*)ifa->ifa_data;
            wifiIBytes += if_data->ifi_ibytes;
            wifiOBytes += if_data->ifi_obytes;
            wifiFlow = wifiIBytes + wifiOBytes;
        }
        
        //3G or gprs
        if (!strcmp(ifa->ifa_name, "pdp_ip0")) {
            struct if_data* if_data = (struct if_data*)ifa->ifa_data;
            wwanIBytes += if_data->ifi_ibytes;
            wwanOBytes += if_data->ifi_obytes;
            wwanFlow = wwanIBytes + wwanOBytes;
        }
    }
    
    freeifaddrs(ifa_list);
    
    // 批量处理通知，减少主线程负担
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_iBytes != 0) {
            NSString *currentDownloadSpeed = [[self stringWithbytes:iBytes - self->_iBytes] stringByAppendingString:@"/s"];
            // 只有速度变化时才发送通知
            if (![currentDownloadSpeed isEqualToString:self.lastDownloadSpeed]) {
                self.lastDownloadSpeed = currentDownloadSpeed;
                self->_downloadNetworkSpeed = currentDownloadSpeed;
                
                NSDictionary *userInfo = @{NetworkSpeedNotificationKey: self->_downloadNetworkSpeed};
                [[NSNotificationCenter defaultCenter] postNotificationName:DownloadNetworkSpeedNotificationKey object:nil userInfo:userInfo];
            }
        }
        
        if (self->_oBytes != 0) {
            NSString *currentUploadSpeed = [[self stringWithbytes:oBytes - self->_oBytes] stringByAppendingString:@"/s"];
            // 只有速度变化时才发送通知
            if (![currentUploadSpeed isEqualToString:self.lastUploadSpeed]) {
                self.lastUploadSpeed = currentUploadSpeed;
                self->_uploadNetworkSpeed = currentUploadSpeed;
                
                NSDictionary *userInfo = @{NetworkSpeedNotificationKey: self->_uploadNetworkSpeed};
                [[NSNotificationCenter defaultCenter] postNotificationName:UploadNetworkSpeedNotificationKey object:nil userInfo:userInfo];
            }
        }
    });
    
    _iBytes = iBytes;
    _oBytes = oBytes;
}

@end
