//
//  MSGRBaseObject.m
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-9.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRBaseObject.h"

@implementation MSGRBaseObject

+ (NSArray *)objectsFromArray:(NSArray *)arr {
    NSMutableArray * objects = [[NSMutableArray alloc] init];
    for (NSDictionary * d in arr) {
        MSGRBaseObject * obj = [[[self class] alloc] initWithJson:d];
        [objects addObject:obj];
    }
    return objects;
}

+ (NSString *)parseString:(id)src {
    if (src == nil) {
        return nil;
    } else if ([src isKindOfClass:[NSNull class]]) {
        return nil;
    } else if ([src isKindOfClass:[NSString class]]) {
        return src;
    } else {
        return [src stringValue];
    }
}

+ (NSDate *)parseDate:(id)dateObj {
    if (dateObj == nil) {
        return nil;
    } else {
        NSTimeInterval interval = [dateObj integerValue];
        return [NSDate dateWithTimeIntervalSince1970:interval];
    }
}

+ (NSInteger)parseInteger:(id)val {
    if (val == nil) {
        return 0;
    } else {
        return [val integerValue];
    }
}

- (id)initWithJson:(NSDictionary *)json {
    self = [self init];
    if (self) {
        [self feedJson:json];
    }
    return self;
}

- (void)feedJson:(NSDictionary *)json {
    
}

@end
