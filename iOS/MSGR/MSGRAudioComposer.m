//
//  MSGRAudioComposer.m
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-30.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//
#import "MSGRAudioComposer.h"

@interface MSGRAudioComposer ()
@property (nonatomic, retain) AVAudioRecorder * recorder;
@end

@implementation MSGRAudioComposer {
    AVAudioRecorder * _recorder;
    NSString * _savedFileName;
    NSInteger recordState;
    NSTimeInterval recordStartTime;
}
@synthesize recorder = _recorder;

- (void)setupRecorder {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    NSError * aSerror;
        AVAudioSession *session = [AVAudioSession sharedInstance];

        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&aSerror];
        if (aSerror) {
            NSLog(@"set category %@", aSerror);
        }
    });
    
    NSURL *destinationURL = [NSURL fileURLWithPath:self.savedAudioFileName];
    
    NSDictionary *settings = @{AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                               AVSampleRateKey: @(44100.0),
                               //AVLinearPCMBitDepthKey: @(16),
                               //AVEncoderBitRateKey: @(16),
                               AVNumberOfChannelsKey: @(1),
                               //AVEncoderBitRateKey: @(128000),
                               AVEncoderAudioQualityKey: @(AVAudioQualityMedium)
                               };
    NSError * error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:destinationURL settings:settings error:&error];
    if (error) {
        NSLog(@"Setup audio record error %@", error);
        return;
    }
    self.recorder.meteringEnabled = YES;
    self.recorder.delegate = self;
    [self.recorder prepareToRecord];
}

- (NSString *)savedAudioFileName {
    if (!_savedFileName) {
        NSString *tempDir = NSTemporaryDirectory();
        NSString *soundFilePath = [tempDir stringByAppendingPathComponent:@"sound.aac"];
        _savedFileName = soundFilePath;
    }
    return _savedFileName;
}

- (void)startRecording {
    [self setupRecorder];
    [self.recorder recordForDuration:60.0f];
    recordStartTime = [[NSDate date] timeIntervalSince1970];
}

- (void)stopRecording {
    NSLog(@"finished!");
    [self.recorder stop];
}

#pragma mark - AudioRecorder Delegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"recorder finished! %g", recorder.currentTime);
    if (self.delegate) {
        NSTimeInterval duration = [[NSDate date] timeIntervalSince1970] - recordStartTime;
        recordStartTime = -1;
        [self.delegate audioComposer:self savedFileName:self.savedAudioFileName duration:duration];
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    NSLog(@"recording error %@", error);
}
@end
