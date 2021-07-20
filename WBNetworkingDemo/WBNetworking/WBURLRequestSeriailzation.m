//
//  WBURLRequestSeriailzation.m
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/8.
//

#import "WBURLRequestSeriailzation.h"

#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

NSString * const WBURLRequestSerializationErrorDomain = @"com.alamofire.error.serialization.request";
NSString * const WBNetworkingOperationFailingURLRequestErrorKey = @"com.alamofire.serialization.request.error.response";

//定义查询request的Block
typedef NSString * (^WBQueryStringSerializationBlock)(NSURLRequest *request, id parameters, NSError *__autoreleasing *error);

/*
 Returns a percent-escaped string following RFC 3986 for a query string key or value.
 RFC 3986 states that the following characters are "reserved" characters.
 - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
 - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="

 In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
 query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
 should be percent-escaped in the query string.
 
 为查询字符串键或值返回遵循 RFC 3986 的百分比转义字符串。
   RFC 3986 指出以下字符是“保留”字符。
   - 通用分隔符：“:”、“#”、“[”、“]”、“@”、“?”、“/”
   - 子分隔符："!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="

   在 RFC 3986 - 第 3.4 节中，它指出“？” 和“/”字符不应被转义以允许
   查询字符串以包含 URL。 因此，除了“？”和 ”/”之外的所有“保留”字符，
   应该在查询字符串中进行百分比转义。
 
 百分号编码又叫做URL编码，是一种编码机制，只要用于URI（包含URL和URN）编码中。
 百分号编码通俗解释：就是将保留字符转换成带百分号的转义字符
 */
NSString * WBPercentEscapedStringFromString(NSString *string) {
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";

    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];

    // FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];

    static NSUInteger const batchSize = 50;

    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;

    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);

        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];

        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];

        index += range.length;
    }

    return escaped;
}
#pragma mark -

@interface WBQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;
@end

@implementation WBQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.field = field;
    self.value = value;

    return self;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return WBPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", WBPercentEscapedStringFromString([self.field description]), WBPercentEscapedStringFromString([self.value description])];
    }
}

@end
FOUNDATION_EXPORT NSArray * WBQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray * WBQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * AFQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (WBQueryStringPair *pair in WBQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }

    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * WBQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return WBQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * WBQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:WBQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:WBQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:WBQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[WBQueryStringPair alloc] initWithField:key value:value]];
    }

    return mutableQueryStringComponents;
}
#pragma mark -
@interface WBStreamingMultipartFormData : NSObject<WBMultipartFormData>

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest
                    stringEncoding:(NSStringEncoding)encoding;

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData;

@end

#pragma mark -
static NSArray *WBHTTPRequestSerializerObservedKeyPaths(){
    static NSArray *_WBHTTPRequestSerializerObservedKeyPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _WBHTTPRequestSerializerObservedKeyPaths = @[NSStringFromSelector(@selector(allowsCellularAccess)),NSStringFromSelector(@selector(cachePolicy)),NSStringFromSelector(@selector(HTTPShouldHandleCookies)),NSStringFromSelector(@selector(HTTPShouldUsePipelining)),NSStringFromSelector(@selector(networkServiceType)),NSStringFromSelector(@selector(timeoutInterval))];
    });
    
    return _WBHTTPRequestSerializerObservedKeyPaths;
    
}

static void *WBHTTPRequestSerializerObserverContext = &WBHTTPRequestSerializerObserverContext;

@interface WBHTTPRequestSerializer()

@property (readwrite, nonatomic, strong) NSMutableSet *mutableObservedChangedKeyPaths;

@property (readwrite, nonatomic, strong) NSMutableDictionary *mutableHTTPRequestHeaders;

@property (readwrite, nonatomic, strong) dispatch_queue_t requestHeaderModificationQueue;

@property (readwrite, nonatomic, assign) WBHTTPRequestQueryStringSerializationStyle queryStringSerializationStyle;

@property (readwrite, nonatomic, copy) WBQueryStringSerializationBlock queryStringSerialization;

@end

@implementation WBHTTPRequestSerializer

+ (instancetype)serializer{
    
    return [[self alloc]init];
}

