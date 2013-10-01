//
//  MSGRCanvasView.h
//  MSGRPaster
//
//  Created by Ke Zeng on 13-6-25.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MSGRCanvasImageView : UIImageView

@property (nonatomic, retain) UIColor * strokeColor;

- (void)cleanupStrokes;

@end
