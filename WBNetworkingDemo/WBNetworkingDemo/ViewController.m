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
    

    self.person = [Person new];
    self.person.fullName = @"李四";
    
    [self.person addObserver:self forKeyPath:@"nikedName"
    options:NSKeyValueObservingOptionNew context:nil];
    
    self.person.fullName = @"张三";
    
    
}
//观擦的回调
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                      context:(void *)context{
    NSLog(@"new ===  %@",change[@"new"]);
    
}

@end
