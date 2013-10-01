//
//  MSGRCategories.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-10-1.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray (MSGR)
- (NSArray *)reversedArray;
@end

@interface UIColor (MSGR)
+ (UIColor *)grayLevelColor:(CGFloat)grayLevel;
+ (UIColor *)grayLevelColor:(CGFloat)grayLevel alpha:(CGFloat)alpha;
+ (UIColor *)darkBlueColor;
+ (UIColor *)lightYellowColor;
@end

@interface UIView (MSGR)
- (CGPoint)originInView:(UIView *)containerView;
@end

@interface NSData (MSGR)

- (NSData *)base64Decode;
- (NSData *)base64Encode;

- (NSInteger)firstPostionOfData:(NSData*)subData;
- (NSInteger)firstPostionOfData:(NSData *)subData offset:(NSInteger)offset;

- (NSString *)UTF8String;
@end