//
//  HWEntiry.m
//  HWDynamicEntity
//
//  Created by huanwh on 2017/12/12.
//  Copyright © 2017年 wally.h. All rights reserved.
//


#import "HWEntiry.h"

@interface HWEntiry : NSProxy <HWEntiry>
@property (nonatomic, strong) NSMutableDictionary *innerDictionary;
@end


@implementation HWEntiry
@synthesize jsonString   = _jsonString;
@synthesize toDictionary = _toDictionary;

static NSString * HWErrorDomain = @"HWEntiry Error: ";


- (instancetype)initWithJsonString:(NSString *)json {
    if (json) {
        self->_jsonString = [json copy];
        
        NSData * data = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSError * err = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
        NSAssert(err == nil, @" json serialization error: %@", err);
        if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            self.innerDictionary = [jsonObj mutableCopy];
        }
        return self;
    }
    
    return nil;
}

- (instancetype)initWithDictionary:(NSDictionary *)dic {
    if ([dic isKindOfClass:[NSDictionary class]]) {
        self.innerDictionary = [dic mutableCopy];
        
        // jsonstring 赋值
        NSError * error = nil;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
        NSAssert(error == nil, @"[%@]: %@",HWErrorDomain,error);
        if (error) {
            NSLog(@"[%@]: %@",HWErrorDomain,error);
            return self;
        }
        
        NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        self->_jsonString = jsonString;
        
        return self;
    }
    return nil;
}

-(BOOL)isKindOfClass:(Class)aClass {
    if ([NSStringFromClass(aClass) isEqualToString:NSStringFromClass(self.class)]) {
        return YES;
    }
    return NO;
}

-(NSString *)description {
    return  [NSString stringWithFormat:@"%@",self.innerDictionary];
}

-(NSDictionary *)toDictionary {
    return [self.innerDictionary mutableCopy];
}

#pragma mark - 字典 & 数组 转换
void exchangeDicToObject(NSMutableDictionary *sourceDic, NSString * key) {
    id obj = [sourceDic objectForKey:key];
    
    // 字典
    if ([obj isKindOfClass:[NSDictionary class]]) {
        id entiry = [[HWEntiry alloc] initWithDictionary:obj];
        if (entiry) {
            [sourceDic setObject:entiry forKey:key];
        }
    }
    // 数组
    else if ([obj isKindOfClass:[NSArray class]]) {
        NSArray * dicArray = (NSArray *)obj;
        NSMutableArray * objsArray = [NSMutableArray arrayWithCapacity:[dicArray count]];
        for (id value in dicArray) {
            // 此处不使用递归，每次使用时再进行转换
            if ([value isKindOfClass:[NSDictionary class]]) {
                id entiry = [[HWEntiry alloc] initWithDictionary:value];
                if (entiry) {
                    [objsArray addObject:entiry];
                }else {
                    [objsArray addObject:value];
                }
            }else {
                [objsArray addObject:value];
            }
        }
        [sourceDic setObject:objsArray forKey:key];
    }
}

#pragma mark - 关键词过滤，待补充
/**
 * 关键词
 * 随着业务扩展
 *
 * https://cupsofcocoa.wordpress.com/2010/09/09/reserved-keywords/
 */
+ (NSArray *)reserves {
    static NSArray *_arr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _arr =  @[
             @"_id",
             @"_do"
             ];
    });
    return _arr;
}
NSString * exchangeReservedWords(NSString *originName) {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF = %@", originName];
    NSArray *results = [[HWEntiry reserves] filteredArrayUsingPredicate:predicate];
    
    if (results && results.count > 0) {
        return [originName substringFromIndex:1];
    }
    return originName;
}

#pragma mark - Message Forwading

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    SEL changedSelector = aSelector;
    if ([self implementNSProxyMethods:aSelector]) {
        NSMethodSignature *sign = [self.class instanceMethodSignatureForSelector:aSelector];
        return sign;
    }
    
    else if ([self propertyNameScanFromGetterSelector:aSelector]) {
        changedSelector = @selector(objectForKey:);
    }
    else if ([self propertyNameScanFromSetterSelector:aSelector]) {
        changedSelector = @selector(setObject:forKey:);
    }
    
    NSMethodSignature *sign = [[self.innerDictionary class] instanceMethodSignatureForSelector:changedSelector];
    
    return sign;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    NSString *propertyName = nil;
    
    // Try getter
    propertyName = [self propertyNameScanFromGetterSelector:invocation.selector];
    if (propertyName) {
        exchangeDicToObject(self.innerDictionary, propertyName);
        
        propertyName = exchangeReservedWords(propertyName);
        
        invocation.selector = @selector(objectForKey:);
        [invocation setArgument:&propertyName atIndex:2]; // self, _cmd, key
        [invocation invokeWithTarget:self.innerDictionary];
        return;
    }
    
    // Try setter
    propertyName = [self propertyNameScanFromSetterSelector:invocation.selector];
    if (propertyName) {

        invocation.selector = @selector(setObject:forKey:);
        [invocation setArgument:&propertyName atIndex:3]; // self, _cmd, obj, key
        [invocation invokeWithTarget:self.innerDictionary];
        return;
    }

    [super forwardInvocation:invocation];
}

#pragma mark - Helpers

- (NSString *)propertyNameScanFromGetterSelector:(SEL)selector
{
    NSString *selectorName = NSStringFromSelector(selector);
    NSUInteger parameterCount = [[selectorName componentsSeparatedByString:@":"] count] - 1;
    if (parameterCount == 0) {
        return selectorName;
    }
    return nil;
}

- (NSString *)propertyNameScanFromSetterSelector:(SEL)selector
{
    NSString *selectorName = NSStringFromSelector(selector);
    NSUInteger parameterCount = [[selectorName componentsSeparatedByString:@":"] count] - 1;
    
    if ([selectorName hasPrefix:@"set"] && parameterCount == 1) {
        NSUInteger firstColonLocation = [selectorName rangeOfString:@":"].location;
        NSString * name = [selectorName substringWithRange:NSMakeRange(3, firstColonLocation - 3)];
        if (name.length > 0) {
            NSString * firstChar = [name substringToIndex:1];
            name = [name stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstChar.lowercaseString];
        }
        return name;
    }
    return nil;
}

#pragma mark -  proxy 方法过滤，待补充

+ (NSArray *)proxyMethods {
    static NSArray *_methods;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _methods =  @[
                  @"isKindOfClass:"
                  ];
    });
    return _methods;
}
- (BOOL)implementNSProxyMethods:(SEL)selector {
    NSString *selectorName = NSStringFromSelector(selector);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF = %@", selectorName];
    NSArray *results = [[HWEntiry proxyMethods] filteredArrayUsingPredicate:predicate];
    
    if (results && results.count > 0) {
        return YES;
    }
    return NO;
}

@end


NSError *HWError(NSString *msg, NSUInteger errorCode) {
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    info[@"message"] = msg;
    NSError * error = [NSError errorWithDomain:@"com.hwh.HWEntiry" code:errorCode userInfo:info];
    return error;
}

#pragma mark - 快速创建
id HWEntiryWithJson(NSString *json) {
    return [[HWEntiry alloc] initWithJsonString:json];
}



