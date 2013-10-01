//
//  MSGRUtilities.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-27.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSGRUtilities : NSObject

+ (float)osVersion;
+ (BOOL)isEmptyText:(NSString*)text;
+ (NSString *)labelOfDate:(NSDate *)date;

@end

