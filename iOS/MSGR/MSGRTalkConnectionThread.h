//
//  MSGRTalkConnectionThread.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-2.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSGRTalkConnectionThread : NSThread

@property (nonatomic, readonly) NSRunLoop * runLoop;

+ (NSRunLoop *)networkRunLoop;

@end
