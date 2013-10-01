//
//  MSGRMsgBubbleCell.h
//  AnyTellDemo
//
//  Created by Zeng Ke on 13-7-17.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSGRMsgObject.h"
#import <AVFoundation/AVFoundation.h>

@interface MSGRMsgBubbleCell : UITableViewCell<AVAudioPlayerDelegate>

@property (nonatomic, retain) MSGRMsgObject * msg;

+ (CGFloat)cellHeightForMsg:(MSGRMsgObject *)msg;
- (void)resetCell;

@end
