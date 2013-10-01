//
//  MSGRObjectStore.m
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-28.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRObjectStore.h"

@implementation MSGRObjectStore

- (void)closeStore {
    
}

- (BOOL)isEqual:(id)object {
    return self == object;
}

- (NSArray *)conversationListWithRange:(NSRange)range {
    return @[];
}

- (NSArray *)conversationList {
    return @[];
}

- (void)saveMessage:(MSGRMsgObject *)msg {
    
}
- (void)addMessage:(MSGRMsgObject *)msg {
    
}

- (NSArray *)messageListOfUser:(MSGRUserObject *)user range:(NSRange)range {
    return @[];
}
- (NSArray *)messageListOfUser:(MSGRUserObject *)user {
    return @[];
}

- (void)clearConvOfUser:(MSGRUserObject *)user {
}

- (void)clearConv:(MSGRConvObject *)conv {
}

- (void)saveData:(NSData *)data toAsset:(NSString *)path {
    
}

- (NSData *)dataFromAssetPath:(NSString *)path {
    return nil;
}

- (NSURL *)assetURLWithPath:(NSString *)path {
    return  nil;
}



@end
