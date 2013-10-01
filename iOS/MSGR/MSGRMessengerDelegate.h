//
//  MSGRMessengerDelegate.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-10-1.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MSGRMsgObject;
@protocol MSGRMessengerDelegate <NSObject>

@required
- (void)connectionClosed;
- (void)loginSuccess;
- (void)localMessage:(MSGRMsgObject *)msg;
- (void)receivedMessage:(MSGRMsgObject *)msg;
@end
