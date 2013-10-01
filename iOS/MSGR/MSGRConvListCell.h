//
//  MSGRTalkListCell.h
//  wehuibao
//
//  Created by Ke Zeng on 13-6-3.
//  Copyright (c) 2013年 Zeng Ke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSGRConvObject.h"

@interface MSGRConvListCell : UITableViewCell

@property (nonatomic, retain) MSGRConvObject * conv;

+ (CGFloat)cellHeightForTalk:(MSGRConvObject * )talk;
@end
