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
#pragma mark - WBStreamingMultipartFormData
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

- (NSDictionary *)HTTPRequestHeaders{
    
    NSDictionary __block *value;
    
    //同步执行并行队列
    dispatch_sync(self.requestHeaderModificationQueue, ^{
        value = [NSDictionary dictionaryWithDictionary:self.mutableHTTPRequestHeaders];
    });
    return  value;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field{
    
    dispatch_barrier_sync(self.requestHeaderModificationQueue, ^{
        [self.mutableHTTPRequestHeaders setValue:value forKey:field];
        
    });
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field{
    
    NSString __block *value;
    dispatch_sync(self.requestHeaderModificationQueue, ^{
        
        value = [self.mutableHTTPRequestHeaders valueForKey:field];
    });
    return value;
}

- (void)setAuthorizationHeaderFieldWithUsername:(NSString *)username password:(NSString *)password{
    
    NSData *basicAuthCredentials = [[NSString stringWithFormat:@"%@:%@",username,password] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64AuthCredentials = [basicAuthCredentials base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
    [self setValue:[NSString stringWithFormat:@"Basic %@",base64AuthCredentials] forHTTPHeaderField:@"Authorization"];
    
    
}

- (void)clearAuthorizationHeader{
    dispatch_barrier_sync(self.requestHeaderModificationQueue, ^{
       
        [self.mutableHTTPRequestHeaders removeObjectForKey:@"Authorization"];
    });
}

#pragma mark -
- (void)setQueryStringSerializationStyle:(WBHTTPRequestQueryStringSerializationStyle)queryStringSerializationStyle{
    
    self.queryStringSerializationStyle = queryStringSerializationStyle;
    self.queryStringSerialization = nil;
    
}

- (void)setQueryStringSerializationWithBlock:(NSString * _Nullable (^)(NSURLRequest * _Nonnull, id _Nonnull, NSError *__autoreleasing  _Nullable * _Nullable))block{
    
    self.queryStringSerialization = block;
}

#pragma mark -
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(id)parameters
                                     error:(NSError * _Nullable __autoreleasing *)error{
    //断言评估一个条件，如果条件为 false ，调用当前线程的断点句柄。
    NSParameterAssert(method);
    NSParameterAssert(URLString);
    NSURL *url = [NSURL URLWithString:URLString];
    NSParameterAssert(url);
    NSMutableURLRequest *mutableRequest = [[NSMutableURLRequest alloc]initWithURL:url];
    mutableRequest.HTTPMethod = method;
    for (NSString *keyPath in self.mutableObservedChangedKeyPaths) {
        [mutableRequest setValue:[self valueForKey:keyPath] forKey:keyPath];
    }
    
    //mutableCopy 不管copy的对象是可变还是不可变，都会重新拷贝一份内存
    //copy 只有当为可变对象时，才会考呗内存，否则，则只会拷贝地址
    mutableRequest = [[self requestBySerializingRequest:mutableRequest withParameters:parameters error:error] mutableCopy];
    return  mutableRequest;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(NSDictionary<NSString *,id> *)parameters
                              constructingBodyWithBlock:(void (^)(id<WBMultipartFormData> _Nonnull))block
                                                  error:(NSError * _Nullable __autoreleasing *)error{
    NSParameterAssert(method);
    NSParameterAssert(![method isEqualToString:@"GET"] &&![method isEqualToString:@"HEAD"]);
    NSMutableURLRequest *mutableRequest = [self requestWithMethod:method URLString:URLString parameters:nil error:error];
    __block WBStreamingMultipartFormData *fromData = [[WBStreamingMultipartFormData alloc]initWithURLRequest:mutableRequest stringEncoding:NSUTF8StringEncoding];
    if (parameters) {
        for (WBQueryStringPair *pair in WBQueryStringPairsFromDictionary(parameters)) {
            
            NSData *data = nil;
            
            if ([pair.value isKindOfClass:[NSData class]]) {
                
                data = pair.value;
                
            }else if ([pair.value isEqual:[NSNull null]]){
                
                data = [NSData data];
            }
            else{
                
                data = [[pair.value description] dataUsingEncoding:self.stringEncoding];
            }
            if (data) {
                [fromData appendPartWithFormData:data name:[pair.field description]];
            }
        }
    }
    
    return  [fromData requestByFinalizingMultipartFormData];
    
    
}

- (NSMutableURLRequest *)requestWithMultipartFormRequest:(NSURLRequest *)request writingStreamContentsToFile:(NSURL *)fileURL completionHandler:(void (^)(NSError * _Nullable))handler{
    NSParameterAssert(request.HTTPBodyStream);
    NSParameterAssert([fileURL isFileURL]);
    NSInputStream *inputStream = request.HTTPBodyStream;
    NSOutputStream *outputStream = [[NSOutputStream alloc]initWithURL:fileURL append:NO];
    __block NSError *error = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [inputStream open];
        [outputStream open];
        while ([inputStream  hasBytesAvailable] && [outputStream hasSpaceAvailable]) {
            uint8_t bufffer[1024];
            
            NSInteger bytesRead = [inputStream read:bufffer maxLength:1024];
            if (inputStream.streamError || bytesRead < 0) {
                error = inputStream.streamError;
                break;
            }
            
            NSInteger bytesWritten = [outputStream write:bufffer maxLength:(NSInteger)bytesRead];
            if (outputStream.streamError || bytesWritten < 0) {
                error = outputStream.streamError;
                break;
            }
            if (bytesRead == 0 && bytesWritten == 0) {
                break;
            }
        }
        
        [outputStream close];
        [inputStream close];
        
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
               
                handler(error);
            });
        }
        
    });
    
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    mutableRequest.HTTPBodyStream = nil;
    
    return  mutableRequest;
}

