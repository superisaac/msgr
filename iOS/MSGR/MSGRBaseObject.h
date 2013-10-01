//
//  MSGRBaseObject.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-9.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSGRBaseObject : NSObject

+ (NSArray *)objectsFromArray:(NSArray *)arr;
+ (NSString *)parseString:(id)src;
+ (NSDate *)parseDate:(id)dateObj;
+ (NSInteger)parseInteger:(id)val;

- (id)initWithJson:(NSDictionary *)json;
- (void)feedJson:(NSDictionary *)json;

@end
