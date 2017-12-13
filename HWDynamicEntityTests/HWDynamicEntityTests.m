//
//  HWDynamicEntityTests.m
//  HWDynamicEntityTests
//
//  Created by huanwh on 2017/12/12.
//  Copyright © 2017年 wally.h. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HWEntiry.h"


/** 关系图
 *
 *  |XXTestEntiry
        |about
        |balance
        |isActive
        |age
        |subEntiry <XXTestSubEntiry>
        |tags
            [string]
        |friends
            [XXTestFriend]
        |nullValue
 */
@protocol XXTestSubEntiry <HWEntiry>
@property (nonatomic, copy)NSString * name;
@end

@protocol XXTestFriend <HWEntiry>
@property (nonatomic, copy)NSString * _id;
@property (nonatomic, copy)NSString * name;
@end

@protocol XXTestEntiry <HWEntiry>
@property (nonatomic, copy)     NSString * about;
@property (nonatomic, copy)     NSString * balance;
@property (nonatomic, assign)   NSNumber * isActive;
@property (nonatomic, strong)   NSNumber * age;
@property (nonatomic, strong)   NSArray  * tags;
@property (nonatomic, copy)     NSArray <XXTestFriend>  * friends;

@property (nonatomic, strong)   id<XXTestSubEntiry>subEntiry;

@property (nonatomic, copy)     NSString * nullValue;
@end




@interface HWDynamicEntityTests : XCTestCase
@property (nonatomic, strong)id<XXTestEntiry>obj;
@end

@implementation HWDynamicEntityTests

- (void)setUp {
    [super setUp];
    NSError * error = nil;
    NSString * path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"json"];
    NSString * json = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"read json string error: %@", error);
        return;
    }
    
    self.obj = HWEntiryWithJson(json);
}

- (void)tearDown {
    [super tearDown];
}

/// 测试取值
- (void)testExample {
    
    NSAssert([self.obj.subEntiry.name isEqualToString:@"wo am i"], @"获取嵌套dic错误  .super dic =  %@; error value = %@",self.obj.subEntiry,self.obj.subEntiry.name);
}


/// 测试 json dictionary 转换
- (void)testInterface {
    NSAssert([self.obj.jsonString isKindOfClass:[NSString class]],       @"转换json 错误");
    NSAssert([self.obj.toDictionary isKindOfClass:[NSDictionary class]], @"转换Dic  错误");
}

/// 测试取出的值是否正确
- (void)testType {
    NSAssert([self.obj.isActive isKindOfClass:[NSNumber class]],@"布尔类型错误");
    NSAssert([self.obj.age isKindOfClass:[NSNumber class]],     @"数字类型错误");
    NSAssert([self.obj.subEntiry.name isKindOfClass:[NSString class]],@"实体类型错误");
    NSAssert([self.obj.tags isKindOfClass:[NSArray class]], @"数组类型错误");
    NSAssert([self.obj.friends isKindOfClass:[NSArray class]], @"数组类型错误");
    
    NSArray * objs = self.obj.friends;
    for (id<XXTestFriend>friend in objs) {
        NSLog(@"\n\n Hi friedn, my name is : %@, code : %@ \n\n", friend.name,friend._id);
    }
    NSLog(@"\nisActive: %@ \nage:%@\ntags: %@",self.obj.isActive, self.obj.age,self.obj.tags);
}

- (void)testSetter {
    NSLog(@"origin about value = %@", self.obj.about);
    
    self.obj.about = @"who am i";
    
    NSAssert([self.obj.about isEqualToString:@"who am i"], @"HWEntiry 赋值错误");
}

/// 测试赋值
- (void)testNullValue {
    self.obj.nullValue = @"who am i";
    
    NSAssert([self.obj.nullValue isEqualToString:@"who am i"], @"HWEntiry 空值错误");
}
@end
