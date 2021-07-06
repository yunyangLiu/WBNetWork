//
//  WBSecurityPolicy.m
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/5.
//

#import "WBSecurityPolicy.h"

#import <AssertMacros.h>

/*
 *    +---------------------------------------------------------------------+
 *    |                            TARGET_OS_MAC                            |
 *    | +---+ +-----------------------------------------------+ +---------+ |
 *    | |   | |               TARGET_OS_IPHONE                | |         | |
 *    | |   | | +---------------+ +----+ +-------+ +--------+ | |         | |
 *    | |   | | |      IOS      | |    | |       | |        | | |         | |
 *    | |OSX| | |+-------------+| | TV | | WATCH | | BRIDGE | | |DRIVERKIT| |
 *    | |   | | || MACCATALYST || |    | |       | |        | | |         | |
 *    | |   | | |+-------------+| |    | |       | |        | | |         | |
 *    | |   | | +---------------+ +----+ +-------+ +--------+ | |         | |
 *    | +---+ +-----------------------------------------------+ +---------+ |
 *    +---------------------------------------------------------------------+
 *  TARGET_OS_*
 *  These conditionals specify in which Operating System the generated code will
 *  run.  Indention is used to show which conditionals are evolutionary subclasses.
 *  这些条件指定生成的代码将在哪个操作系统中运行。 缩进用于显示子类。
 *  The MAC/WIN32/UNIX conditionals are mutually exclusive. MAC/WIN32/UNIX 条件是互斥的。
 *  The IOS/TV/WATCH conditionals are mutually exclusive.   IOS/TV/WATCH 条件是互斥的。
 *      TARGET_OS_WIN32           - Generated code will run under 32-bit Windows 生成的代码将在 32 位 Windows 下运行
 *      TARGET_OS_UNIX            - Generated code will run under some Unix (not OSX) 生成的代码将在某些 Unix 下运行
 *      TARGET_OS_MAC             - Generated code will run under Mac OS X variant 生成的代码将在 Mac OS X 变体下运行
 *         TARGET_OS_OSX          - Generated code will run under OS X devices  生成的代码将在 OS X 设备下运行
 *         TARGET_OS_IPHONE          - Generated code for firmware, devices, or simulator 为固件、设备或模拟器生成的代码
 *            TARGET_OS_IOS             - Generated code will run under iOS  生成的代码会在iOS下运行
 *            TARGET_OS_TV              - Generated code will run under Apple TV OS 生成的代码将在 Apple TV OS 下运行
 *            TARGET_OS_WATCH           - Generated code will run under Apple Watch OS 生成的代码将在 Apple Watch OS 下运行
 *            TARGET_OS_BRIDGE          - Generated code will run under Bridge devices 生成的代码将在 Bridge 设备下运行
 *            TARGET_OS_MACCATALYST     - Generated code will run under macOS  生成的代码将在 macOS 下运行（所以可以生成在macOS上运行的手机app？？？）
 *         TARGET_OS_SIMULATOR      - Generated code will run under a simulator 生成的代码将在模拟器下运行
 *
 *      TARGET_OS_EMBEDDED        - DEPRECATED: Use TARGET_OS_IPHONE and/or TARGET_OS_SIMULATOR instead
 *      TARGET_IPHONE_SIMULATOR   - DEPRECATED: Same as TARGET_OS_SIMULATOR
 *      TARGET_OS_NANO            - DEPRECATED: Same as TARGET_OS_WATCH
 */
#if !TARGET_OS_IOS && !TARGET_OS_WATCH && !TARGET_OS_TV

/*
 —般情况下,C语言源程序中的每一行代码.都要参加编译。但有时候出于对程序代码优化的考虑.希望只对其中一部分内容进行编译.此时就需要在程序中加上条件，让编译器只对满足条件的代码进行编译，将不满足条件的代码舍弃，这就是条件编译（conditional compile）。
 */
//如果不在iOS且不在watch且不在tv上运行，则编译代码
//将 SecKeyRef key 转换为二进制 NSData
static NSData * WBSecKeyGetData(SecKeyRef key) {
    CFDataRef data = NULL;

    __Require_noErr_Quiet(SecItemExport(key, kSecFormatUnknown, kSecItemPemArmour, NULL, &data), _out);

    return (__bridge_transfer NSData *)data;

_out:
    if (data) {
        CFRelease(data);
    }

    return nil;
}
#endif

