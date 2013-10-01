//
//  MSGRTalkConnectionThread.m
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-2.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRTalkConnectionThread.h"

@implementation MSGRTalkConnectionThread {
    dispatch_group_t _waitGroup;
}

@synthesize runLoop = _runLoop;

- (id)init {
    self = [super init];
    if (self) {
        _waitGroup = dispatch_group_create();
        dispatch_group_enter(_waitGroup);
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        _runLoop = [NSRunLoop currentRunLoop];
        dispatch_group_leave(_waitGroup);
        
        NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate distantFuture] interval:0.0 target:nil selector:nil userInfo:nil repeats:NO];
        [_runLoop addTimer:timer forMode:NSDefaultRunLoopMode];

        while ([_runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
        }
        assert(NO);
    }
}


- (NSRunLoop *)runLoop;
{
    dispatch_group_wait(_waitGroup, DISPATCH_TIME_FOREVER);
    return _runLoop;
}

+ (NSRunLoop *)networkRunLoop {
    static MSGRTalkConnectionThread * networkThread = nil;
    static NSRunLoop * networkRunLoop = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkThread = [[MSGRTalkConnectionThread alloc] init];
        networkThread.name = @"com.zengke.Msgr";
        [networkThread start];
        networkRunLoop = networkThread.runLoop;
    });
    
    return networkRunLoop;
}

@end