#pragma mark - WBURLRequestSerialization
- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)parameters error:(NSError * _Nullable __autoreleasing *)error{
    
    
    NSParameterAssert(request);
    
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    
    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
       
        if (![request valueForHTTPHeaderField:key]) {
            [mutableRequest setValue:obj forHTTPHeaderField:key];
        }
    }];
    
    NSString *query = nil;
    if (parameters) {
        if (self.queryStringSerialization) {
            
            NSError *serializationError;
            query = self.queryStringSerialization(request,parameters,&serializationError);
            
            if (serializationError) {
                if (error) {
                    *error = serializationError;
                }
                return nil;
            }
        }else{
            
            switch (self.queryStringSerializationStyle) {
                case WBHTTPRequestQueryStringSerializationDefaultStyle:
                    query = WBQueryStringFromParameters(parameters);
                    break;
                    
                default:
                    break;
            }
        }
    }
    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        if (query && query.length > 0) {
            mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString]stringByAppendingFormat:mutableRequest.URL.query?@"&%@":@"?%@",query]];
        }
    }else{
        if (!query) {
            query = @"";
        }
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setHTTPBody:[query dataUsingEncoding:self.stringEncoding]];
        }
        
    }
    return mutableRequest;
}
#pragma mark - NSKeyValueObserving
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key{
    
    if ([WBHTTPRequestSerializerObservedKeyPaths() containsObject:key]) {
        
        return  NO;
    }
    
    return [super automaticallyNotifiesObserversForKey:key];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if (context == WBHTTPRequestSerializerObserverContext) {
        if ([change[NSKeyValueChangeNewKey] isEqual:[NSNull null]]) {
            [self.mutableObservedChangedKeyPaths removeObject:keyPath];
        }else{
            [self.mutableObservedChangedKeyPaths addObject:keyPath];
        }
    }
}


#pragma mark - NSSecureCoding
+(BOOL)supportsSecureCoding{
    return  YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [self init];
    if (!self) {
        return  nil;
    }
    
    self.mutableHTTPRequestHeaders = [[coder decodeObjectOfClass:[NSDictionary class] forKey:NSStringFromSelector(@selector(mutableHTTPRequestHeaders))] mutableCopy];
    self.queryStringSerializationStyle = (WBHTTPRequestQueryStringSerializationStyle)[[coder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(queryStringSerializationStyle))] unsignedIntegerValue];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder{
    
    dispatch_sync(self.requestHeaderModificationQueue, ^{
        [coder encodeObject:self.mutableHTTPRequestHeaders forKey:NSStringFromSelector(@selector(mutableHTTPRequestHeaders))];
    });
    
    [coder encodeObject:@(self.queryStringSerializationStyle) forKey:NSStringFromSelector(@selector(queryStringSerializationStyle))];
    
}

