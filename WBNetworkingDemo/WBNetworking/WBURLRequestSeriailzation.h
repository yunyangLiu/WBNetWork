//
//  WBURLRequestSeriailzation.h
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/8.
//

#import <Foundation/Foundation.h>

#import <TargetConditionals.h>

#if TARGET_OS_IOS || TARGET_OS_TV
#import <UIKit/UIKit.h>
#elif TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif


NS_ASSUME_NONNULL_BEGIN

/**
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
 
 
 @param string The string to be percent-escaped.
 
 @return The percent-escaped string.
 */

FOUNDATION_EXPORT NSString *WBPercentEscapedStringFromString(NSString *string);

/**
 A helper method to generate encoded url query parameters for appending to the end of a URL.

 将查询参数生成url拼接到URL的尾部
 @param parameters A dictionary of key/values to be encoded.

 @return A url encoded query string
 */

FOUNDATION_EXPORT NSString *WBQueryStringFromParameters(NSDictionary *parameters);

@protocol WBURLRequestSerialization <NSObject, NSSecureCoding, NSCopying>
/**
 The `AFURLRequestSerialization` protocol is adopted by an object that encodes parameters for a specified HTTP requests. Request serializers may encode parameters as query strings, HTTP bodies, setting the appropriate HTTP header fields as necessary.

 For example, a JSON request serializer may set the HTTP body of the request to a JSON representation, and set the `Content-Type` HTTP header field value to `application/json`.
 
 `AFURLRequestSerialization` 协议被一个对象采用，该对象为指定的 HTTP 请求编码参数。 请求序列化程序可以将参数编码为查询字符串、HTTP 正文，并根据需要设置适当的 HTTP 标头字段。

 例如，JSON 请求序列化程序可以将请求的 HTTP 主体设置为 JSON 表示，并将 `Content-Type` HTTP 标头字段值设置为 `application/json`。
 */
/**
 __nullable 和__nonnull。从字面上我们可知， __nullable 表示对象可以是 NULL 或 nil，而 __nonnull 表示对象不应该为空。当我们不遵循这一规则时，编译器就会给出警告。在 Xcode 7 中，为了避免与第三方库潜在的冲突，苹果把 __nonnull/__nullable改成 _Nonnull/_Nullable。再加上苹果同样支持了没有下划线的写法 nonnull/nullable ，于是就造成现在有三种写法这样混乱的局面。
 */
/**
 NS_SWIFT_NOTHROW 不抛出swift的错误，可能用于swift调用此代码的报错。
 */

