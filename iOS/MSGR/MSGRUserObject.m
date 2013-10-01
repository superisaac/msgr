//
//  MSGRUserObject.m
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-9.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRUserObject.h"

@implementation MSGRUserObject
@synthesize lastModified, screenName;
@synthesize identifier;

- (void)feedJson:(NSDictionary *)json {
    self.identifier = [MSGRBaseObject parseString:json[@"id"]];
    
    self.screenName = [MSGRBaseObject parseString:json[@"screen_name"]];
    self.lastModified = [MSGRBaseObject parseDate:json[@"lm"]];
}

- (BOOL)isEqual:(id)object {
    if([object isKindOfClass:[self class]]) {
        typeof(self) conv = (typeof(self))object;
        return [self.identifier isEqualToString:conv.identifier];
    }
    return NO;
}

- (NSString *)stringValue {
    return [NSString stringWithFormat:@"UserObject(id=%@, screenName=%@)", self.identifier, self.screenName];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
    if (self) {
        self.identifier = [coder decodeObjectForKey:@"identifier"];
        self.screenName = [coder decodeObjectForKey:@"screenName"];
        self.lastModified = [coder decodeObjectForKey:@"lastModified"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.identifier forKey:@"identifier"];
    [aCoder encodeObject:self.screenName forKey:@"screenName"];
    [aCoder encodeObject:self.lastModified forKey:@"lastModified"];
}

@end
