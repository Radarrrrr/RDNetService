//
//  RDNetService.m
//
//  Created by Radar on 18/2/1.
//  Copyright (c) 2018年 Radar. All rights reserved.
//


#import "RDNetService.h"
#import "AFNetworking.h"


#define STRVALID(str)   [RDNetService checkStringValid:str]   //检查一个字符串是否有效
#define DICTIONARYHASVALUE(dic)  (dic && [dic isKindOfClass:[NSDictionary class]] && [dic count] > 0)// 判断字典是否有值

#define DEFAULT_HTTP_TIME_OUT   30.0  //HTTP请求默认超时时间，30秒是经验值，可以通过初始化方法修改



#pragma mark --------- ConfigStore类
//配置项存储类, 把初始化配置项存储在内存中。
@interface ConfigStore : NSObject
@end

@interface ConfigStore ()

@property (nonatomic, copy) NSString *httpPrefix;           //http Prefix, 也就是本类里边params数据结构中的url，后面也可以通过override方法临时更改
@property (nonatomic, copy) NSDictionary *httpHeaders;      //http header, 初始化设定一个，后面也可以通过override方法临时更改
@property (nonatomic)       NSTimeInterval httpTimeout;     //http请求超时时间，只可以设定一次，不设定就使用默认值了

@end

@implementation ConfigStore
@end



#pragma mark -------- RDNetService类

static ConfigStore *cfgStore;
static AFHTTPSessionManager *afnManger;

@interface RDNetService ()

//字符串&URL的encode和decode，暂时做成内部方法不放开了
+ (NSString*)urlEncode:(NSString*)urlString;
+ (NSString*)urlDecode:(NSString*)urlString;

@end


@implementation RDNetService


#pragma mark -- 单实例相关
//为初始化配置创建单实例
+ (ConfigStore *)sharedConfigStore
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        cfgStore = [[ConfigStore alloc] init];
    });
    
    return cfgStore;
}

//为get和post创建AFN单实例
+ (AFHTTPSessionManager *)sharedAFJsonManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        afnManger = [AFHTTPSessionManager manager];
        afnManger.requestSerializer = [AFJSONRequestSerializer serializer];
        afnManger.responseSerializer = [AFHTTPResponseSerializer serializer];

        afnManger.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:
                                                               @"application/json", 
                                                               @"text/json", 
                                                               @"text/javascript", 
                                                               @"text/html", 
                                                               @"text/xml", 
                                                               @"text/plain", 
                                                               @"image/jpeg", 
                                                               @"image/png",
                                                               @"image/gif",
                                                               @"audio/mp3",
                                                               @"video/mpeg4",
                                                               nil];
        
        ConfigStore *config = [self sharedConfigStore];
        if(DICTIONARYHASVALUE(config.httpHeaders))
        {
            NSArray *allkeys = [config.httpHeaders allKeys];
            for(NSString *field in allkeys)
            {
                NSString *header = [config.httpHeaders objectForKey:field];
                if(STRVALID(header))
                {
                    [afnManger.requestSerializer setValue:header forHTTPHeaderField:field];
                }
            }
        }
    
        NSTimeInterval timeOut = DEFAULT_HTTP_TIME_OUT;
        if(config.httpTimeout > 0) timeOut = config.httpTimeout;
        
        [afnManger.requestSerializer setTimeoutInterval:timeOut];

        afnManger.securityPolicy = [[AFSecurityPolicy alloc] init];
        afnManger.securityPolicy.allowInvalidCertificates = YES;
        afnManger.securityPolicy.validatesDomainName = NO;
    });

    return afnManger;
}




#pragma mark -- 初始化方法
+ (void)initializeHttpPrefix:(NSString*)prefix
{
    if(!STRVALID(prefix)) return;
    
    ConfigStore *confStore = [self sharedConfigStore];
    confStore.httpPrefix = prefix;
}
+ (void)initializeHttpHeader:(NSDictionary*)headers
{
    if(!DICTIONARYHASVALUE(headers)) return;
    
    ConfigStore *confStore = [self sharedConfigStore];
    confStore.httpHeaders = headers;
}
+ (void)initializeHttpTimeOut:(NSTimeInterval)timeout
{
    ConfigStore *confStore = [self sharedConfigStore];
    
    if(timeout > 0)
    {
        confStore.httpTimeout = timeout;
    }
    else
    {
        confStore.httpTimeout = DEFAULT_HTTP_TIME_OUT;
    }
}



