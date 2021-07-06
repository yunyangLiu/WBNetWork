//
//  ViewController.m
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/5.
//

#import "ViewController.h"
#import "Person.h"

#import <AssertMacros.h>


@interface ViewController ()

@property (nonatomic, strong) Person *person;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    

 
    NSLog(@"Reachable ==== %@",NSLocalizedStringFromTable(@"Not Reachable", @"WBNetworking", nil));

    NSLog(@"Reachable ==== %@",NSLocalizedString(@"Reachable", nil));


    
    
}
//观擦的回调
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                      context:(void *)context{
    
}

@end
