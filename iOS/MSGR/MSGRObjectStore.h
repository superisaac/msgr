//
//  MSGRObjectStore.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-28.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSGRMsgObject.h"
#import "MSGRUserObject.h"
#import "MSGRConvObject.h"
#import "MSGRObjectStore.h"

@interface MSGRObjectStore : NSObject

- (void)closeStore;

- (NSArray *)conversationListWithRange:(NSRange)range;
- (NSArray *)conversationList;
- (void)addMessage:(MSGRMsgObject *)msg;
- (void)saveMessage:(MSGRMsgObject *)msg;
- (NSArray *)messageListOfUser:(MSGRUserObject *)user range:(NSRange)range;
- (NSArray *)messageListOfUser:(MSGRUserObject *)user;
- (void)clearConvOfUser:(MSGRUserObject *)user;
- (void)clearConv:(MSGRConvObject *)conv;
- (void)saveData:(NSData *)data toAsset:(NSString *)path;
- (NSData *)dataFromAssetPath:(NSString *)path;
- (NSURL *)assetURLWithPath:(NSString *)path;

@end
