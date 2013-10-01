//
//  MSGRMsgObject.m
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-9.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRMsgObject.h"
#import "MSGRUserObject.h"
#import "MSGRMessenger.h"

@implementation MSGRMsgObject
@synthesize content, fromUser, toUser, dateCreated;
@synthesize metadata;
@synthesize identifier;
@synthesize msgType;
@synthesize msgState;
@synthesize globalId;

+ (MSGRMsgObject *)localMessage {
    MSGRMsgObject * msg = [[MSGRMsgObject alloc] init];
    NSDate * now = [[NSDate alloc] init];
    msg.identifier = [NSString stringWithFormat:@"local.%d", (int)[now timeIntervalSince1970]];
    msg.msgState = MSGRMsgStateUnDelivered;
    return msg;
}

- (void)feedJson:(NSDictionary *)json {
    self.msgState = MSGRMsgStateDelivered;
    self.msgType = [MSGRBaseObject parseString:json[@"msgType"]];
    self.identifier = [MSGRBaseObject parseString:json[@"id"]];
    self.content = [MSGRBaseObject parseString:json[@"content"]];
    self.metadata = json[@"metadata"];
    
    if ([self.metadata isKindOfClass:[NSNull class]]) {
        self.metadata = nil;
    }
    
    MSGRUserObject * loginUser = [MSGRMessenger messenger].loginUser;
    
    if(json[@"from_user"] && ![json[@"from_user"] isKindOfClass:[NSNull class]]) {
        self.fromUser = [[MSGRUserObject alloc] initWithJson:json[@"from_user"]];
        if ([loginUser isEqual:self.fromUser]) {
            self.fromUser = nil;
        }
    }
    if (json[@"to_user"] && ![json[@"to_user"] isKindOfClass:[NSNull class]]) {
        self.toUser = [[MSGRUserObject alloc] initWithJson:json[@"to_user"]];
        if ([loginUser isEqual:self.toUser]) {
            self.toUser = nil;
        }
    }    
    self.dateCreated = [MSGRBaseObject parseDate:json[@"date_created"]];
}

- (BOOL)selfSend {
    return self.fromUser == nil || [self.fromUser isEqual:[MSGRMessenger messenger].loginUser];
}

- (BOOL)isEqual:(id)object {
    if([object isKindOfClass:[self class]]) {
        typeof(self) conv = (typeof(self))object;
        return [self.identifier isEqualToString:conv.identifier];
    }
    return NO;
}

- (MSGRUserObject *)peerUser {
    return self.fromUser?self.fromUser:self.toUser;
}

- (NSString *)stringValue {
    return [NSString stringWithFormat:@"MsgObject(id=%@, peerUser=%@, content=%@)", self.identifier, self.peerUser, self.content];
}

- (BOOL)isLocal {
    return self.identifier != nil && self.identifier.length > 6 && [[self.identifier substringToIndex:6] isEqualToString:@"local."];
}

- (BOOL)isText {
    return [self.msgType isEqualToString:@"text"];
}

- (BOOL)isImage {
    return [self.msgType isEqualToString:@"image"];
}

- (BOOL)isAudio {
    return [self.msgType isEqualToString:@"audio"];
}

- (NSString *)convTitle {
    if ([self isImage]) {
        return @"Image";
    } else if ([self isAudio]) {
        return @"Voice";
    } else {
        return self.content;
    }
}

- (NSString *)assetPath {
    if ([self isImage]) {
        return [NSString stringWithFormat:@"%@.jpg", self.identifier];
    } else if ([self isAudio]) {
        return [NSString stringWithFormat:@"%@.aac", self.identifier];
    } else {
        return nil;
    }
}

- (void)setJsonMetadata:(NSData *)jsonMetadata {
    if (jsonMetadata != nil && jsonMetadata.length > 0) {
        NSError * error;
        self.metadata = [NSJSONSerialization JSONObjectWithData:jsonMetadata options:0 error:&error];
        if (error) {
            NSLog(@"Error on setting json metadata %@", error.description);
        }
    } else {
        self.metadata = nil;
    }
}

- (NSData *)jsonMetadata {
    if (self.metadata) {
        NSError * error;
        NSData * data = [NSJSONSerialization dataWithJSONObject:self.metadata options:0 error:&error];
        if (error) {
            NSLog(@"json data error %@", error.description);
            data = nil;
        }
        return data;
    }
    return nil;
}

@end
