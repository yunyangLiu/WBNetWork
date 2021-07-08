//
//  WBNetworkReachabilityManager.m
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/6.
//

#import "WBNetworkReachabilityManager.h"

//只有在不是watchos的条件下进行编译
#if !TARGET_OS_WATCH

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>


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

/**
 * Queue a status change notification for the main thread.
 *
 * This is done to ensure that the notifications are received in the same order
 * as they are sent. If notifications are sent directly, it is possible that
 * a queued notification (for an earlier status condition) is processed after
 * the later update, resulting in the listener being left in the wrong state.
 
 * 这样做是为了确保接收通知的顺序与发送通知的顺序相同。 如果直接发送通知，则可能会在稍后更新后处理排队的通知（针对较早的状态条件），从而导致侦听器处于错误状态。
 */
static void WBPostReachablilityStatusChange(SCNetworkReachabilityFlags flags, WBNetworkReachabilityStatusCallback block){
    
    WBNetworkReachabilityStatus status = WBNetworkReachabilityStatusForFlags(flags);
    dispatch_async(dispatch_get_main_queue(), ^{
       
        WBNetworkReachabilityManager *manager = nil;
        if (block) {
            manager = block(status);
        }
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        NSDictionary *userInfo = @{WBNetworkingReachabilityNotificationStatusItem : @(status)};
        [notificationCenter postNotificationName:WBNetworkingReachabilityDidChangeNotification object:manager userInfo:userInfo];
        
    });
    
}

static void WBNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info){
    
    WBPostReachablilityStatusChange(flags, (__bridge WBNetworkReachabilityStatusCallback)info);
    
}

static const void *WBNetworkReachabilityRetainCallback(const void *info){
    return Block_copy(info);
}

static void WBNetworkReachabilityReleaseCallback(const void *info){
    if (info) {
        Block_release(info);
    }
}
@interface WBNetworkReachabilityManager()

@property (nonatomic, readonly, assign) SCNetworkReachabilityRef networkReachability;
@property (nonatomic, readwrite, assign) WBNetworkReachabilityStatus networkReachabilityStatus;
@property (nonatomic, readwrite, copy) WBNetworkReachabilityStatusBlock networkReachabilityStatusBlock;
@end

@implementation WBNetworkReachabilityManager


+ (instancetype)shareManager{
    static WBNetworkReachabilityManager *_shareManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       _shareManager = [self manager];
    });
    return  _shareManager;
}

+ (instancetype)managerForDomain:(NSString *)domain{
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [domain UTF8String]);
    WBNetworkReachabilityManager *manager = [[self alloc]initWithReachability:reachability];
    
    CFRelease(reachability);
    
    return manager;
}

+ (instancetype)managerForAddress:(const void *)address{
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);
    
    WBNetworkReachabilityManager *manager = [[self alloc]initWithReachability:reachability];
    
    CFRelease(reachability);
    
    return manager;
}

+ (instancetype)manager{

#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_family = AF_INET6;
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_family = AF_INET;
#endif
    return [self managerForAddress:&address];
    
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability{
    
    self = [super init];
    if (!self) {
        return  nil;
    }
    _networkReachability = CFRetain(reachability);
    self.networkReachabilityStatus = WBNetworkReachabilityStatusUnknown;
    
    return self;
}

- (instancetype)init{
    
    @throw [NSException exceptionWithName:NSGenericException reason:@"`-init` unavailable. Use `-initWithReachability:` instead" userInfo:nil];
}

- (void)dealloc{
    
    [self stopMonitoring];
    if (_networkReachability != NULL) {
        CFRelease(_networkReachability);
    }
}

#pragma mark -
- (BOOL)isReachable{
    return [self isReachableWiFi] || [self isReachableViaWWAN];
}

- (BOOL)isReachableViaWWAN{
    return self.networkReachabilityStatus == WBNetworkReachabilityStatusReachableViaWWAN;
}

- (BOOL)isReachableWiFi{
    return self.networkReachabilityStatus == WBNetworkReachabilityStatusReachableWiFi;
}

#pragma mark -
- (void)startMonitoring{
    [self stopMonitoring];
    
    if (!self.networkReachability) {
        return;
    }
    
    __weak __typeof(self) weakSelf = self;
    WBNetworkReachabilityStatusCallback callback = ^(WBNetworkReachabilityStatus status){


        __strong __typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }
        
        return strongSelf;

    };
    
    SCNetworkReachabilityContext context = {0,(__bridge  void *)callback,WBNetworkReachabilityRetainCallback,WBNetworkReachabilityReleaseCallback,NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, WBNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(self.networkReachability, &flags)) {
            WBPostReachablilityStatusChange(flags, callback);
        }
    });
}

- (void)stopMonitoring{
    
    if (!self.networkReachability) {
        return;
    }
    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

#pragma mark -
- (NSString *)localizedNetworkReachabilityStatusString{
    return WBStringFormNetworkReachabilityStatus(self.networkReachabilityStatus);
}

#pragma mark -

- (void)setReeachabilityStatusChangeBlock:(void (^)(WBNetworkReachabilityStatus))block{
    self.networkReachabilityStatusBlock = block;
}

#pragma mark - NSKeyValueObserving
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key{
    
    if ([key isEqualToString:@"reachable"] ||[key isEqualToString:@"reachableViaWWAN"] || [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"networkReachabilityStatus"];
    }
    return [super keyPathsForValuesAffectingValueForKey:key];
}
@end

#endif