#pragma mark - NSCopying
- (instancetype)copyWithZone:(NSZone *)zone{
    
    WBHTTPRequestSerializer *serializer = [[[self class]allocWithZone:zone]init];
    
    dispatch_sync(self.requestHeaderModificationQueue, ^{
        serializer.mutableHTTPRequestHeaders = self.mutableHTTPRequestHeaders;
    });
    serializer.queryStringSerializationStyle = self.queryStringSerializationStyle;
    serializer.queryStringSerialization = self.queryStringSerialization;
    return serializer;
}


@end

#pragma mark -
static NSString *WBCreateMultipartFormBoundary(){
    
    return [NSString stringWithFormat:@"Boundary+%08X%08X",arc4random(),arc4random()];
}

static NSString * const kWBMultipartFormCRLF = @"\r\n";

static inline NSString * WBMultipartFormInitialBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"--%@%@", boundary, kWBMultipartFormCRLF];
}

static inline NSString * WBMultipartFormEncapsulationBoundary(NSString *boundary){
    
    return [NSString stringWithFormat:@"%@--%@%@",kWBMultipartFormCRLF,boundary,kWBMultipartFormCRLF];
}

static inline NSString * WBMultipartFormFinalBoundary(NSString *boundary){
    
    return [NSString stringWithFormat:@"%@--%@--%@",kWBMultipartFormCRLF,boundary,kWBMultipartFormCRLF];
}

static inline NSString *WBContentTypeForPathExtension(NSString *extension){
    
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge  CFStringRef)extension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge  CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        return @"application/octet-stream";
    }else{
        return contentType;
    }
    
}

NSUInteger const KWBUploadStream3GSuggestedPacketSize = 1024 * 16;
NSTimeInterval const kWBUploadStream3GSuggestedDelay = 0.2;

#pragma mark - WBHTTPBodyPart
 
@interface WBHTTPBodyPart : NSObject

@property (nonatomic, assign) NSStringEncoding stringEncoding;

@property (nonatomic, strong) NSDictionary *headers;

@property (nonatomic, copy) NSString *bounday;

@property (nonatomic, strong) id body;

@property (nonatomic, assign) unsigned long long bodyContentLength;

@property (nonatomic, strong) NSInputStream *inputStream;

@property (nonatomic, assign) BOOL hasInitialBounday;

@property (nonatomic, assign) BOOL hasFinalBounday;

@property (nonatomic, readonly, assign, getter=hasByTesAvailable) BOOL bytesAvailable;

@property (nonatomic, readonly, assign) unsigned long long cententLength;

- (NSInteger)read:(uint8_t *)buffer
        maxLength:(NSUInteger)length;

@end

#pragma mark - WBMultipartBodyStream
@interface WBMultipartBodyStream : NSInputStream<NSStreamDelegate>
@property (nonatomic, assign) NSUInteger numberOfBytesInPacket;
@property (nonatomic, assign) NSTimeInterval delay;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, assign, readonly) unsigned long long contentLength;
@property (nonatomic, assign, readonly, getter=isEmpty) BOOL empty;

- (instancetype)initWithStringEncoding:(NSStringEncoding)encoding;
- (void)setInitialAndFinalBoundaries;
- (void)appendHTTPBodyPart:(WBHTTPBodyPart *)bodyPart;


@end

#pragma mark - WBStreamingMultipartFormData

@interface WBStreamingMultipartFormData()

@property (readwrite, nonatomic, copy) NSMutableURLRequest *request;

@property (readwrite, nonatomic, assign) NSStringEncoding stringEncoding;

@property (readwrite, nonatomic, copy) NSString *boundray;

@property (readwrite, nonatomic, strong) WBMultipartBodyStream *bodyStream;


@end

@implementation WBStreamingMultipartFormData

- (instancetype)initWithURLRequest:(NSMutableURLRequest *)urlRequest stringEncoding:(NSStringEncoding)encoding{
    self = [super init];
    if (!self) {
        return  nil;
    }
    self.request = urlRequest;
    self.stringEncoding = encoding;
    self.boundray = WBCreateMultipartFormBoundary();
    self.bodyStream = [[WBMultipartBodyStream alloc]initWithStringEncoding:encoding];
    return self;
}

