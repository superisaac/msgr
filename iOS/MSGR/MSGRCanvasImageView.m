//
//  MSGRCanvasView.m
//  MSGRPaster
//
//  Created by Ke Zeng on 13-6-25.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRCanvasImageView.h"
#import "MSGRStroke.h"

@interface TouchTracker: NSObject
@property (nonatomic, retain) UITouch * touch;
@property (nonatomic, retain) MSGRStroke * stroke;
@end

@implementation TouchTracker
@synthesize touch, stroke;
@end

@implementation MSGRCanvasImageView {
    //MSGRStroke * currentStroke;
    UIImage * oldImage;
    NSMutableArray * strokes;
    NSMutableArray * touchTrackers;
}
@synthesize strokeColor;

//- (id)initWithFrame:(CGRect)frame
- (id) init
{
    self = [super init];
    if (self) {
        // Initialization code
        self.contentMode  = UIViewContentModeScaleAspectFit;
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin];
        [self setUserInteractionEnabled:YES];
        self.multipleTouchEnabled = YES;
        strokes = [[NSMutableArray alloc] init];
        touchTrackers = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:0.831373 alpha:1.0];
        self.image = [UIImage imageNamed:@"canvasBackground"];
        self.strokeColor = [UIColor blueColor];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{

}

- (void)removeTrackingTouch:(UITouch *)touch {
    for (NSInteger i=0;i<touchTrackers.count;i++) {
        TouchTracker * tracker = touchTrackers[i];
        if (tracker.touch == touch) {
            [touchTrackers removeObjectAtIndex:i];
            break;
        }
    }
}

- (MSGRStroke *)strokeForTouch:(UITouch *)touch {
    for (NSInteger i=0;i<touchTrackers.count;i++) {
        TouchTracker * tracker = touchTrackers[i];
        if (tracker.touch == touch) {
            return tracker.stroke;
        }
    }
    return nil;
}

- (void)repaintStrokes {
    [self drawInContext:^(CGContextRef context) {
        for (MSGRStroke * stroke in strokes) {
            [stroke drawCurveStrokeInContext:context];
        }
    }];
}

- (void)drawInContext:(void(^)(CGContextRef context))drawBlock {
    UIGraphicsBeginImageContext(self.frame.size);
    [self.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor);

    CGContextSetLineWidth(context, 2.0f);
    CGContextSetShouldAntialias(context, TRUE);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    drawBlock(context);
    self.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

#pragma mark - touches
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"touches begin");
    for (UITouch * touch in touches) {
        CGPoint p = [touch locationInView:self];
        oldImage = self.image;
        MSGRStroke * stroke = [[MSGRStroke alloc] initWithPoint:p];
        stroke.strokeColor = self.strokeColor;
        TouchTracker * tracker = [[TouchTracker alloc] init];
        tracker.stroke = stroke;
        tracker.touch = touch;
        
        [touchTrackers addObject:tracker];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch * touch in touches) {
        MSGRStroke * stroke = [self strokeForTouch:touch];
        CGPoint p = [touch locationInView:self];
        [self drawInContext:^(CGContextRef context) {
            [stroke drawStrokeLineInContext:context toPoint:p];
        }];
        [stroke addPoint:p];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for(UITouch * touch in touches) {
        MSGRStroke * currentStroke = [self strokeForTouch:touch];
        
        CGPoint p = [touch locationInView:self];
        [self drawInContext:^(CGContextRef context) {
            [currentStroke drawStrokeLineInContext:context toPoint:p];
        }];
        [self removeTrackingTouch:touch];
        [currentStroke setEndPoint:p];
        [currentStroke generateControlPoints];
        [strokes addObject:currentStroke];
    }
    if (touchTrackers.count == 0) {
        self.image = oldImage;
        [self repaintStrokes];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)cleanupStrokes {
    strokes = [[NSMutableArray alloc] init];
    self.image = [UIImage imageNamed:@"canvasBackground"];
}

@end
