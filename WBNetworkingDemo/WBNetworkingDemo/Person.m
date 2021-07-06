//
//  Person.m
//  WBNetworkingDemo
//
//  Created by 58 on 2021/7/6.
//

#import "Person.h"

@implementation Person

- (void)setFullName:(NSString *)fullName{
    
    _fullName = fullName;
    
    self.nikedName = fullName;
    
}

+ (NSSet *)keyPathsForValuesAffectingNikedName{
    return [NSSet setWithObject:@"fullName"];
}
@end
