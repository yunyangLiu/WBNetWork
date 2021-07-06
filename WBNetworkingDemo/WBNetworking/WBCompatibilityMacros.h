//
//  WBCompatibilityMacros.h
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/5.
//

#ifndef WBCompatibilityMacros_h
#define WBCompatibilityMacros_h


// 如果宏定义 API_AVAILABLE 已存在，则定义WB_API_AVAILABLE 并实现该方法
//__VA_ARGS__在预编译中会被实参列表取代， ...表示可变参列表
#ifdef API_AVAILABLE
    #define WB_API_AVAILABLE(...)   API_AVAILABLE(__VA_ARGS__)
#else
    #define WB_API_AVAILABLE(...)
#endif

// 如果宏定义 API_UNAVAILABLE 已存在，则定义WB_API_UNAVAILABLE 并实现该方法
//__VA_ARGS__在预编译中会被实参列表取代， ...表示可变参列表
#ifdef API_UNAVAILABLE
    #define WB_API_UNAVAILABLE(...)  API_UNAVAILABLE(__VA_ARGS__)
#else
    #define WB_API_UNAVAILABLE(...)
#endif

//如果存在-Wunguarded-availability-new警告，则定义WB_CAN_USE_AT_AVAILABLE为1
#if __has_warning("-Wunguarded-availability-new")
    #define WB_CAN_USE_AT_AVAILABLE 1
#else
    #define WB_CAN_USE_AT_AVAILABLE 0
#endif

//__IPHONE_OS_VERSION_MAX_ALLOWED 代表iOS最大的版本 100000代表10.0
//__MAC_OS_VERSION_MAX_ALLOWED 代表MAC OS最大的版本 101200代表10.12
//__WATCH_OS_MAX_VERSION_ALLOWED 代表iOS最大的版本 30000代表3.0
//__TV_OS_MAX_VERSION_ALLOWED 代表iOS最大的版本 100000代表10.0
//如果满足以上要求，则定义WB_CAN_INCLUDE_SESSION_TASK_METRICS为0
#if ((__IPHONE_OS_VERSION_MAX_ALLOWED && __IPHONE_OS_VERSION_MAX_ALLOWED < 100000) || (__MAC_OS_VERSION_MAX_ALLOWED && __MAC_OS_VERSION_MAX_ALLOWED < 101200) ||(__WATCH_OS_MAX_VERSION_ALLOWED && __WATCH_OS_MAX_VERSION_ALLOWED < 30000) ||(__TV_OS_MAX_VERSION_ALLOWED && __TV_OS_MAX_VERSION_ALLOWED < 100000))
    #define WB_CAN_INCLUDE_SESSION_TASK_METRICS 0
#else
    #define WB_CAN_INCLUDE_SESSION_TASK_METRICS 1
#endif


#endif /* WBCompatibilityMacros_h */