- (nullable NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                                        withParameters:(nullable id)parameters
                                                 error:(NSError * _Nullable __autoreleasing *)error NS_SWIFT_NOTHROW;



@end

typedef NS_ENUM(NSInteger, WBHTTPRequestQueryStringSerializationStyle) {
    
    WBHTTPRequestQueryStringSerializationDefaultStyle = 0,
};

// 声明一个协议
@protocol WBMultipartFormData;//WBMultipartFormData


@interface WBHTTPRequestSerializer :NSObject<WBURLRequestSerialization>

/**
 The string encoding used to serialize parameters. `NSUTF8StringEncoding` by default. 编码参数，默认为UTF-8
 */
@property (nonatomic, assign) NSStringEncoding stringEncoding;

/**
 Whether created requests can use the device’s cellular radio (if present). `YES` by default.
 是否可以用蜂窝数据
 @see NSMutableURLRequest -setAllowsCellularAccess:
 */
@property (nonatomic, assign) BOOL allowsCellularAccess;

/**
 typedef NS_ENUM(NSUInteger, NSURLRequestCachePolicy)
 {
     NSURLRequestUseProtocolCachePolicy = 0, //默认的缓存策略， 如果缓存不存在，直接从服务端获取。如果缓存存在，会根据response中的Cache-Control字段判断下一步操作，如: Cache-Control字段为must-revalidata, 则询问服务端该数据是否有更新，无更新的话直接返回给用户缓存数据，若已更新，则请求服务端.

     NSURLRequestReloadIgnoringLocalCacheData = 1, //忽略本地缓存数据，直接请求服务端.
     NSURLRequestReloadIgnoringLocalAndRemoteCacheData = 4,  //忽略本地缓存，代理服务器以及其他中介，直接请求源服务端.
     NSURLRequestReloadIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData,

     NSURLRequestReturnCacheDataElseLoad = 2, //有缓存就使用，不管其有效性(即忽略Cache-Control字段), 无则请求服务端.
     NSURLRequestReturnCacheDataDontLoad = 3, //死活加载本地缓存. 没有就失败. (确定当前无网络时使用)

     NSURLRequestReloadRevalidatingCacheData = 5, // 如果原始源可以验证缓存数据，请使用缓存数据; 否则，从原点加载。
 };
 
 */
/**
 The cache policy of created requests. `NSURLRequestUseProtocolCachePolicy` by default.
  缓存策略，默认为NSURLRequestUseProtocolCachePolicy
 @see NSMutableURLRequest -setCachePolicy:
 */
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;

/**
 Whether created requests should use the default cookie handling. `YES` by default.
 是否使用默认的cookie进行网络请求
 @see NSMutableURLRequest -setHTTPShouldHandleCookies:
 */
@property (nonatomic, assign) BOOL HTTPShouldHandleCookies;


/**
 Whether created requests can continue transmitting data before receiving a response from an earlier transmission. `NO` by default
  创建的请求是否可以从之前传输的请求数据继续接收

 @see NSMutableURLRequest -setHTTPShouldUsePipelining:
 */
@property (nonatomic, assign) BOOL HTTPShouldUsePipelining;

/**
 The network service type for created requests. `NSURLNetworkServiceTypeDefault` by default.

 @see NSMutableURLRequest -setNetworkServiceType:
 */
/**
 typedef NS_ENUM(NSUInteger, NSURLRequestNetworkServiceType)
 {
     NSURLNetworkServiceTypeDefault = 0,    // Standard internet traffic
     NSURLNetworkServiceTypeVoIP API_DEPRECATED("Use PushKit for VoIP control purposes", macos(10.7,10.15), ios(4.0,13.0), watchos(2.0,6.0), tvos(9.0,13.0)) = 1,    // Voice over IP control traffic
     NSURLNetworkServiceTypeVideo = 2,    // Video traffic
     NSURLNetworkServiceTypeBackground = 3, // Background traffic
     NSURLNetworkServiceTypeVoice = 4,       // Voice data
     NSURLNetworkServiceTypeResponsiveData = 6, // Responsive data
     NSURLNetworkServiceTypeAVStreaming API_AVAILABLE(macosx(10.9), ios(7.0), watchos(2.0), tvos(9.0)) = 8 , // Multimedia Audio/Video Streaming
     NSURLNetworkServiceTypeResponsiveAV API_AVAILABLE(macosx(10.9), ios(7.0), watchos(2.0), tvos(9.0)) = 9, // Responsive Multimedia Audio/Video
     NSURLNetworkServiceTypeCallSignaling API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) = 11, // Call Signaling
 };
 NSURLNetworkServiceTypeDefault  默认的服务类型
 NSURLNetworkServiceTypeVoIP     基于IP的语音通话（已废弃，被NSURLNetworkServiceTypeVoice覆盖）
 NSURLNetworkServiceTypeVideo   基于视频通话
 NSURLNetworkServiceTypeBackground 基于下载
 NSURLNetworkServiceTypeVoice   语音
 NSURLNetworkServiceTypeResponsiveData 即时消息
 NSURLNetworkServiceTypeAVStreaming  用于流式传输音频/视频数据的服务类型。
 NSURLNetworkServiceTypeResponsiveAV 即时通话
 NSURLNetworkServiceTypeCallSignaling   电话信号
 */
@property (nonatomic, assign) NSURLRequestNetworkServiceType networkServiceType;


/**
 The timeout interval, in seconds, for created requests. The default timeout interval is 60 seconds.
超时信息 默认 60

 @see NSMutableURLRequest -setTimeoutInterval:
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 Default HTTP header field values to be applied to serialized requests. By default, these include the following:

 - `Accept-Language` with the contents of `NSLocale +preferredLanguages`
 - `User-Agent` with the contents of various bundle identifiers and OS designations

 默认的请求头
 @discussion To add or remove default request headers, use `setValue:forHTTPHeaderField:`. //使用setValue:forHTTPHeaderField:`设置
 */
@property (readonly, nonatomic, strong) NSDictionary <NSString *, NSString *> *HTTPRequestHeaders;

/**
 Creates and returns a serializer with default configuration. //默认的序列化配置
 */
+ (instancetype)serializer;

/**
 Sets the value for the HTTP headers set in request objects made by the HTTP client. If `nil`, removes the existing value for that header.
设置HTTP 的头信息。如果为空，则移除已经存在的值。
 @param field The HTTP header to set a default value for
 @param value The value set as default for the specified header, or `nil`
 */
- (void)setValue:(nullable NSString *)value
forHTTPHeaderField:(NSString *)field;

/**
 Returns the value for the HTTP headers set in the request serializer.
 返回HTTP 的头信息中，某一项的值

 @param field The HTTP header to retrieve the default value for

 @return The value set as default for the specified header, or `nil`
 */
- (nullable NSString *)valueForHTTPHeaderField:(NSString *)field;


/**
 Sets the "Authorization" HTTP header set in request objects made by the HTTP client to a basic authentication value with Base64-encoded username and password. This overwrites any existing value for this header.
 将 HTTP 客户端发出的请求对象中设置的“授权”HTTP 标头设置为具有 Base64 编码的用户名和密码的基本身份验证值。 这将覆盖此标头的任何现有值。
 @param username The HTTP basic auth username
 @param password The HTTP basic auth password
 */
- (void)setAuthorizationHeaderFieldWithUsername:(NSString *)username
                                       password:(NSString *)password;

/**
 Clears any existing value for the "Authorization" HTTP header.
 清除授权的头部信息
 */
- (void)clearAuthorizationHeader;

/**
 HTTP methods for which serialized requests will encode parameters as a query string. `GET`, `HEAD`, and `DELETE` by default.
  设置允许的查询方法集合
 */
@property (nonatomic, strong) NSSet <NSString *> *HTTPMethodsEncodingParametersInURI;

/**
 Set the method of query string serialization according to one of the pre-defined styles.

 @param style The serialization style.

 @see AFHTTPRequestQueryStringSerializationStyle
 */
- (void)setQueryStringSerializationWithStyle:(WBHTTPRequestQueryStringSerializationStyle)style;
/**
 Set the a custom method of query string serialization according to the specified block.

 @param block A block that defines a process of encoding parameters into a query string. This block returns the query string and takes three arguments: the request, the parameters to encode, and the error that occurred when attempting to encode parameters for the given request.
 */
//根据指定的块设置查询字符串序列化的自定义方法。

- (void)setQueryStringSerializationWithBlock:(nullable NSString * _Nullable (^)(NSURLRequest *request, id parameters, NSError * __autoreleasing *error))block;

/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and URL string.
 创建一个网络请求根据method和url

 If the HTTP method is `GET`, `HEAD`, or `DELETE`, the parameters will be used to construct a url-encoded query string that is appended to the request's URL. Otherwise, the parameters will be encoded according to the value of the `parameterEncoding` property, and set as the request body.

 @param method The HTTP method for the request, such as `GET`, `POST`, `PUT`, or `DELETE`. This parameter must not be `nil`.
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be either set as a query string for `GET` requests, or the request HTTP body.
 @param error The error that occurred while constructing the request.

 @return An `NSMutableURLRequest` object.
 */
- (nullable NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                          URLString:(NSString *)URLString
                                         parameters:(nullable id)parameters
                                              error:(NSError * _Nullable __autoreleasing *)error;


/**
 Creates an `NSMutableURLRequest` object with the specified HTTP method and URLString, and constructs a `multipart/form-data` HTTP body, using the specified parameters and multipart form data block. See http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.2

 Multipart form requests are automatically streamed, reading files directly from disk along with in-memory data in a single HTTP body. The resulting `NSMutableURLRequest` object has an `HTTPBodyStream` property, so refrain from setting `HTTPBodyStream` or `HTTPBody` on this request object, as it will clear out the multipart form body stream.

 @param method The HTTP method for the request. This parameter must not be `GET` or `HEAD`, or `nil`.
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol.
 @param error The error that occurred while constructing the request.

 @return An `NSMutableURLRequest` object
 */
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(nullable NSDictionary <NSString *, id> *)parameters
                              constructingBodyWithBlock:(nullable void (^)(id <WBMultipartFormData> formData))block
                                                  error:(NSError * _Nullable __autoreleasing *)error;

/**
 Creates an `NSMutableURLRequest` by removing the `HTTPBodyStream` from a request, and asynchronously writing its contents into the specified file, invoking the completion handler when finished.

 @param request The multipart form request. The `HTTPBodyStream` property of `request` must not be `nil`.
 @param fileURL The file URL to write multipart form contents to.
 @param handler A handler block to execute.

 @discussion There is a bug in `NSURLSessionTask` that causes requests to not send a `Content-Length` header when streaming contents from an HTTP body, which is notably problematic when interacting with the Amazon S3 webservice. As a workaround, this method takes a request constructed with `multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:error:`, or any other request with an `HTTPBodyStream`, writes the contents to the specified file and returns a copy of the original request with the `HTTPBodyStream` property set to `nil`. From here, the file can either be passed to `AFURLSessionManager -uploadTaskWithRequest:fromFile:progress:completionHandler:`, or have its contents read into an `NSData` that's assigned to the `HTTPBody` property of the request.

 @see https://github.com/AFNetworking/AFNetworking/issues/1398
 */
- (NSMutableURLRequest *)requestWithMultipartFormRequest:(NSURLRequest *)request
                             writingStreamContentsToFile:(NSURL *)fileURL
                                       completionHandler:(nullable void (^)(NSError * _Nullable error))handler;

@end


@protocol  WBMultipartFormData

//将文件通过fileURL转为NSData，并拼接到formData中
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                        error:(NSError * _Nullable __autoreleasing *)error;

//将文件通过fileURL转为NSData，并拼接到formData中
- (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                         name:(NSString *)name
                     fileName:(NSString *)fileName
                     mimeType:(NSString *)mimeType
                        error:(NSError * _Nullable __autoreleasing *)error;

//直接拼接输入流
- (void)appendPartWithInputStream:(nullable NSInputStream *)inputStream
                             name:(NSString *)name
                         fileName:(NSString *)fileName
                           length:(int64_t)length
                         mimeType:(NSString *)mimeType;

//直接拼接data
- (void)appendPartWithFileData:(NSData *)data
                          name:(NSString *)name
                      fileName:(NSString *)fileName
                      mimeType:(NSString *)mimeType;


//直接拼接data
- (void)appendPartWithFormData:(NSData *)data
                          name:(NSString *)name;

//直接拼接headers中的数据
- (void)appendPartWithHeaders:(nullable NSDictionary <NSString *, NSString *> *)headers
                         body:(NSData *)body;


//通过限制数据包大小并为从上传流读取的每个块添加延迟来限制请求带宽。
- (void)throttleBandwidthWithPacketSize:(NSUInteger)numberOfBytes
                                  delay:(NSTimeInterval)delay;


@end


/**
 `AFJSONRequestSerializer` is a subclass of `AFHTTPRequestSerializer` that encodes parameters as JSON using `NSJSONSerialization`, setting the `Content-Type` of the encoded request to `application/json`.
 
 `AFJSONRequestSerializer` 是 `AFHTTPRequestSerializer` 的子类，它使用 `NSJSONSerialization` 将参数编码为 JSON，将编码请求的 `Content-Type` 设置为 `application/json`。
 */

@interface WBJsonRequestSerializer : WBHTTPRequestSerializer

/**
 Options for writing the request JSON data from Foundation objects. For possible values, see the `NSJSONSerialization` documentation section "NSJSONWritingOptions". `0` by default.
 
 #从基础对象转JSON数据时使用/NSJSONWritingOptions
 typedef NS_OPTIONS(NSUInteger, NSJSONWritingOptions) {
 NSJSONWritingPrettyPrinted = (1UL << 0),//使用空白和缩进使输出更可读的写入选项。
 NSJSONWritingSortedKeys API_AVAILABLE(macos(10.13), ios(11.0), watchos(4.0), tvos(11.0)) = (1UL << 1),//按字典顺序排列键的写入选项。
 NSJSONWritingFragmentsAllowed = (1UL << 2),
 NSJSONWritingWithoutEscapingSlashes API_AVAILABLE(macos(10.15), ios(13.0), watchos(6.0), tvos(13.0)) = (1UL << 3),
 } API_AVAILABLE(macos(10.7), ios(5.0), watchos(2.0), tvos(9.0));

 NSJSONWritingPrettyPrinted = (1UL << 0) //是将生成的json数据格式化输出，这样可读性高，不设置则输出的json字符串就是一整行。(自己原生打印输出，一般选用这个可读性比较高)；
 NSJSONWritingSortedKeys //输出的json字符串就是一整行（如果要往后台传或者字典转json然后加密，就不能格式化，会有换行符和空格）；这个枚举是iOS11后才出的，iOS11之前我们可以用kNilOptions来替代
 NSJSONWritingFragmentsAllowed 允许写入片段
 NSJSONWritingWithoutEscapingSlashes 不转义斜线
*/

@property (nonatomic, assign) NSJSONWritingOptions writingOptions;


/**
 Creates and returns a JSON serializer with specified reading and writing options.

 @param writingOptions The specified JSON writing options.
 */
+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions;


@end



/*
 `AFPropertyListRequestSerializer` is a subclass of `AFHTTPRequestSerializer` that encodes parameters as JSON using `NSPropertyListSerializer`, setting the `Content-Type` of the encoded request to `application/x-plist`.

 `AFPropertyListRequestSerializer` 是 `AFHTTPRequestSerializer` 的子类，它使用 `NSPropertyListSerializer` 将参数编码为 JSON，将编码请求的 `Content-Type` 设置为 `application/x-plist`。
 */
@interface WBPropertyListRequestSerializer : WBHTTPRequestSerializer


/**
 The property list format. Possible values are described in "NSPropertyListFormat".
 
 typedef NS_ENUM(NSUInteger, NSPropertyListFormat) {
     NSPropertyListOpenStepFormat = kCFPropertyListOpenStepFormat,
     NSPropertyListXMLFormat_v1_0 = kCFPropertyListXMLFormat_v1_0,
     NSPropertyListBinaryFormat_v1_0 = kCFPropertyListBinaryFormat_v1_0
 };
 NSPropertyListOpenStepFormat = kCFPropertyListOpenStepFormat,//明文的方式
 NSPropertyListXMLFormat_v1_0 = kCFPropertyListXMLFormat_v1_0,//这个是xml的格式
 NSPropertyListBinaryFormat_v1_0 = kCFPropertyListBinaryFormat_v1_0//这个是二进制的格式

 */
@property (nonatomic, assign) NSPropertyListFormat format;

/**
 @warning The `writeOptions` property is currently unused.
 */
@property (nonatomic, assign) NSPropertyListWriteOptions writeOptions;

/**
 Creates and returns a property list serializer with a specified format, read options, and write options.

 @param format The property list format.
 @param writeOptions The property list write options.

 @warning The `writeOptions` property is currently unused.
 */
+ (instancetype)serializerWithFormat:(NSPropertyListFormat)format
                        writeOptions:(NSPropertyListWriteOptions)writeOptions;


@end

/**
 ## Error Domains

 The following error domain is predefined.

 - `NSString * const AFURLRequestSerializationErrorDomain`

 ### Constants

 `AFURLRequestSerializationErrorDomain`
 AFURLRequestSerializer errors. Error codes for `AFURLRequestSerializationErrorDomain` correspond to codes in `NSURLErrorDomain`.
 
作为NSError 初始化的key
[[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];

 */
FOUNDATION_EXPORT NSString * const WBURLRequestSerializationErrorDomain;

/**
 ## User info dictionary keys

 These keys may exist in the user info dictionary, in addition to those defined for NSError.

 - `NSString * const AFNetworkingOperationFailingURLRequestErrorKey`

 ### Constants

 `AFNetworkingOperationFailingURLRequestErrorKey`
 The corresponding value is an `NSURLRequest` containing the request of the operation associated with an error. This key is only present in the `AFURLRequestSerializationErrorDomain`.
 */
FOUNDATION_EXPORT NSString * const WBNetworkingOperationFailingURLRequestErrorKey;

/**
 ## Throttling Bandwidth for HTTP Request Input Streams

 @see -throttleBandwidthWithPacketSize:delay:

 ### Constants

 `kAFUploadStream3GSuggestedPacketSize`。3G网络下建议包大小
 Maximum packet size, in number of bytes. Equal to 16kb.

 `kAFUploadStream3GSuggestedDelay  3G网络下建议延迟0.2秒
 Duration of delay each time a packet is read. Equal to 0.2 seconds.
 */
FOUNDATION_EXPORT NSUInteger const kWBUploadStream3GSuggestedPacketSize;
FOUNDATION_EXPORT NSTimeInterval const kWBUploadStream3GSuggestedDelay;
NS_ASSUME_NONNULL_END
