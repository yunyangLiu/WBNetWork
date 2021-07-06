//
//  ViewController.m
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/5.
//

#import "ViewController.h"

#import <AssertMacros.h>


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    NSString *str = @"111111111";
    __Require_Quiet(NO, _out);
    str = @"222222222";


_out:
    
    NSLog(@"%@",str);
  
}


@end