//判断两个key是否相等
static BOOL WBSecKeyIsEqualToKey(SecKeyRef key1, SecKeyRef key2) {
#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
    return [(__bridge id)key1 isEqual:(__bridge id)key2];
#else
    return [WBSecKeyGetData(key1) isEqual:WBSecKeyGetData(key2)];
#endif
}

//二进制证书转换为公钥
static id WBPublicKeyForCertificate(NSData *certificate) {
    id allowedPublicKey = nil; //允许的公钥
    SecCertificateRef allowedCertificate; //证书
    SecPolicyRef policy = nil; //策略对象
    SecTrustRef allowedTrust = nil; //信任的证书
    SecTrustResultType result;

    //根据certificate 创建 SecCertificateRef
    allowedCertificate = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificate);
    //__Require_Quiet  _out 是一个标记，如果条件不成立，即allowedCertificate == NULL，就会跳到我们打标记的地方，_out:的地方
    __Require_Quiet(allowedCertificate != NULL, _out);

    //获取一个策略对象
    policy = SecPolicyCreateBasicX509();
    
    //__Require_noErr_Quiet  如果发生异常，就跳转到标记的地方
    __Require_noErr_Quiet(SecTrustCreateWithCertificates(allowedCertificate, policy, &allowedTrust), _out);
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-相关命令"
////需要操作的代码
//#pragma clang diagnostic pop
#pragma clang diagnostic push
    //-Wdeprecated-declarations 方法启用警告
    //-Wincompatible-pointer-types 不兼容指针类型
    //-Warc-retain-cycles 循环引用
    //-Wunused-variable 未使用变量
    //-Wcovered-switch-default 未使用defalut
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __Require_noErr_Quiet(SecTrustEvaluate(allowedTrust, &result), _out);
#pragma clang diagnostic pop

    allowedPublicKey = (__bridge_transfer id)SecTrustCopyPublicKey(allowedTrust);

_out:
    //释放各个对象资源
    if (allowedTrust) {
        CFRelease(allowedTrust);
    }

    if (policy) {
        CFRelease(policy);
    }

    if (allowedCertificate) {
        CFRelease(allowedCertificate);
    }

    //return allowedPublicKey
    return allowedPublicKey;
}

//服务信任是否无效
static BOOL WBServerTrustIsValid(SecTrustRef serverTrust) {
    BOOL isValid = NO;
    SecTrustResultType result;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    __Require_noErr_Quiet(SecTrustEvaluate(serverTrust, &result), _out);
#pragma clang diagnostic pop

    isValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);

_out:
    return isValid;
}

//从serverTrust获取证书信任串数组
static NSArray * WBCertificateTrustChainForServerTrust(SecTrustRef serverTrust) {
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];

    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
        [trustChain addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
    }

    return [NSArray arrayWithArray:trustChain];
}

//从serverTrust 获取公钥
static NSArray * WBPublicKeyTrustChainForServerTrust(SecTrustRef serverTrust) {
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray *trustChain = [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
    for (CFIndex i = 0; i < certificateCount; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);

        SecCertificateRef someCertificates[] = {certificate};
        CFArrayRef certificates = CFArrayCreate(NULL, (const void **)someCertificates, 1, NULL);

        SecTrustRef trust;
        __Require_noErr_Quiet(SecTrustCreateWithCertificates(certificates, policy, &trust), _out);
        SecTrustResultType result;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        __Require_noErr_Quiet(SecTrustEvaluate(trust, &result), _out);
#pragma clang diagnostic pop
        [trustChain addObject:(__bridge_transfer id)SecTrustCopyPublicKey(trust)];

    _out:
        if (trust) {
            CFRelease(trust);
        }

        if (certificates) {
            CFRelease(certificates);
        }

        continue;
    }
    CFRelease(policy);

    return [NSArray arrayWithArray:trustChain];
    
}


@interface WBSecurityPolicy()
@property (readwrite, nonatomic, assign) WBSSLPinningMode SSLPinningMode; //SSL的链接模式
@property (readwrite, nonatomic, strong) NSSet *pinnedPublicKeys;//稳定的公钥集合
@end

@implementation WBSecurityPolicy

