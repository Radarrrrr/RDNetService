# RDNetService
简易版网络请求底层库，需要依托AFNetworking使用 （pod "AFNetworking"）


本类pods名为：
pod "RDNetService"



一、标准请求方式：
//1. 设定配置项
NSDictionary *headerDic = @{
                                @"Content-Type":@"application/x-www-form-urlencoded",
                                @"User-Agent":@"xxxxxxx-ios",
                                @"Accept-Language":@"zh-cn",
                                @"Accept-Encoding":@"gzip"
};

[NetService initializeHttpPrefix:@"http://192.168.142.130/home.php"];
[NetService initializeHttpHeader:headerDic];
[NetService initializeHttpTimeOut:20];

//2. 发送请求    
[NetService requestGetWithParams:@{@"client":@"ios", @"version":@"1.0.0"} action:@"get_home" progress:^(double progress) {
        NSLog(@"进度= %f",progress);
} success:^(id response) {
        NSLog(@"success");
        NSLog(@"%@", response);
} failure:^(NSDictionary *errdic) {
        NSLog(@"failure");
        NSLog(@"%@", errdic);
}];


二、简易请求方式，不需要设定配置项
[NetService requestGetWithURL:@"http://img63.ddimg.cn/2018/2/2/2018020214431836357.jpg" progress:^(double progress) {
        NSLog(@"进度= %f",progress);
} success:^(id response) {
        UIImage *image = [UIImage imageWithData:response];
        NSLog(@"success");
} failure:^(NSDictionary *errdic) {
        NSLog(@"failure");
}];


