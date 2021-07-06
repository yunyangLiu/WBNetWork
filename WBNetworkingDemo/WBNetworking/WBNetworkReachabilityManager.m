//
//  WBNetworkReachabilityManager.m
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/6.
//

#import "WBNetworkReachabilityManager.h"

//只有在不是watchos的条件下进行编译
#if !TARGET_OS_WATCH

NSString * const WBNetworkingReachabilityDidChangeNotification = @"com.alamofire.networking.reachability.change";
NSString * const WBNetworkingReachabilityNotificationStatusItem = @"WBNetworkingReachabilityNotificationStatusItem";

typedef void (^WBNetworkReachabilityStatusBlock)(WBNetworkReachabilityStatus status);
typedef WBNetworkReachabilityManager * (^WBNetworkReachabilityStatusCallback)(WBNetworkReachabilityStatus status);

/*
 四种本地化语言文件的方法：
 1、必须使用系统默认的文件名Localizable.strings,如果tbl不存在返回key值
 #define NSLocalizedString(key, comment) \
         [NSBundle.mainBundle localizedStringForKey:(key) value:@"" table:nil]
 2、使用自己定义的名称tb1的strings，tb1,如果tbl不存在返回key值
 #define NSLocalizedStringFromTable(key, tbl, comment) \
         [NSBundle.mainBundle localizedStringForKey:(key) value:@"" table:(tbl)]
 3、使用指定目录bundle的指定的tb1的strings文件,如果tbl不存在返回key值
 #define NSLocalizedStringFromTableInBundle(key, tbl, bundle, comment) \
         [bundle localizedStringForKey:(key) value:@"" table:(tbl)]
 4、使用指定目录bundle的指定的tb1的strings文件，并默认一个value,如果tbl不存在返回key值
 #define NSLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) \
         [bundle localizedStringForKey:(key) value:(val) table:(tbl)]
 
 */
NSString *WBStringFormNetworkReachabilityStatus(WBNetworkReachabilityStatus status){
    switch (status) {
        case WBNetworkReachabilityStatusNotReachable:
            return NSLocalizedStringFromTable(@"Not Reachable", @"WBNetworking", nil);
            
        case WBNetworkReachabilityStatusReachableViaWWAN:
            return NSLocalizedStringFromTable(@"Reachable via WWAN", @"WBNetworking", nil);
            
        case WBNetworkReachabilityStatusReachableWiFi:
            return NSLocalizedStringFromTable(@"Reachable via WiFi", @"WBNetworking", nil);
            
        case WBNetworkReachabilityStatusUnknown:
        default:
            return NSLocalizedStringFromTable(@"Unknown", @"WBNetworking", nil);
    }
}

static WBNetworkReachabilityStatus WBNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags){
    /*
     typedef CF_OPTIONS(uint32_t, SCNetworkReachabilityFlags) {
         kSCNetworkReachabilityFlagsTransientConnection        = 1<<0,
         kSCNetworkReachabilityFlagsReachable            = 1<<1,
         kSCNetworkReachabilityFlagsConnectionRequired        = 1<<2,
         kSCNetworkReachabilityFlagsConnectionOnTraffic        = 1<<3,
         kSCNetworkReachabilityFlagsInterventionRequired        = 1<<4,
         kSCNetworkReachabilityFlagsConnectionOnDemand
             API_AVAILABLE(macos(6.0),ios(3.0))        = 1<<5,
         kSCNetworkReachabilityFlagsIsLocalAddress        = 1<<16,
         kSCNetworkReachabilityFlagsIsDirect            = 1<<17,
         kSCNetworkReachabilityFlagsIsWWAN
             API_UNAVAILABLE(macos) API_AVAILABLE(ios(2.0))    = 1<<18,

         kSCNetworkReachabilityFlagsConnectionAutomatic    = kSCNetworkReachabilityFlagsConnectionOnTraffic
     };
     */
    //& 按位与 只有都为1的时候才为1 如 011 & 010 = 010
    
    //flags == kSCNetworkFlagsReachable
    BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
    
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    
    //可以建立连接且（不需要手动连接并上可以自动连接）
    BOOL isNetworkReachable = (isReachable &&(!needsConnection || canConnectWithoutUserInteraction));
    WBNetworkReachabilityStatus status = WBNetworkReachabilityStatusUnknown;
    if (isNetworkReachable == NO) {
        status = WBNetworkReachabilityStatusNotReachable;
    }
    
#if TARGET_OS_IPHONE
    //流量
    else if((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0){
        status = WBNetworkReachabilityStatusReachableViaWWAN;
    }
#endif
    //Wi-Fi
    else{
        status = WBNetworkReachabilityStatusReachableWiFi;
    }
    return status;
    
}
@interface WBNetworkReachabilityManager()

@end

@implementation WBNetworkReachabilityManager


#endif

@end
