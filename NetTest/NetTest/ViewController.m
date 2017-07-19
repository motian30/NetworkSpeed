//
//  ViewController.m
//  NetTest
//
//  Created by Motian on 2017/7/19.
//  Copyright © 2017年 Motian. All rights reserved.
//

#import "ViewController.h"
#import "NetworkSpeedManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NetworkSpeedManager *manager = [[NetworkSpeedManager alloc]init];
   
    [manager NetworkSpeed:^(NSString *speed) {
        NSLog(@"即时网速:%@",speed);
    } Finished:^(NSString *speed, NSString *bandWidth) {
        NSLog(@"平均网速:%@ 带宽:%@",speed,bandWidth);
    } Failure:^(NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }];
    [manager startMeasurement];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
