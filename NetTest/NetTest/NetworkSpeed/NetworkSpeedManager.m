//
//  NetworkSpeedManager.m
//  MeasurNetTools
//
//  Created by Motian on 2017/7/18.
//  Copyright © 2017年 SH. All rights reserved.
//

#import "NetworkSpeedManager.h"
#import "QBTools.h"

static NSString *TEST_URL = @"http://down.cdcdn.cn/Uploads/2017-07-04/20170704102207.zip";

@interface NetworkSpeedManager ()<NSURLSessionDelegate>{
    NSInteger _secend;
    NSInteger _interval;
}

@property (strong, nonatomic)NSURLSession *session;
@property (strong, nonatomic)NSTimer *timer;
@property (strong, nonatomic)NSMutableData *forthwithData;
@property (strong, nonatomic)NSMutableData *finishedData;
@property (strong, nonatomic)NSMutableArray *dataArr;

@property (strong, nonatomic)ForthwithBlock forthwithBlock;
@property (strong, nonatomic)FinishedBlock finishedBlock;
@property (strong, nonatomic)FailureBlock failureBlock;

@end

@implementation NetworkSpeedManager

- (void)NetworkSpeed:(ForthwithBlock )forthwithSpeed Finished:(FinishedBlock )finishedSpeed Failure:(FailureBlock)failure{
    
    self.forthwithBlock = forthwithSpeed;
    self.finishedBlock = finishedSpeed;
    self.failureBlock = failure;
}

- (void)startMeasurement{
    
    _interval = 20;
    
    NSURLSessionTask * task = [self.session dataTaskWithURL:[NSURL URLWithString:TEST_URL]];
    [task resume];
    
    self.timer.fireDate = [NSDate distantPast];
}

- (void)endMeasurement{
    
    self.timer.fireDate = [NSDate distantFuture];
    [self.timer invalidate];
    self.timer = nil;


    if (self.finishedBlock) {
        self.finishedBlock([NSString stringWithFormat:@"%@/S", [QBTools formattedFileSize:(self.finishedData.length / _secend -1)]],[QBTools formatBandWidth:[[self dataSort] length]]);
    }
    
    _secend = 0;
    
    [self.forthwithData resetBytesInRange:NSMakeRange(0, self.forthwithData.length)];
    [self.forthwithData setLength:0];
    
    [self.finishedData resetBytesInRange:NSMakeRange(0, self.finishedData.length)];
    [self.finishedData setLength:0];
}
- (void)timerAction{
    
    _secend ++;
    
    if (self.forthwithBlock) {
        self.forthwithBlock ([NSString stringWithFormat:@"%@/S", [QBTools formattedFileSize:self.forthwithData.length]]);
    }
    if (_secend == _interval) {
        [self endMeasurement];
    }
    [self.dataArr addObject:self.forthwithData];
    [self.forthwithData resetBytesInRange:NSMakeRange(0, self.forthwithData.length)];
    [self.forthwithData setLength:0];
}

- (NSData *)dataSort{
    NSInteger index = self.dataArr.count;
    
    for (int i = 0; i < index; ++i) {

        for (int j = 0; j < index-1; ++j) {

            if ([self.dataArr[j] length]< [self.dataArr[j+1] length]) {
                
                [self.dataArr exchangeObjectAtIndex:j withObjectAtIndex:j+1];
            }
        }
    }
    return [self.dataArr[0] copy];
}

#pragma mark - URLSession Delegate
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    //NSLog(@"%ld",data.length);
    [self.forthwithData appendData:data];
    [self.finishedData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self endMeasurement];
}

-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{

    if (self.failureBlock) {
        self.failureBlock(error);
    }
}

#pragma mark - Getter
- (NSURLSession *)session{
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    }
    return _session;
}

- (NSTimer *)timer{
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}

- (NSMutableData *)forthwithData{
    if (!_forthwithData) {
        _forthwithData = [NSMutableData data];
    }
    return _forthwithData;
}

- (NSMutableData *)finishedData{
    if (!_finishedData) {
        _finishedData = [NSMutableData data];
    }
    return _finishedData;
}

- (NSMutableArray *)dataArr{
    if (!_dataArr) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

@end

#pragma mark - Reachability
static const NSString *  DEFAULT_HOSTNAME = @"http://www.baidu.com";
static const NSString *  DEFAULT_IPADDRESS = @"http://www.baidu.com";

@interface ReachabilityManager ()

@end

@implementation ReachabilityManager

+ (ReachabilityManager *)sharedManager{
    
    static ReachabilityManager *reachability = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        reachability = [[ReachabilityManager alloc] init];
        
        reachability.curNetworkNotifiyType = InternetConnection;
        
        reachability.isConnectNetwork = YES;
    });
    return reachability;
}

- (void)startNotifier{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    switch (self.curNetworkNotifiyType) {
        case HostName:{
            self.reachability = [Reachability reachabilityWithHostName: (self.hostName ? self.hostName : DEFAULT_HOSTNAME)];
            break;
        }
        case IPAddress:{
            struct sockaddr_in sockAddr;
            bzero((char*)&sockAddr,sizeof(sockAddr));
            sockAddr.sin_len = sizeof(sockAddr);
            sockAddr.sin_family = AF_INET;
            sockAddr.sin_addr.s_addr= inet_addr([self.ipAddress ? self.ipAddress : DEFAULT_IPADDRESS UTF8String]);
            self.reachability = [Reachability reachabilityWithAddress: &sockAddr];
            break;
        }
        case InternetConnection:{
            self.reachability = [Reachability reachabilityForInternetConnection];
            break;
        }
        case WiFi:{
            self.reachability = [Reachability reachabilityForLocalWiFi];
            break;
        }
        default:
            break;
    }
    if(self.reachability){
        [self.reachability startNotifier];
    }
}

- (void)reachabilityChanged:(NSNotification *)noti{
    
    Reachability* curReach = [noti object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    self.curNetworkStatus = [reachability currentReachabilityStatus];
    
    switch (self.curNetworkStatus)
    {
        case NotReachable:{

            self.isConnectNetwork = NO;
            break;
        }
        case ReachableViaWWAN:{
            
            [self networkConnected];
            self.isConnectNetwork = YES;
            break;
        }
        case ReachableVia2G:{
            
            [self networkConnected];
            self.isConnectNetwork = YES;
            break;
        }
        case ReachableVia3G:{
            
            [self networkConnected];
            self.isConnectNetwork = YES;
            break;
        }
        case ReachableVia4G:{
            
            [self networkConnected];
            self.isConnectNetwork = YES;
            break;
        }
        case ReachableViaWiFi:{
            
            [self networkConnected];
            self.isConnectNetwork = YES;
            break;
        }
    }
}

- (void)networkConnected{
    
    if(!self.isConnectNetwork){
        
    }
}

- (void)stopNotifier
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

#pragma mark - dealloc
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

@end