/// 从目录bundle 获取所有以.cer 结尾的证书，并将证书专为二进制数据，放在数组中返回
/// @param bundle  目录
+ (NSSet *)certificatesInBundle:(NSBundle *)bundle {
    NSArray *paths = [bundle pathsForResourcesOfType:@"cer" inDirectory:@"."];

    NSMutableSet *certificates = [NSMutableSet setWithCapacity:[paths count]];
    for (NSString *path in paths) {
        NSData *certificateData = [NSData dataWithContentsOfFile:path];
        [certificates addObject:certificateData];
    }

    return [NSSet setWithSet:certificates];
}

/// 获取一个默认的安全策略 securityPolicy
+ (instancetype)defaultPolicy{
    WBSecurityPolicy *securityPolicy = [[self alloc]init];
    securityPolicy.SSLPinningMode = WBSSLPinningModeNone;
    return securityPolicy;
}


/// 从默认目录获取证书数据，并根据策略模式创建一个安全策略
/// @param pinningMode 策略模式
+ (instancetype)policyWithPinningMode:(WBSSLPinningMode)pinningMode{
    
    NSSet <NSData *> *defaultPinnedCertificates = [self certificatesInBundle:[NSBundle mainBundle]];
    return [self policyWithPinningMode:pinningMode withPinnedCertificates:defaultPinnedCertificates];
}


/// 根据策略模式和证书数据创建一个安全策略
/// @param pinningMode 策略模式
/// @param pinnedCertificates 证书二进制数据
+ (instancetype)policyWithPinningMode:(WBSSLPinningMode)pinningMode withPinnedCertificates:(NSSet<NSData *> *)pinnedCertificates{
    
    WBSecurityPolicy *securityPolicy = [[self alloc]init];
    securityPolicy.SSLPinningMode = pinningMode;
    [securityPolicy setPinnedCertificates:pinnedCertificates];
    return securityPolicy;
}


/// 初始化init
- (instancetype)init{
    self = [super init];
    if (!self) {
        return  nil;
    }
    //默认需要验证证书中的域名
    self.validatesDomainName = YES;
    return self;
}


/// 设置证书数据，得到pinnedPublicKeys
/// @param pinnedCertificates 所有证书的二进制数据集合
- (void)setPinnedCertificates:(NSSet<NSData *> *)pinnedCertificates{
    
    _pinnedCertificates = pinnedCertificates;
    
    if (self.pinnedCertificates) {
        //setWithCapacity 会根据后边的count创建set，可以提高内存效率。注：指定为3，实际上也是可以大于3的。NSDictionary和NSArray也是一样
        NSMutableSet *mutablePinnedPublickeys = [NSMutableSet setWithCapacity:[self.pinnedCertificates count]];
        for (NSData *certificate in self.pinnedCertificates) {
            id publicKey = WBPublicKeyForCertificate(certificate);
            if (!publicKey) {
                continue;
            }
            [mutablePinnedPublickeys addObject:publicKey];
        }
        self.pinnedPublicKeys = [NSSet setWithSet:mutablePinnedPublickeys];
        
    }else{
        self.pinnedPublicKeys = nil;
    }
}