#pragma mark -- 属性配套方法
+ (NSDictionary*)assembleParams:(NSDictionary*)params action:(NSString*)action method:(NSString*)method
{    
    //method 如果是POST必须要写明，其他方式可以直接填nil
    //本类组装params的时候，以原始params设定为准，如果params里边已经全部都自带了，则本类后面就不做任何事情了
    
    //url有两个来源，1.从config里边初始化 2.params自带  
    NSMutableDictionary *paramsDic = [[NSMutableDictionary alloc] init];
    
    //先把全部属性都塞进来
    if(DICTIONARYHASVALUE(params))
    {
        [paramsDic addEntriesFromDictionary:params];
    }
    
    //以params设定的原始属性为准
    if(!STRVALID([paramsDic objectForKey:@"action"]))
    {
        if(STRVALID(action))
        {
            [paramsDic setObject:action forKey:@"action"];
        }
    }

    //先判断是否params里边已经自带url, 有自带url，以自带的为主, 如果没有自带的，用初始化的补进去
    if(!STRVALID([paramsDic objectForKey:@"url"]))
    {
        ConfigStore *config = [self sharedConfigStore];
        if(STRVALID(config.httpPrefix))
        {
            [paramsDic setObject:config.httpPrefix forKey:@"url"];
        }
    }
    
    //修正post下面，url和action的关系，url后面挂上actin，并从params里边抹去action字段
    //如果是POST，拼一下URL, 判断一下，如果后面不带问号，则自己补一个
    if(STRVALID(method) && [method isEqualToString:@"POST"])
    {
        NSString *paraURL = [paramsDic objectForKey:@"url"];
        NSString *paraAction = [paramsDic objectForKey:@"action"];
        
        if(STRVALID(paraURL) && STRVALID(paraAction))
        {
            NSString *useURL = paraURL;
            
            //判断paraURL是否有问号
            NSRange range = [paraURL rangeOfString:@"?" options:NSBackwardsSearch];
            if(range.length == 0)
            {
                //没问号，补一个问号
                useURL = [useURL stringByAppendingString:@"?"];
            }
            
            //接上action字段
            useURL = [NSString stringWithFormat:@"%@action=%@", useURL, paraAction];
            
            //把useURL塞回到属性数组里
            [paramsDic setObject:useURL forKey:@"url"];
            
            //移除掉action字段
            [paramsDic removeObjectForKey:@"action"];
        }
    }
    
    return paramsDic;
}



#pragma mark -- 异步请求方法
+ (void)requestGetWithParams:(NSDictionary*)params action:(NSString*)action progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure
{
    NSDictionary *requestParams = [self assembleParams:params action:action method:@"GET"];
    
    if(!requestParams || !STRVALID([requestParams objectForKey:@"url"]))
    {
        NSLog(@"url不能为空");
        return;
    }
    
    NSString *api_prefix = [requestParams objectForKey:@"url"];
    [self requestGetWithURL:api_prefix params:requestParams progress:progress success:success failure:failure];
}

+ (void)requestPostWithParams:(NSDictionary*)params action:(NSString*)action progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure
{
    //ps:本类中，整个params全部都post过去，action拼在url后面做成新的url
    NSDictionary *requestParams = [self assembleParams:params action:action method:@"POST"];
    
    if(!requestParams || !STRVALID([requestParams objectForKey:@"url"]))
    {
        NSLog(@"url不能为空");
        return;
    }
    
    NSString *api_prefix = [requestParams objectForKey:@"url"];
    [self requestPostWithURL:api_prefix params:requestParams progress:progress success:success failure:failure];
}

+ (void)requestGetWithURL:(NSString*)url progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure
{
    if(!STRVALID(url))
    {
        NSLog(@"url不能为空");
        return;
    }
    
    [self requestGetWithURL:url params:nil progress:progress success:success failure:failure];
}


/**
 *  multipart方式post方法
 *
 *  @param params    post参数
 *  @param fileData  文件流
 *  @param name      给服务器解析用的key
 *  @param fileName  文件名
 *  @param mimeType  文件类型
 *  @param success   成功回调
 *  @param failure   失败回调
 */
+ (void)requestPostFileWithParams:(NSDictionary*)params action:(NSString*)action fileData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure
{
     NSDictionary *requestParams = [self assembleParams:params action:action method:@"POST"];
    
    if(!requestParams || !STRVALID([requestParams objectForKey:@"url"]))
    {
        NSLog(@"url不能为空");
        return;
    }
    
    NSString *api_prefix = [requestParams objectForKey:@"url"];
    [self requestPostFileWithURL:api_prefix params:requestParams fileData:fileData name:name fileName:fileName mimeType:mimeType progress:progress success:success failure:failure];
}





