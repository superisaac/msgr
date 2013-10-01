//
//  MSGRMsgObject.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-9.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRBaseObject.h"

/*typedef enum {
    MSGRMsgText=0,
    MSGRMsgAudio=1,
    MSGRMsgImage=2
} MSGRMsgType; */

typedef enum {
    MSGRMsgStateDelivering=0,
    MSGRMsgStateUnDelivered=1,
    MSGRMsgStateDelivered=2
} MSGRMsgState;

@class MSGRUserObject;
@interface MSGRMsgObject : MSGRBaseObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic) NSString * msgType;
@property (nonatomic) MSGRMsgState msgState;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) id metadata;
@property (nonatomic, retain) MSGRUserObject * fromUser;
@property (nonatomic, retain) MSGRUserObject * toUser;
@property (nonatomic, retain) NSString * globalId;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, readonly) MSGRUserObject * peerUser;
@property (nonatomic, readonly) BOOL isLocal;
@property (nonatomic, retain) NSData * jsonMetadata;

+ (MSGRMsgObject *)localMessage;
- (BOOL)selfSend;
- (BOOL)isText;
- (BOOL)isImage;
- (BOOL)isAudio;
- (NSString *)convTitle;
- (NSString *)assetPath;

@end
