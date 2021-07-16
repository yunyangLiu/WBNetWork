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

@protocol WBMutipartFromData;


@interface WBHTTPRequestSerializer :NSObject<WBURLRequestSerialization>



@end


@protocol  WBMutipartFromData<NSObject>


@end
NS_ASSUME_NONNULL_END