#pragma mark -- 请求 get post file 底层方法，url 和 参数分开
+ (void)requestGetWithURL:(NSString*)url params:(NSDictionary*)params progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure
{
    AFHTTPSessionManager *afom = [self sharedAFJsonManager];
    
    [self setHttpHeader:params afmanager:afom];
    [self removeUrlKey:params];

    [afom GET:url parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
   
        if(progress)
        {
            progress(downloadProgress.fractionCompleted);
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *requestURL =  task.currentRequest.URL.absoluteString;
        NSLog(@"REQUEST GET SUCCESS: %@", requestURL);
        
        //处理数据    
        NSString *mineType = task.response.MIMEType;
        id data = [self analysisData:responseObject withMineType:mineType];
        
        if (success) 
        {
            success(data);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSString *requestURL =  task.currentRequest.URL.absoluteString;
        NSLog(@"REQUEST GET FAILURE: %@", requestURL);
        
        if (task.state != NSURLSessionTaskStateCanceling && failure)
        {
            NSDictionary *errDict = [self getErrorDict:error];
            failure(errDict);
        }
    }];
}

+ (void)requestPostWithURL:(NSString *)url params:(NSDictionary*)params progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure
{
    AFHTTPSessionManager *afom = [self sharedAFJsonManager];

    [self setHttpHeader:params afmanager:afom];
    [self removeUrlKey:params];

    [afom POST:url parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if(progress)
        {
            progress(uploadProgress.fractionCompleted);
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *requestURL =  task.currentRequest.URL.absoluteString;
        NSLog(@"REQUEST POST SUCCESS: %@", requestURL);
        
        //处理数据
        NSString *mineType = task.response.MIMEType;
        id data = [self analysisData:responseObject withMineType:mineType];
        
        if (success) 
        {
            success(data);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSString *requestURL =  task.currentRequest.URL.absoluteString;
        NSLog(@"REQUEST POST FAILURE: %@", requestURL);
        
        if (task.state != NSURLSessionTaskStateCanceling && failure) 
        {
            NSDictionary *errDict = [self getErrorDict:error];
            failure(errDict);
        }
        
    }];
}

+ (void)requestPostFileWithURL:(NSString *)url params:(NSDictionary*)params fileData:(NSData *)fileData name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType progress:(progressCallBlock)progress success:(successCallBlock)success failure:(failCallBlock)failure
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager.requestSerializer setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"]; //此处固定为.*二进制格式上传内容，不用更改了
    
    //过滤掉Content-Type不受到初始化的影响，除非是在后面override覆写进来，否则就默认用二进制格式了。
    ConfigStore *config = [self sharedConfigStore];
    if(DICTIONARYHASVALUE(config.httpHeaders))
    {
        NSArray *allkeys = [config.httpHeaders allKeys];
        for(NSString *field in allkeys)
        {
            NSString *header = [config.httpHeaders objectForKey:field];
            if(STRVALID(header))
            {
                if([header isEqualToString:@"Content-Type"]) continue;
                [afnManger.requestSerializer setValue:header forHTTPHeaderField:field];
            }
        }
    }
    
    NSTimeInterval timeOut = DEFAULT_HTTP_TIME_OUT;
    if(config.httpTimeout > 0) timeOut = config.httpTimeout;
    
    manager.requestSerializer.timeoutInterval = timeOut;
    
    
    [self setHttpHeader:params afmanager:manager];
    [self removeUrlKey:params];
    
    [manager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        [formData appendPartWithFileData:fileData name:name fileName:fileName mimeType:mimeType];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if(progress)
        {
            progress(uploadProgress.fractionCompleted);
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
        NSString *requestURL =  task.currentRequest.URL.absoluteString;
        NSLog(@"REQUEST POST FILE SUCCESS: %@", requestURL);
        
        //处理数据
        NSString *mineType = task.response.MIMEType;
        id data = [self analysisData:responseObject withMineType:mineType];
        
        if (success) 
        {
            success(data);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        NSString *requestURL =  task.currentRequest.URL.absoluteString;
        NSLog(@"REQUEST POST FILE FAILURE: %@", requestURL);
        
        if (task.state != NSURLSessionTaskStateCanceling && failure) 
        {
            NSDictionary *errDict = [self getErrorDict:error];
            failure(errDict);
        }
        
    }];
    
}



#pragma mark -- 同步请求 -- 鉴于NSURLSession没有很好的支持纯同步，暂时先用NSURLConnection了
+ (NSData*)requestGetSync:(NSString *)url
{
    if(!STRVALID(url)) return nil;
    
    NSURL *aurl = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aurl];
    
    [request setHTTPMethod:@"GET"];
    
    ConfigStore *config = [self sharedConfigStore];
    NSTimeInterval timeOut = DEFAULT_HTTP_TIME_OUT;
    if(config.httpTimeout > 0) timeOut = config.httpTimeout;
    
    [request setTimeoutInterval:timeOut];
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse: nil error: nil];
    return returnData;
}
+ (NSData*)requestPostSync:(NSString *)postString StringURL:(NSString *)url
{
    if(!STRVALID(url)) return nil;
    
    NSURL *aurl = [NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:aurl];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    ConfigStore *config = [self sharedConfigStore];
    NSTimeInterval timeOut = DEFAULT_HTTP_TIME_OUT;
    if(config.httpTimeout > 0) timeOut = config.httpTimeout;
    
    [request setTimeoutInterval:timeOut];
    
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse: nil error: nil];
    return returnData;
}



