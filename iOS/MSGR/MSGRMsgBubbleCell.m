//
//  MSGRMsgBubbleCell.m
//  AnyTellDemo
//
//  Created by Zeng Ke on 13-7-17.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRMsgBubbleCell.h"
#import "MSGRUserObject.h"
#import "MSGRUtilities.h"
#import "MSGRMessenger.h"
#import <QuartzCore/QuartzCore.h>
 
@implementation MSGRMsgBubbleCell {
    UIImageView * bubble;
    UIView * contentView;
    AVAudioPlayer * _player;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self initView];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

    }
    return self;
}

- (void)dealloc {
    if (_player) {
        _player.delegate = nil;
        _player = nil;
    }
}

+ (CGFloat)cellHeightForMsg:(MSGRMsgObject *)msg {
    CGSize contentSize = [self contentSizeOfMsg:msg];
    return 5 + contentSize.height + 12 + 5;
}

+ (CGSize)sizeOfContent:(NSString *)text {
    return [text sizeWithFont:[UIFont systemFontOfSize:18] constrainedToSize:CGSizeMake(180, 10000) lineBreakMode:NSLineBreakByCharWrapping];
}

+ (NSString *)unknownAlert {
    static NSString * alert = @"Unknown message type, please upgrade to the latest version";
    return alert;
}

+ (CGSize)contentSizeOfMsg:(MSGRMsgObject *)msg {
    if ([msg isText]) {
        return [msg.content sizeWithFont:[UIFont systemFontOfSize:18] constrainedToSize:CGSizeMake(180, 10000) lineBreakMode:NSLineBreakByCharWrapping];
    } else if ([msg isImage]) {
        return CGSizeMake(100, 100);
    } else if ([msg isAudio]) {
        return CGSizeMake(60, 26);
    } else {
        return [[self unknownAlert] sizeWithFont:[UIFont systemFontOfSize:18] constrainedToSize:CGSizeMake(180, 10000) lineBreakMode:NSLineBreakByCharWrapping];
    }
    return CGSizeMake(180, 18);
}

- (void)initView {
    bubble = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 26)];
    bubble.userInteractionEnabled = YES;
    UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bubbleTapped)];
    [bubble addGestureRecognizer:tapRecognizer];
    [self.contentView addSubview:bubble];
}

- (void)resetCell {
    if (contentView) {
        [contentView removeFromSuperview];
        contentView = nil;
    }
    
    if (_player) {
        _player.delegate = nil;
        _player = nil;
    }
}

- (void)bubbleTapped {
    if ([_msg isAudio]) {
        if (_player && _player.playing) {
            NSLog(@"stop");
            [_player stop];
        } else {
            MSGRMessenger * msgr = [MSGRMessenger messenger];
            [msgr message:_msg gotData:^(NSData *data) {
                if (data) {
                    NSError * error;
                    _player = [[AVAudioPlayer alloc] initWithData:data error:&error];
                    if (error) {
                        NSLog(@"dddd %@", error);
                    }
                    _player.volume = 1.0;
                    _player.delegate = self;
                    [_player prepareToPlay];
                    [_player play];
                    NSLog(@"played");
                } else {
                    NSLog(@"no audio data");
                }
            }];
        }
    } else if ([_msg isImage]) {
        MSGRMessenger * msgr = [MSGRMessenger messenger];
        [msgr message:_msg gotImage:^(UIImage *image) {
            
        }];
    }
}


- (UIView *)viewForMsg:(MSGRMsgObject *)msg {
    CGSize contentSize = [[self class] contentSizeOfMsg:msg];
    CGFloat leftOffset = [msg selfSend]?11:29;
    if ([msg isText]) {
        UILabel * contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftOffset, 6, contentSize.width, contentSize.height)];
        if (msg.msgState != MSGRMsgStateDelivered) {
            contentLabel.textColor = [UIColor redColor];
        }
        contentLabel.text = msg.content;
        contentLabel.backgroundColor = [UIColor clearColor];
        contentLabel.numberOfLines = contentSize.height/[UIFont systemFontOfSize:18].lineHeight;
        return contentLabel;
    } else if ([msg isImage]) {
        UIImageView * contentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(leftOffset, 6, contentSize.width, contentSize.height)];
        MSGRMessenger * msgr = [MSGRMessenger messenger];
        [msgr message:msg gotImage:^(UIImage *image){
            contentImageView.image = image;
        }];
        return contentImageView;
    } else if ([msg isAudio]) {
        UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftOffset, 6, contentSize.width, contentSize.height)];
        timeLabel.font = [UIFont systemFontOfSize:16];
        timeLabel.backgroundColor = [UIColor clearColor];
        NSInteger duration = 0;
        if (msg.metadata && msg.metadata[@"duration"]) {
            duration = [msg.metadata[@"duration"] integerValue];
        }
        timeLabel.text = [NSString stringWithFormat:@"🔊 %d\"", duration];
        return timeLabel;
    } else {
        UILabel * contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftOffset, 6, contentSize.width, contentSize.height)];
        if (msg.msgState != MSGRMsgStateDelivered) {
            contentLabel.textColor = [UIColor redColor];
        }
        contentLabel.text = [[self class] unknownAlert];
        contentLabel.numberOfLines = contentSize.height/[UIFont systemFontOfSize:18].lineHeight;
        return contentLabel;
    }
}

- (void)setMsg:(MSGRMsgObject *)msg {
    _msg = msg;
    contentView = [self viewForMsg:msg];
    if (contentView) {
        [bubble addSubview:contentView];
    }
    //contentLabel.text = msg.content;
    CGSize contentSize = [[self class] contentSizeOfMsg:msg];
    CGFloat cellPadding = 40;
    if ([msg selfSend]) {
        UIEdgeInsets edges = UIEdgeInsetsMake(11, 11, 11, 40);
        if ([MSGRUtilities osVersion] >= 6.0) {
            bubble.image = [[UIImage imageNamed:@"MSGRRightBubble"] resizableImageWithCapInsets:edges resizingMode:UIImageResizingModeStretch];
        } else {
            bubble.image = [[UIImage imageNamed:@"MSGRRightBubble"] resizableImageWithCapInsets:edges];
        }
        bubble.frame = CGRectMake(310-(contentSize.width + cellPadding), 5, contentSize.width + cellPadding, contentSize.height + 12);
    } else {
        UIEdgeInsets edges = UIEdgeInsetsMake(11, 40, 11, 11);
        if ([MSGRUtilities osVersion] >= 6.0) {
            bubble.image = [[UIImage imageNamed:@"MSGRLeftBubble"] resizableImageWithCapInsets:edges resizingMode:UIImageResizingModeStretch];
        } else {
            bubble.image = [[UIImage imageNamed:@"MSGRLeftBubble"] resizableImageWithCapInsets:edges];
        }
        bubble.frame = CGRectMake(10, 5, contentSize.width + cellPadding, contentSize.height + 12);
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    player.delegate = nil;
    _player = nil;
}

@end
