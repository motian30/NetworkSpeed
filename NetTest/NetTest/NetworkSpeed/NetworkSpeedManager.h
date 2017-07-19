//
//  NetworkSpeedManager.h
//  MeasurNetTools
//
//  Created by Motian on 2017/7/18.
//  Copyright © 2017年 SH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import <arpa/inet.h>

@class NetworkSpeedManager;

typedef void (^ForthwithBlock)(NSString *speed);
typedef void (^FinishedBlock)(NSString *speed, NSString *bandWidth);
typedef void (^FailureBlock)(NSError *error);

@interface NetworkSpeedManager : NSObject

- (void)NetworkSpeed:(ForthwithBlock )forthwithSpeed Finished:(FinishedBlock )finishedSpeed Failure:(FailureBlock )failure;

- (void)startMeasurement;

@end


typedef enum : NSInteger{
    HostName = 0,
    IPAddress,
    InternetConnection,
    WiFi 
} NetworkNotifyType;

@interface ReachabilityManager : NSObject

@property(nonatomic, strong) Reachability *reachability;

@property(nonatomic, assign) BOOL isConnectNetwork;

@property(nonatomic, assign) NetworkStatus curNetworkStatus;

@property(nonatomic, assign) NetworkNotifyType curNetworkNotifiyType;

@property(nonatomic, assign) NSString *hostName;

@property(nonatomic, assign) NSString *ipAddress;

+ (ReachabilityManager *)sharedManager;

- (void)startNotifier;

- (void)stopNotifier;
@end
