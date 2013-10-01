//
//  MSGRUserObject.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-9.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSGRBaseObject.h"

@interface MSGRUserObject:MSGRBaseObject <NSCoding>

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * screenName;
@property (nonatomic, retain) NSDate * lastModified;

@end
