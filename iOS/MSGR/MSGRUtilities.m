//
//  MSGRUtilities.m
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-27.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRUtilities.h"

@implementation MSGRUtilities

+ (float)osVersion {
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}

+ (BOOL)isEmptyText:(NSString*)text {
    return (text == nil || text.length == 0);
}

+ (NSString *)labelOfDate:(NSDate *)date {
    NSCalendar * calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents * cps = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit|NSDayCalendarUnit|NSWeekCalendarUnit|NSWeekdayCalendarUnit| NSMonthCalendarUnit|NSYearCalendarUnit fromDate:date];
    NSDateComponents * newCps = [calendar components:NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit|NSDayCalendarUnit|NSWeekCalendarUnit|NSWeekdayCalendarUnit| NSMonthCalendarUnit|NSYearCalendarUnit fromDate:[NSDate date]];
    if (newCps.year == cps.year && newCps.month == cps.month && newCps.day == cps.day) {
        return [NSString stringWithFormat:@"%02d:%02d", cps.hour, cps.minute];
    } else {
        return [NSString stringWithFormat:@"%04d-%02d-%02d", cps.year, cps.month, cps.day];
    }
}
@end
