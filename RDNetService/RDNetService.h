//
//  RDNetService.h
//
//  Created by Radar on 18/2/1.
//  Copyright (c) 2018年 Radar. All rights reserved.
//
 
/*说明，本类暂只支持php接口，支持形式上符合如下样式的请求，
 http://api.xxxx.com/index.php?action=get_home&user_client=iphone 
 
 常规使用路径：
 [initialize] -> [request]
 
 极简使用路径：(直接使用url请求)
 [requestGetWithURL]
 
*/


/* httpheader字典结构:
 {
     "Content-Type":"application/x-www-form-urlencoded",
     "User-Agent":"Dangdang-iOS",
     "Accept-Language":"zh-cn",
     "Accept-Encoding":"gzip"
 }
*/


/* params数据结构：
//注意：header是在特殊情况下，用来补充或者覆盖默认header使用的
{
    "HttpHeader":
    {
        "client_ip":"192.168.142.104",
        "device":"iphone",
        "udid":"28209E0CB600B29A4ABEF4D708085C55"
    },
    
    "url":"http://192.168.142.130/home.php", 
    "action":"get_home",
    "user_client":"iphone",
    "client_version":"1.0.0"
}
*/




#import <Foundation/Foundation.h>

typedef void(^successCallBlock)(id response);
typedef void(^failCallBlock)(NSDictionary *errdic);
typedef void(^progressCallBlock)(double progress); //progress: 0～1

@interface RDNetService : NSObject


#pragma mark -- 初始化方法 (建议放在appDelegate里)
//准备HTTP请求的各种属性设定，使用本类之前，必须调用的方法。//PS: 如果不需要设定任何prefix和header，则只需要使用requestGetWithURL就行了
+ (void)initializeHttpPrefix:(NSString*)prefix;         //初始化http Prefix, 也就是本类里边params数据结构中的url，后面也可以通过override方法临时更改。 格式如 @"http://192.168.142.130/home.php" 后面不用带问号，里边会自动补齐
+ (void)initializeHttpHeader:(NSDictionary*)headers;    //初始化http header，后面也可以通过override方法临时更改
+ (void)initializeHttpTimeOut:(NSTimeInterval)timeout;  //初始化http请求超时时间，只可以设定一次，不设定就使用默认值了


#pragma mark -- 请求发送方法
//异步请求方法
//PS: <*如下方法全部都可以使用完整版的params字典来强制执行自定义的prefix，header，action的请求，优先级会高于方法参数和初始化参数，完整格式见上面注释*>
+ (void)requestGetWithParams:(NSDictionary*)params action:(NSString*)action progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure;    //GET方法，用来处理需要带参数的请求
+ (void)requestPostWithParams:(NSDictionary*)params action:(NSString*)action progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure;   //POST方法，只用来处理字符串的POST

+ (void)requestGetWithURL:(NSString*)url progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure;    //只需要通过URL获取数据或者图片文件等的方法，用来处理已知URL且不需要参数的请求
+ (void)requestPostFileWithParams:(NSDictionary*)params action:(NSString*)action fileData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure; //POST方法，用来处理Multipart文件


//同步请求方法
+ (NSData*)requestGetSync:(NSString *)url;
+ (NSData*)requestPostSync:(NSString *)postString StringURL:(NSString *)url;



@end