#pragma mark -
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(NSString *)domain{
    
    if (domain && self.allowInvalidCertificates && self.validatesDomainName && (self.SSLPinningMode == WBSSLPinningModeNone || self.pinnedCertificates.count == 0)) {
        //  According to the docs, you should only trust your provided certs for evaluation. 你必须对你信任的证书进行评估
        //  Pinned certificates are added to the trust. Without pinned certificates,there is nothing to evaluate against. 固定的证书已被添加到信任中，没有固定的证书，就不需要进行评估
        //  为了验证自签名证书的域名，您必须使用固定的证书。
        NSLog(@"In order to validate a domain name for self signed certificates, you MUST use pinning.");
        return NO;
    }
    
    NSMutableArray *policies = [NSMutableArray array];
    
    //需要验证域名时，添加一个域名验证策略
    if(self.validatesDomainName){
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
    }else{
        [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
    }
    
    //设置验证策略
    SecTrustSetPolicies(serverTrust, (__bridge  CFArrayRef)policies);
    
    //AFSSLPinningModeNone 时，allowInvalidCertificates为YES ，则代表服务器任何证书都能验证
    //如果是NO，则需要判断此服务器是否是系统信任证书
    if (self.SSLPinningMode == WBSSLPinningModeNone) {
        return self.allowInvalidCertificates || WBServerTrustIsValid(serverTrust);
    }
    //如果服务器证书不是系统信任证书，且不允许不信任证书通过验证则返回NO
    else if (!self.allowInvalidCertificates && !WBServerTrustIsValid(serverTrust)){
        return  NO;
    }
    
    switch (self.SSLPinningMode) {
        case WBSSLPinningModeCertificate:{
            // AFSSLPinningModeCertificate 是直接将本地证书设置为信任的根证书，然后来进行判断，并且比较本地证书内容和服务器证书内容是否一致，如果有一个相同则返回YES
            NSMutableArray *pinnedCertificates = [NSMutableArray array];
            for (NSData *certificateData in self.pinnedCertificates) {
                [pinnedCertificates addObject:(__bridge_transfer  id)SecCertificateCreateWithData(NULL, (__bridge  CFDataRef)certificateData)];
            }
            //设置本地证书为根证书
            SecTrustSetAnchorCertificates(serverTrust, (__bridge  CFArrayRef)pinnedCertificates);
            
            //通过本地证书来判断服务器证书是否可信，不可信则不通过
            if (!WBServerTrustIsValid(serverTrust)) {
                return NO;
            }
            
            //判断本地证书和服务器证书是否相同
            NSArray *serverCertificates = WBCertificateTrustChainForServerTrust(serverTrust);
            for (NSData *trustChainCertificate in [serverCertificates reverseObjectEnumerator]) {
                if ([self.pinnedCertificates containsObject:trustChainCertificate]) {
                    return YES;
                }
            }
            
        
        }
            return NO;

        case WBSSLPinningModePublicKey:{
            //是通过比较证书中公钥部分来进行校验。通过SecTrustCopyPublicKey方法获取本地证书和服务器证书，进行比较，如果有一个相同则验证通过
            NSInteger trustedPublicKeyCount = 0;
            NSArray *publicKeys = WBPublicKeyTrustChainForServerTrust(serverTrust);
            for (id trustChainPublicKey in publicKeys) {
                
                for (id pinnedPublicKey in self.pinnedPublicKeys) {
                    if (WBSecKeyIsEqualToKey((__bridge  SecKeyRef)trustChainPublicKey, (__bridge SecKeyRef)pinnedPublicKey)) {
                        trustedPublicKeyCount += 1;
                    }
                }
            }
            return trustedPublicKeyCount > 0;
            
            
        }
            return NO;
        default:
            return NO;
    }
    
    return NO;
}

#pragma mark - NSKeyValueObserving

//用kvo监听pinnedPublicKeys，当pinnedCertificates发生改变时，观察者也会收到通知。
+ (NSSet *)keyPathsForValuesAffectingPinnedPublicKeys{
    return [NSSet setWithObject:@"pinnedCertificates"];
}

#pragma mark - NSSecureCoding
//是否支持加密编码
+ (BOOL)supportsSecureCoding{
    return YES;
}

//二进制数据解密为对象
- (instancetype)initWithCoder:(NSCoder *)coder{
    
    self = [super init];
    if (!self) {
        return  nil;
    }
    self.SSLPinningMode = [[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(SSLPinningMode))] unsignedIntegerValue];
    self.allowInvalidCertificates = [coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(allowInvalidCertificates))];
    self.validatesDomainName = [coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(validatesDomainName))];
    self.pinnedCertificates = [coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(pinnedCertificates))];
    return self;
    
}

//对象加密成二进制数据
- (void)encodeWithCoder:(NSCoder *)coder{
    
    [coder encodeObject:[NSNumber numberWithInteger:self.SSLPinningMode] forKey:NSStringFromSelector(@selector(SSLPinningMode))];
    [coder encodeBool:self.allowInvalidCertificates forKey:NSStringFromSelector(@selector(allowInvalidCertificates))];
    [coder encodeBool:self.validatesDomainName forKey:NSStringFromSelector(@selector(validatesDomainName))];
    [coder encodeObject:self.pinnedCertificates forKey:NSStringFromSelector(@selector(pinnedCertificates))];
    
}

#pragma mark - NSCopying

// 确保copy方法的对象的属性和原属性保持一致
- (instancetype)copyWithZone:(NSZone *)zone{
    
    WBSecurityPolicy *securityPolicy = [[[self class] allocWithZone:zone]init];
    
    securityPolicy.SSLPinningMode = self.SSLPinningMode;
    securityPolicy.allowInvalidCertificates = self.allowInvalidCertificates;
    securityPolicy.validatesDomainName = self.validatesDomainName;
    securityPolicy.pinnedCertificates = [self.pinnedCertificates copyWithZone:zone];
    
    return securityPolicy;
}

@end
