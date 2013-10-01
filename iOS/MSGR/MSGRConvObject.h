//
//  MSGRConvObject.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-9.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRBaseObject.h"

@class MSGRUserObject;
@class MSGRMsgObject;

@interface MSGRConvObject : MSGRBaseObject

@property (nonatomic) NSInteger numberOfUnread;

@property (nonatomic, retain) MSGRMsgObject * lastMessage;
@property (nonatomic, retain) MSGRUserObject * user;
@end
