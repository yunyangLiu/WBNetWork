//
//  WBNetworkReachabilityManager.h
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/6.
//

#import <Foundation/Foundation.h>
//只有在不是watchos的条件下进行编译
#if !TARGET_OS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>

//定义网络状态的枚举
typedef NS_ENUM(NSInteger, WBNetworkReachabilityStatus) {
    WBNetworkReachabilityStatusUnknown          = -1, //不明的状态
    WBNetworkReachabilityStatusNotReachable     = 0,  //网络连接不可用
    WBNetworkReachabilityStatusReachableViaWWAN = 1,  //移动网络
    WBNetworkReachabilityStatusReachableWiFi    = 2,  //Wi-Fi
};


NS_ASSUME_NONNULL_BEGIN
/**
 `AFNetworkReachabilityManager` monitors the reachability of domains, and addresses for both WWAN and WiFi network interfaces.
 AFNetworkReachabilityManager 用来监控WWAN和WiFi 网络接口的域名的可用性

 Reachability can be used to determine background information about why a network operation failed, or to trigger a network operation retrying when a connection is established. It should not be used to prevent a user from initiating a network request, as it's possible that an initial request may be required to establish reachability.
 Reachability 可以用来决定网络链接失败的原因，或者当一个链接时触发网络链接重试。它不应该用于阻止用户发起网络请求，因为可能需要初始请求来建立可达性。
 See Apple's Reachability Sample Code ( https://developer.apple.com/library/ios/samplecode/reachability/ )

 @warning Instances of `AFNetworkReachabilityManager` must be started with `-startMonitoring` before reachability status can be determined.
 //AFNetworkReachabilityManager` 的实例必须使用 `-startMonitoring` 启动，然后才能确定可达性状态。
 */
@interface WBNetworkReachabilityManager : NSObject

/**
 The current network reachability status.
 当前网络的连接状态
 */
@property (nonatomic, readonly, assign) WBNetworkReachabilityStatus networkReachabilityStatus;

/**
 Whether or not the network is currently reachable.
  网络当前是否可用
 */
@property (nonatomic, readonly, assign, getter = isReachable) BOOL reachable;

/**
 Whether or not the network is currently reachable via WWAN.
  当前WWAN网络是否可用
 */
@property (nonatomic, readonly, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

/**
 Whether or not the network is currently reachable via WiFi.
 当前Wi-Fi网络是否可用
 */
@property (nonatomic, readonly, assign, getter = isReachableWiFi) BOOL reachableWiFi;


///---------------------
/// @name Initialization
///---------------------

/**
 Returns the shared network reachability manager.
  返回 WBNetworkReachabilityManager 的单例
 */
+ (instancetype)shareManager;

/**
 Creates and returns a network reachability manager with the default socket address.
  创建一个WBNetworkReachabilityManager，通过默认的socket 地址
 @return An initialized network reachability manager, actively monitoring the default socket address.
 */
+ (instancetype)manager;

/**
 Creates and returns a network reachability manager for the specified domain.
 
 创建一个WBNetworkReachabilityManager，通过指定的域名

 @param domain The domain used to evaluate network reachability. 域名用来验证网络的可用性

 @return An initialized network reachability manager, actively monitoring the specified domain. 返回一个初始化WBNetworkReachabilityManager，通过指定的域名
 */
+ (instancetype)managerForDomain:(NSString *)domain;

/**
 Creates and returns a network reachability manager for the socket address.

 @param address The socket address (`sockaddr_in6`) used to evaluate network reachability.

 @return An initialized network reachability manager, actively monitoring the specified socket address.
 */
+ (instancetype)managerForAddress:(const void *)address;

/**
 Initializes an instance of a network reachability manager from the specified reachability object.
 初始化一个WBNetworkReachabilityManager对象根据reachability对象
 
 NS_DESIGNATED_INITIALIZER 表示指定此方法为初始化方法

 @param reachability The reachability object to monitor.

 @return An initialized network reachability manager, actively monitoring the specified reachability.
 */
- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability NS_DESIGNATED_INITIALIZER;

/**
 *  Unavailable initializer
 *  NS_UNAVAILABLE 表示此初始化方法不可用，调用时会编译错误，但运行时可以调用。
 *  类似写法还有，效果相同。
 *  - (instancetype)init __attribute__((unavailable));
 *  - (instancetype)init __attribute__((unavailable("请使用initWithName:")));
 */
+ (instancetype)new NS_UNAVAILABLE;

/**
 *  Unavailable initializer
 *  NS_UNAVAILABLE 表示此初始化方法不可用
 */
- (instancetype)init NS_UNAVAILABLE;

///--------------------------------------------------
/// @name Starting & Stopping Reachability Monitoring
///--------------------------------------------------

/**
 Starts monitoring for changes in network reachability status.
 开始监控网络状态
 */
- (void)startMonitoring;
/**
 Stops monitoring for changes in network reachability status.
 停止监控网络状态
 */
- (void)stopMonitoring;

/**
 Returns a localized string representation of the current network reachability status.
 根据状态返回对应的字符串
 */
- (NSString *)localizedNetworkReachabilityStatusString;
/**
 Sets a callback to be executed when the network availability of the `baseURL` host changes.
 设置一个block回调，当baseURL的地址发生改变的时候调用

 @param block A block object to be executed when the network availability of the `baseURL` host changes.. This block has no return value and takes a single argument which represents the various reachability states from the device to the `baseURL`.
 */
- (void)setReeachabilityStatusChangeBlock:(nullable void(^)(WBNetworkReachabilityStatus status))block;

@end

/**
 Posted when network reachability changes.
 This notification assigns no notification object. The `userInfo` dictionary contains an `NSNumber` object under the `AFNetworkingReachabilityNotificationStatusItem` key, representing the `AFNetworkReachabilityStatus` value for the current network reachability.
 当发送通知的时候使用，WBNetworkingReachabilityNotificationStatusItem用作notification中userInfo的key，value为当前网络的状态。
 notification的name为WBNetworkingReachabilityDidChangeNotification

 @warning In order for network reachability to be monitored, include the `SystemConfiguration` framework in the active target's "Link Binary With Library" build phase, and add `#import <SystemConfiguration/SystemConfiguration.h>` to the header prefix of the project (`Prefix.pch`).
 为了监听网络的状态，需要添导入头文件#import <SystemConfiguration/SystemConfiguration.h>
 */

/*
 FOUNDATION_EXPORT和#define都可以用来定义常量
 FOUNDATION_EXPORT 在.h中声明，在.m中实现
 
 使用FOUNDATION_EXPORT方法在检测字符串的值是否相等时的效率更高
 
 第一种可以使用==直接来比较。第二种需要使用isEqualToString

 第一种是直接比较指针地址。第二种是一一比较字符串的每一个字符是否相等
 */
FOUNDATION_EXPORT NSString * const WBNetworkingReachabilityDidChangeNotification;
FOUNDATION_EXPORT NSString * const WBNetworkingReachabilityNotificationStatusItem;


/**
 Returns a localized string representation of an `AFNetworkReachabilityStatus` value.
 返回一个AFNetworkReachabilityStatus字符串
 */
FOUNDATION_EXPORT NSString * WBStringFromNetworkReachabilityStatus(WBNetworkReachabilityStatus status);

NS_ASSUME_NONNULL_END

#endif
