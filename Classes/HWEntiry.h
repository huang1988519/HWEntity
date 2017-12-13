
//  Created by huanwh on 2017/12/12.
//  Copyright © 2017年 wally.h. All rights reserved.
//
//  通过Json生成Model，使用协议定义接口来获取json中的值。

//  初始化有两种方式
//    1.[[HWEntiry alloc] initWithJsonString:json];
//    2.HWEntiryWithJson(json) 推荐
//


#import <Foundation/Foundation.h>

@protocol HWEntiry <NSObject>
@property (nonatomic, copy, readonly) NSString * jsonString;
@property (nonatomic, copy, readonly) NSDictionary *toDictionary;

/** override. 需要 HEEntiry实现的方法.
 *  现包含
 [
    @"isKindOfClass:"
 ]
 */
+ (NSArray *)proxyMethods;

/** override. ios 保留关键词
 * 现包含
 [
 @"id",
 @"do"
 ]
 * 参考  https://cupsofcocoa.wordpress.com/2010/09/09/reserved-keywords/
 */
+ (NSArray *)reserves;
@end


/// 快捷创建  HWEntiry 方法。 直接使用此方法创建 Model。
extern id HWEntiryWithJson(NSString *json);