- (void)setRequest:(NSMutableURLRequest *)request{
    _request = [request mutableCopy];
    
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name error:(NSError * _Nullable __autoreleasing *)error{
    
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    NSString *fileName = [fileURL lastPathComponent];
    NSString *mimeType = WBContentTypeForPathExtension([fileURL pathExtension]);
    return [self appendPartWithFileURL:fileURL name:name fileName:fileName mimeType:mimeType error:error];
    
}

- (BOOL)appendPartWithFileURL:(NSURL *)fileURL name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType error:(NSError * _Nullable __autoreleasing *)error{
    
    NSParameterAssert(fileURL);
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    if (![fileURL isFileURL]) {
        //如果不是地址
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey:NSLocalizedStringFromTable(@"Expected URL to be a file URL", @"WBNetworking", nil)};
        if (error) {
            *error = [[NSError alloc]initWithDomain:WBURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        return NO;
    }
    
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:error];
    //如果地址信息不存在
    if (!fileAttributes) {
        return NO;
    }
    
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data;name=\"%@\";filename=\"%@\"",name,fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    WBHTTPBodyPart *bodyPart = [[WBHTTPBodyPart alloc]init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = mutableHeaders;
    bodyPart.bounday = self.boundray;
    bodyPart.body = fileURL;
    bodyPart.bodyContentLength = [fileAttributes[NSFileSize] unsignedLongLongValue];
    [self.bodyStream appendHTTPBodyPart:bodyPart];
    
    return YES;
    
}

- (void)appendPartWithInputStream:(NSInputStream *)inputStream name:(NSString *)name fileName:(NSString *)fileName length:(int64_t)length mimeType:(NSString *)mimeType{
    
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"from-data;name=\"%@\";filename=\"%@\"",name,fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    
    WBHTTPBodyPart *bodyPart = [[WBHTTPBodyPart alloc]init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = mutableHeaders;
    bodyPart.bounday = self.boundray;
    bodyPart.inputStream = inputStream;
    bodyPart.bodyContentLength = (unsigned long long) length;
    [self.bodyStream appendHTTPBodyPart:bodyPart];
    
}

- (void)appendPartWithFileData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType{
    
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data;name=\"%@\";filename=\"%@\"",name,fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    [self appendPartWithHeaders:mutableHeaders body:data];
}

- (void)appendPartWithFormData:(NSData *)data name:(NSString *)name{
    
    NSParameterAssert(name);
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data;name=\"%@\"",name] forKey:@"Content-Disposition"];
    [self appendPartWithHeaders:mutableHeaders body:data];
    
}

- (void)appendPartWithHeaders:(NSDictionary<NSString *,NSString *> *)headers body:(NSData *)body{
    
    NSParameterAssert(body);
    WBHTTPBodyPart *bodyPart = [[WBHTTPBodyPart alloc]init];
    bodyPart.stringEncoding = self.stringEncoding;
    bodyPart.headers = headers;
    bodyPart.bounday = self.boundray;
    bodyPart.bodyContentLength = [body length];
    bodyPart.body = body;
    [self.bodyStream appendHTTPBodyPart:bodyPart];
}

- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes delay:(NSTimeInterval)delay{
    
    self.bodyStream.numberOfBytesInPacket = numberOfBytes;
    self.bodyStream.delay = delay;
}

- (NSMutableURLRequest *)requestByFinalizingMultipartFormData{
    
    if ([self.bodyStream isEmpty]) {
        return  self.request;
    }
    
    [self.bodyStream setInitialAndFinalBoundaries];
    [self.request setHTTPBodyStream:self.bodyStream];
    
    [self.request setValue:[NSString stringWithFormat:@"multipart/form-data;boundary=%@",self.boundray ] forHTTPHeaderField:@"Content-Type"];
    [self.request setValue:[NSString stringWithFormat:@"%llu",[self.bodyStream contentLength]] forHTTPHeaderField:@"Content-Length"];
    return  self.request;
}


@end

@implementation WBURLRequestSeriailzation : NSObject




- (void)setQueryStringSerializationWithBlock:(nullable NSString * _Nullable (^)(NSURLRequest *request, id parameters, NSError * __autoreleasing *error))block{
    
    block([NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.jianshu.com/"]],@{@"name":@"1111"},nil);
    
    
}

@end