- (instancetype)init{
    
    self = [super init];
    if (!self) {
        return  nil;
    }
    
    self.stringEncoding = NSUTF8StringEncoding;
    self.mutableHTTPRequestHeaders = [NSMutableDictionary dictionary];
    self.requestHeaderModificationQueue = dispatch_queue_create("rquestHeaderModificationQueue", DISPATCH_QUEUE_CONCURRENT);
    NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
    [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        float q = 1.0f - (idx * 0.1f);
        [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g",obj,q]];
        *stop = q <= 0.5f;
        
    }];
    [self setValue:[acceptLanguagesComponents componentsJoinedByString:@", "] forHTTPHeaderField:@"Accept-Language"];
    
    NSString *userAgent = nil;
    
#if TARGET_OS_IOS
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif TARGET_OS_TV
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; tvOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];
#elif TARGET_OS_WATCH
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; watchOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[WKInterfaceDevice currentDevice] model], [[WKInterfaceDevice currentDevice] systemVersion], [[WKInterfaceDevice currentDevice] screenScale]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
    userAgent = [NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]];
#endif
    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            if (CFStringTransform((__bridge  CFMutableStringRef)(mutableUserAgent), NULL, (__bridge  CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                userAgent = mutableUserAgent;
            }
        }
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    self.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"",@"",@"", nil];
    self.mutableObservedChangedKeyPaths = [NSMutableSet set];
    
    for (NSString *keyPath in WBHTTPRequestSerializerObservedKeyPaths()) {
        if ([self respondsToSelector:@selector(keyPath)]) {
            [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:WBHTTPRequestSerializerObserverContext];
        }
    }
    return  self;
}

- (void)dealloc{
    for (NSString *keyPath in WBHTTPRequestSerializerObservedKeyPaths()) {
        if ([self respondsToSelector:NSSelectorFromString(keyPath)]) {
            [self removeObserver:self forKeyPath:keyPath context:WBHTTPRequestSerializerObserverContext];
        }
    }
}

#pragma mark -
// 注意：如果手动调用了kvo，则必须实现 automaticallyNotifiesObserversForKey 方法，不然会产生crash
//一般不会手动去调用willChangeValueForKey、didChangeValueForKey 所以automaticallyNotifiesObserversForKey也不必实现
- (void)setAllowsCellularAccess:(BOOL)allowsCellularAccess {
    [self willChangeValueForKey:NSStringFromSelector(@selector(allowsCellularAccess))];
    _allowsCellularAccess = allowsCellularAccess;
    [self didChangeValueForKey:NSStringFromSelector(@selector(allowsCellularAccess))];
}

- (void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    [self willChangeValueForKey:NSStringFromSelector(@selector(cachePolicy))];
    _cachePolicy = cachePolicy;
    [self didChangeValueForKey:NSStringFromSelector(@selector(cachePolicy))];
}

- (void)setHTTPShouldHandleCookies:(BOOL)HTTPShouldHandleCookies {
    [self willChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldHandleCookies))];
    _HTTPShouldHandleCookies = HTTPShouldHandleCookies;
    [self didChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldHandleCookies))];
}

- (void)setHTTPShouldUsePipelining:(BOOL)HTTPShouldUsePipelining {
    [self willChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldUsePipelining))];
    _HTTPShouldUsePipelining = HTTPShouldUsePipelining;
    [self didChangeValueForKey:NSStringFromSelector(@selector(HTTPShouldUsePipelining))];
}

- (void)setNetworkServiceType:(NSURLRequestNetworkServiceType)networkServiceType {
    [self willChangeValueForKey:NSStringFromSelector(@selector(networkServiceType))];
    _networkServiceType = networkServiceType;
    [self didChangeValueForKey:NSStringFromSelector(@selector(networkServiceType))];
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    [self willChangeValueForKey:NSStringFromSelector(@selector(timeoutInterval))];
    _timeoutInterval = timeoutInterval;
    [self didChangeValueForKey:NSStringFromSelector(@selector(timeoutInterval))];
}


#pragma mark -

@end

@implementation WBURLRequestSeriailzation : NSObject




- (void)setQueryStringSerializationWithBlock:(nullable NSString * _Nullable (^)(NSURLRequest *request, id parameters, NSError * __autoreleasing *error))block{
    
    block([NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.jianshu.com/"]],@{@"name":@"1111"},nil);
    
    
}

@end
