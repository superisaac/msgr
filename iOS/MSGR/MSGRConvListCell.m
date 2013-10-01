//
//  MSGRTalkListCell.m
//  wehuibao
//
//  Created by Ke Zeng on 13-6-3.
//  Copyright (c) 2013年 Zeng Ke. All rights reserved.
//

#import "MSGRConvListCell.h"
#import "MSGRUserObject.h"
#import "MSGRMsgObject.h"
#import <QuartzCore/QuartzCore.h>

@implementation MSGRConvListCell {
    UILabel * nameLabel;
    UILabel * unreadCountLabel;
    UILabel * contentLabel;
    
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self initView];
    }
    return self;
}

+ (CGFloat)cellHeightForTalk:(MSGRConvObject * )talk {
    return 48;
}

- (void)initView {
    self.imageView.image = [UIImage imageNamed:@"MSGRDefaultContact"];
    
    nameLabel = [[UILabel alloc] init];
    nameLabel.frame = CGRectMake(46, 8, 230, 16);
    nameLabel.font = [UIFont boldSystemFontOfSize:16];
    nameLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:nameLabel];
    
    contentLabel = [[UILabel alloc] init];
    contentLabel.backgroundColor = [UIColor clearColor];
    contentLabel.frame = CGRectMake(46, 26, 230, 18);
    contentLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:contentLabel];
    
    CGRect imageFrame = self.imageView.frame;
    CGFloat ucSize = 16;
    unreadCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageFrame.origin.x + imageFrame.size.width - ucSize-15, imageFrame.origin.y+5, ucSize, ucSize)];
    unreadCountLabel.backgroundColor = [UIColor redColor];
    unreadCountLabel.textColor = [UIColor whiteColor];
    unreadCountLabel.layer.cornerRadius = ucSize/2.0f;
    unreadCountLabel.textAlignment = NSTextAlignmentCenter;
    unreadCountLabel.font = [UIFont boldSystemFontOfSize:13];
    unreadCountLabel.text = @"0";
    unreadCountLabel.contentMode = UIControlContentVerticalAlignmentCenter;
    unreadCountLabel.hidden = YES;
    [self.imageView addSubview:unreadCountLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect imageFrame =  CGRectMake(5, 5, 37, 37);
    self.imageView.frame = imageFrame;
    CGFloat ucSize = 16;
    unreadCountLabel.frame = CGRectMake(imageFrame.origin.x + imageFrame.size.width - ucSize - 2, 2, ucSize, ucSize);
}

- (void)setConv:(MSGRConvObject *)conv {
    _conv = conv;
    nameLabel.text = conv.user.screenName;
    contentLabel.text = [conv.lastMessage convTitle];
    if (conv.numberOfUnread > 0) {
        unreadCountLabel.text = [NSString stringWithFormat:@"%d", conv.numberOfUnread];
        unreadCountLabel.hidden = NO;
    } else {
        unreadCountLabel.hidden = YES;
    }
}

@end
