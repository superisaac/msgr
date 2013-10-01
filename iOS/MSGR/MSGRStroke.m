//
//  MSGRStroke.m
//  MSGRPaster
//
//  Created by Ke Zeng on 13-6-26.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRStroke.h"

// Point arithmetic

CGPoint paAdd(CGPoint p1, CGPoint p2) {
    return CGPointMake(p1.x + p2.x, p1.y + p2.y);
}

CGPoint paSub(CGPoint p1, CGPoint p2) {
    return CGPointMake(p1.x - p2.x, p1.y - p2.y);
}

CGPoint paScale(CGPoint p, CGFloat r) {
    return CGPointMake(p.x * r, p.y * r);
}

CGPoint paCenter(CGPoint p1, CGPoint p2) {
    return CGPointMake(0.5 * (p1.x + p2.x), 0.5 * (p1.y + p2.y));
}

CGFloat paDistance(CGPoint p) {
    return sqrtf(p.x * p.x + p.y * p.y);
}

CGFloat paDistanceBetween(CGPoint p1, CGPoint p2) {
    return paDistance(paSub(p1, p2));
}

CGFloat paCross(CGPoint p1, CGPoint p2) {
    return (p1.x * p2.x + p1.y * p2.y) / (paDistance(p1) * paDistance(p2));
}

CGPoint paNormalize(CGPoint p) {
    CGFloat direction = paDistance(p);
    return paScale(p, 1.0/direction);    
}


@implementation MSGRStroke {
    CGPoint startPoint;
    CGPoint endPoint;
    
    NSMutableArray * points;
    NSMutableArray * leftPoints;
    NSMutableArray * rightPoints;
}
@synthesize strokeColor;

- (id)init {
    self = [super init];
    if (self) {
        points = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithPoint:(CGPoint)p {
    self = [self init];
    if (self) {
        startPoint = p;
    }
    return self;
}

- (void)setEndPoint:(CGPoint)p {
    endPoint = p;
}

- (void)addPoint:(CGPoint)point {
    [points addObject:[NSValue valueWithCGPoint:point]];
}

/*- (void)drawStrokeInContext:(CGContextRef)context {
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    
    for(NSValue * val in points) {
        CGPoint p = [val CGPointValue];
        CGContextAddLineToPoint(context, p.x, p.y);
    }
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextStrokePath(context);
}*/

- (void)drawCurveStrokeInContext:(CGContextRef)context {
    CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    if  (points.count == 0) {
        CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
        return;
    }
    CGPoint c1 = [leftPoints[0] CGPointValue];
    CGPoint p = [points[0] CGPointValue];
    CGContextAddQuadCurveToPoint(context, c1.x, c1.y, p.x, p.y);
    
    for (NSInteger i=1; i<points.count; i++) {
        p = [points[i] CGPointValue];
        c1 = [rightPoints[i-1] CGPointValue];
        CGPoint c2 = [leftPoints[i] CGPointValue];
        CGContextAddCurveToPoint(context, c1.x, c1.y, c2.x, c2.y, p.x, p.y);
    }
    
    c1 = [[rightPoints lastObject] CGPointValue];
    CGContextAddQuadCurveToPoint(context, c1.x, c1.y, endPoint.x, endPoint.y);
    
    CGContextStrokePath(context);
}

- (void)drawStrokeLineInContext:(CGContextRef)context toPoint:(CGPoint)end {
    CGPoint op = startPoint;
    NSValue * val = [points lastObject];
    if (val) {
        op = [val CGPointValue];
    }
    CGContextMoveToPoint(context, op.x, op.y);
    CGContextAddLineToPoint(context, end.x, end.y);
    CGContextStrokePath(context);
}

- (void)reducePoints {
    CGPoint lastPoint = startPoint;
    //CGPoint avgDirection;
    NSMutableArray * newPoints = [[NSMutableArray alloc] init];
    for (NSInteger i=0; i<points.count; i++) {
        CGPoint p = [points[i] CGPointValue];

        CGPoint direction = paNormalize(paSub(p, lastPoint));
        if (i==0) {
            //avgDirection = direction;
            [newPoints addObject:[NSValue valueWithCGPoint:p]];
        } else if (i == points.count - 1) {
            [newPoints addObject:[NSValue valueWithCGPoint:p]];
        } else {
            //avgDirection = paNormalize(paAdd(direction, paScale(avgDirection, 0.2)));
            CGPoint nextPoint = [points[i+1] CGPointValue];
            CGPoint nextDirection = paNormalize(paSub(nextPoint, p));
            
            //CGFloat cross = paCross(direction, avgDirection);
            if (//cross < 0.98 ||
                paCross(direction, nextDirection) < 0.99 ||
                paDistanceBetween(p, lastPoint) > 6.0) {
            //if (YES) {
                [newPoints addObject:[NSValue valueWithCGPoint:p]];
            }
        }
        lastPoint = p;
    }
    NSLog(@"points from %d to %d", points.count, newPoints.count);
    points = newPoints;

}

- (void)generateControlPoints {
    CGPoint lastPoint = startPoint;
    CGFloat r = 0.3;
    
    [self reducePoints];
    leftPoints = [[NSMutableArray alloc] init];
    rightPoints = [[NSMutableArray alloc] init];
    
    NSInteger pointsCount = points.count;
    for (NSInteger i=0; i<pointsCount; i++) {
        CGPoint p = [points[i] CGPointValue];
        
        CGPoint nextPoint = endPoint;
        if (i<points.count - 1) {
            nextPoint = [points[i+1] CGPointValue];
        }
        CGPoint leftCenter = paCenter(lastPoint, p);
        CGPoint rightCenter = paCenter(p, nextPoint);
        CGPoint center = paCenter(leftCenter, rightCenter);
        
        CGPoint leftPos = paAdd(paScale(paSub(leftCenter, center), r), p); // (leftCenter - center) * r + p;
        CGPoint rightPos = paAdd(paScale(paSub(rightCenter, center), r), p); // (rightCenter - center) * r + p;
        
        [leftPoints addObject:[NSValue valueWithCGPoint:leftPos]];
        [rightPoints addObject:[NSValue valueWithCGPoint:rightPos]];
        
        lastPoint = p;
        
    }
}

@end