#pragma mark -- 配套方法
//加密
+ (NSString*)urlEncode:(NSString*)urlString
{
    if(!STRVALID(urlString)) return nil;
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                             kCFAllocatorDefault,
                                                                                             (CFStringRef)urlString,
                                                                                             NULL,
                                                                                             CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                             kCFStringEncodingUTF8));

    return result; 
}

//解密
+ (NSString*)urlDecode:(NSString*)urlString
{
    if(!STRVALID(urlString)) return nil;
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
                                                                                                             kCFAllocatorDefault,
                                                                                                             (CFStringRef)urlString,
                                                                                                             CFSTR(""),
                                                                                                             kCFStringEncodingUTF8));
    return result; 
}



#pragma mark -- method
+ (BOOL)checkStringValid:(NSString *)string
{
    if(!string) return NO;
    if(![string isKindOfClass:[NSString class]]) return NO;
    if([string compare:@""] == NSOrderedSame) return NO;
    if([string compare:@"(null)"] == NSOrderedSame) return NO;
    
    return YES;
}

+ (NSDictionary *)getErrorDict:(NSError *)error
{
    NSMutableDictionary *errDict = [NSMutableDictionary dictionary];
    if (![AFNetworkReachabilityManager sharedManager].reachable)
    {
        errDict[@"errorCode"] = @"-2";
        errDict[@"errorMsg"] = @"网络不给力";
    }
    else
    {
        errDict[@"errorCode"] = @"-1";  //其他异常
        errDict[@"errorMsg"] = error.userInfo.description;
    }
    
    return errDict;
}

//删除url和header键值
+ (void)removeUrlKey:(NSDictionary *) dic
{
    if(DICTIONARYHASVALUE(dic) && [dic isKindOfClass:[NSMutableDictionary class]])
    {
        NSMutableDictionary *dict = (NSMutableDictionary *)dic;
        [dict removeObjectForKey:@"url"];
        [dict removeObjectForKey:@"HttpHeader"];
    }
}

/**
 *  设置httpheader，此处可以在外部通过params设置header，覆盖本地默认的header参数
 *
 *  @param dict      HttpHeader为key的字典
 *  @param afmanager 网络请求manager
 */
+ (void)setHttpHeader:(NSDictionary *)dict afmanager:(AFHTTPSessionManager *)afmanager
{
    if(DICTIONARYHASVALUE(dict))
    {
        NSDictionary *httpHeaderDict = [dict objectForKey:@"HttpHeader"];
        
        if(DICTIONARYHASVALUE(httpHeaderDict))
        {
            for(NSString *key in httpHeaderDict.allKeys)
            {
                id value = [httpHeaderDict objectForKey:key];
                if(value)
                {
                    [afmanager.requestSerializer setValue:value forHTTPHeaderField:key];
                }
            }
        }
    }
}

//根据minetype解析返回数据
+ (id)analysisData:(id)data withMineType:(NSString*)mineType
{
    //根据url后缀，分析数据源，根据可识别的类型，返回对应的数据类型
    if(![data isKindOfClass:[NSData class]] || [(NSData*)data length] <= 0) return nil;
    
    //如果mineType不存在，也直接返回了
    if(!STRVALID(mineType)) return data;
    
    //如果mineType存在，则只认为application/json，text/json，text/html 这三种格式为json，其他格式都直接返回二进制，由上层自行处理
    id retData = data;
    
    //如果不可识别，或者不存在后缀，则把数据转成JSON数据返回
    if([mineType isEqualToString:@"application/json"] || 
       [mineType isEqualToString:@"text/json"] || 
       [mineType isEqualToString:@"text/html"] )
    {
        retData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments|NSJSONReadingMutableContainers error:nil];
    }
    
    return retData;
}




@end








