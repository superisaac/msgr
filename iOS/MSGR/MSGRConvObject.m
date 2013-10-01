//
//  MSGRConvObject.m
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-9.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRConvObject.h"
#import "MSGRMsgObject.h"
#import "MSGRUserObject.h"

@implementation MSGRConvObject
@synthesize user, lastMessage, numberOfUnread;


- (void)feedJson:(NSDictionary *)json {
    self.numberOfUnread = [MSGRBaseObject parseInteger:json[@"unread_count"]];
    self.lastMessage = [[MSGRMsgObject alloc] initWithJson:json[@"last_message"]];
    self.user = [[MSGRUserObject alloc] initWithJson:json[@"with_user"]];
}

- (BOOL)isEqual:(id)object {
    if([object isKindOfClass:[self class]]) {
        typeof(self) obj = (typeof(self))object;
        return [self.user isEqual:obj.user];
    }
    return NO;
}

- (NSString *)stringValue {
    return [NSString stringWithFormat:@"ConvObject(user=%@, lastMessage=%@, unread=%d)", self.user, self.lastMessage, self.numberOfUnread];
}



@end
