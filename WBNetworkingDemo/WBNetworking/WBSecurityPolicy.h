//
//  WBSecurityPolicy.h
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//SSLPinningMode SSL的链接模式 pinning固定的
typedef NS_ENUM(NSInteger,WBSSLPinningMode) {
    WBSSLPinningModeNone, //无
    WBSSLPinningModePublicKey,//公共的key
    WBSSLPinningModeCertificate,//证书
};

/*
 
 `WBSecurityPolicy` evaluates server trust against pinned X.509 certificates and public keys over secure connections.

 Adding pinned SSL certificates to your app helps prevent man-in-the-middle attacks and other vulnerabilities. Applications dealing with sensitive customer data or financial information are strongly encouraged to route all communication over an HTTPS connection with SSL pinning configured and enabled.
 
 Security Policy 安全 策略
 
 WBSecurityPolicy通过固定的 X.509 的证书和建立在安全连接上的公共的key 来评估服务器是否可以信任
 
 添加固定的 SSL 证书可以帮助app 远离中间人或者其他的漏洞攻击
 
 强烈建议处理敏感客户数据或财务信息的应用程序通过配置和启用 SSL 固定的 HTTPS 连接路由所有通信。
 
 */

/*
 
 如果想把自定义的对象持久化（存到硬盘），或者用于网络传输。需要先将自定义对象序列化成NSData

 如果自定义对象要想转成NSData，需要服从NSCoding协议。并实现其中的两个方法。
 
 - (void)encodeWithCoder:(nonnull NSCoder *)aCoder
 
 - (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder
 
 
 NSSecureCoding 是基于 NSCoding的协议的，要多实现一个方法。
 
 + (BOOL)supportsSecureCoding
 
 NSSecureCoding和NSCoding是一样的，除了在解码时要同时指定key和要解码的对象的类，如果要求的类和从文件中解码出的对象的类不匹配，NSCoder会抛出异常，告诉你数据已经被篡改了。
 
 
 */


@interface WBSecurityPolicy : NSObject<NSSecureCoding,NSCopying>

/**
 The criteria by which server trust should be evaluated against the pinned SSL certificates. Defaults to `AFSSLPinningModeNone`.
 
 根据 固定的SSL证书判断服务信任的标准，默认WBSSLPinningModeNone
 */
@property (readonly, nonatomic, assign) WBSSLPinningMode SSLPinningMode;

/**
 The certificates used to evaluate server trust according to the SSL pinning mode.
 
 Note that if pinning is enabled, `evaluateServerTrust:forDomain:` will return true if any pinned certificate matches.

 @see policyWithPinningMode:withPinnedCertificates:
 
 pinnedCertificates 通过 SSL pinning mode. 来判断 server 是否可以信任
 */

@property (nonatomic, strong, nullable) NSSet <NSData *> *pinnedCertificates;

/**
 Whether or not to trust servers with an invalid or expired SSL certificates. Defaults to `NO`.
 是否信任过期或者无效的证书，默认为NO
 */
@property (nonatomic, assign) BOOL allowInvalidCertificates;

/**
 Whether or not to validate the domain name in the certificate's CN field. Defaults to `YES`.
 
 是否验证证书的中的域名。 默认为“是”。
 */
@property (nonatomic, assign) BOOL validatesDomainName;

/**
 Returns any certificates included in the bundle. If you are using AFNetworking as an embedded framework, you must use this method to find the certificates you have included in your app bundle, and use them when creating your security policy by calling `policyWithPinningMode:withPinnedCertificates`.

 获取bundle中的所有certificate
 @return The certificates included in the given bundle.
 */
+ (NSSet <NSData *> *)certificatesInBundle:(NSBundle *)bundle;


/**
 Returns the shared default security policy, which does not allow invalid certificates, validates domain name, and does not validate against pinned certificates or public keys.
 返回一个默认的policy 不允许无效的certificates，验证domain name 不允许无效的固定证书和公共keys

 @return The default security policy.
 */
+ (instancetype)defaultPolicy;


/**
 Creates and returns a security policy with the specified pinning mode.
 
 创建一个security policy 用 pinningMode字段
 
 Certificates with the `.cer` extension found in the main bundle will be pinned. If you want more control over which certificates are pinned, please use `policyWithPinningMode:withPinnedCertificates:` instead.
 
 在main bundle的以.cer结尾的文件必须是固定的，如果想自定义建议用policyWithPinningMode:withPinnedCertificates:方法

 @param pinningMode The SSL pinning mode.

 @return A new security policy.

 @see -policyWithPinningMode:withPinnedCertificates:
 */
+ (instancetype)policyWithPinningMode:(WBSSLPinningMode)pinningMode;

/**
 Creates and returns a security policy with the specified pinning mode.

 创建一个security policy 用 pinningMode字段和证书集合pinnedCertificates
 
 @param pinningMode The SSL pinning mode.
 @param pinnedCertificates The certificates to pin against.

 @return A new security policy.

 @see +certificatesInBundle:
 @see -pinnedCertificates
*/
+ (instancetype)policyWithPinningMode:(WBSSLPinningMode)pinningMode withPinnedCertificates:(NSSet <NSData *> *)pinnedCertificates;


///------------------------------
/// @name Evaluating Server Trust
///------------------------------

/**
 Whether or not the specified server trust should be accepted, based on the security policy.
 
 根据安全策略，判断证书是否是信任的

 This method should be used when responding to an authentication challenge from a server.

 @param serverTrust The X.509 certificate trust of the server.
 @param domain The domain of serverTrust. If `nil`, the domain will not be validated.

 @return Whether or not to trust the server.
 */
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust
                  forDomain:(nullable NSString *)domain;



@end

NS_ASSUME_NONNULL_END
