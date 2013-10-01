//
//  MSGRStroke.h
//  MSGRPaster
//
//  Created by Ke Zeng on 13-6-26.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSGRStroke : NSObject

@property (nonatomic, retain) UIColor * strokeColor;

- (id)initWithPoint:(CGPoint)p;
- (void)addPoint:(CGPoint)point;
//- (void)drawStrokeInContext:(CGContextRef)context;
- (void)drawCurveStrokeInContext:(CGContextRef)context;

- (void)drawStrokeLineInContext:(CGContextRef)context toPoint:(CGPoint)end;
- (void)setEndPoint:(CGPoint)p;
- (void)generateControlPoints;

@end
