//
//  ViewController.m
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/5.
//

#import "ViewController.h"
#import "Person.h"

#import <AssertMacros.h>
#import "WBURLRequestSeriailzation.h"


@interface ViewController ()

@property (nonatomic, strong) Person *person;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    

//    int (^block)() = ^(){
//
//        return 2;
//    };
//
//    int a =  block();
    
//    UITextField *textfiled = [[UITextField alloc]initWithFrame:CGRectMake(100, 200, 200, 40)];
//    textfiled.backgroundColor = UIColor.redColor;
//    textfiled.textAlignment = NSTextAlignmentRight;
//    [self.view addSubview:textfiled];
//
    
    WBHTTPRequestSerializer *s = [[WBHTTPRequestSerializer alloc]init];
    
    
    [s setQueryStringSerializationWithBlock:^NSString * _Nullable(NSURLRequest * _Nonnull request, id  _Nonnull parameters, NSError *__autoreleasing  _Nullable * _Nullable error) {
        
        NSLog(@"%@",request.URL.absoluteString);
        return  request.URL.absoluteString;
        
    }];
    
    
}
//观擦的回调
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                      context:(void *)context{
    
}

@end
