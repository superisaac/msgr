//
//  MSGRAudioComposer.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-30.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class MSGRAudioComposer;
@protocol MSGRAudioComposerDelegate <NSObject>

@required
- (void)audioComposer:(MSGRAudioComposer *)composer savedFileName:(NSString*)fileName duration:(NSTimeInterval)duration;
@end

@interface MSGRAudioComposer : NSObject<AVAudioRecorderDelegate>

@property (nonatomic, retain) NSString * savedAudioFileName;
@property (nonatomic, weak) id<MSGRAudioComposerDelegate> delegate;
- (void)startRecording;
- (void)stopRecording;

@end
