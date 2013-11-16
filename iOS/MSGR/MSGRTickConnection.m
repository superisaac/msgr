//
//  MSGRTalkConnection.m
//  wehuibao
//
//  Created by Ke Zeng on 13-6-20.
//  Copyright (c) 2013年 Zeng Ke. All rights reserved.
//

#import "MSGRTickConnection.h"
#import "MSGRCategories.h"
#import "MSGRTalkConnectionThread.h"
#import "MSGRMessenger.h"

#define maybe_bridge(x) ((__bridge void *) x)

typedef enum {
    WaitTypeNone = 0,
    WaitTypeTerminator,
    WaitTypeLength
} WaitType;

static const NSInteger kTagPacketResponseHead = 1000;
static const NSInteger kTagPacketLength = 1001;
static const NSInteger kTagPacketBody = 1002;
static const NSInteger kTagPacketTail = 1003;

@implementation MSGRTickConnection {
    dispatch_queue_t _connectionQueue;
    
    NSInputStream * inputStream;
    NSOutputStream * outputStream;
    dispatch_queue_t queue;
    NSMutableData * _readingBuffer;
    NSMutableArray * outputBufferList;
    
    WaitType waitType;
    NSInteger waitingTag;
    NSInteger waitingLength;
    NSData * waitingData;
    
    NSThread * runThread;
    BOOL threadRunning;
    int specific;
}

@synthesize state;
@synthesize delegate;
@synthesize loginOK;

- (id)init {
    self = [super init];
    if (self) {
        
        // Customize
        _connectionQueue = dispatch_queue_create("com.zengke.MsgrWorkingQueue", DISPATCH_QUEUE_SERIAL);
        
        // Going to set a specific on the queue so we can validate we're on the work queue
        dispatch_queue_set_specific(_connectionQueue, &specific, &specific, NULL);
        
        self.state = MSGRTickConnectionStateNotConnected;
        waitType = WaitTypeNone;
    }
    return self;
}

- (void)dealloc {
    inputStream.delegate = nil;
    outputStream.delegate = nil;
    [inputStream close];
    [outputStream close];
}

- (void)connect {
    if (self.state != MSGRTickConnectionStateNotConnected) {
        NSLog(@"Already connected");
        return;
    }
    dispatch_async(_connectionQueue, ^{
        [self doConnect];
    });
}

- (void)doConnect {
    self.state = MSGRTickConnectionStateConnecting;
    _readingBuffer = [[NSMutableData alloc] init];
    waitType = WaitTypeNone;
    outputBufferList = [[NSMutableArray alloc] init];
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    NSURL * baseURL = [MSGRMessenger messenger].baseURL;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)baseURL.host, [baseURL.port integerValue], &readStream, &writeStream);
    inputStream = (__bridge_transfer NSInputStream *)readStream;
    outputStream = (__bridge_transfer NSOutputStream*)writeStream;
     
    inputStream.delegate = self;
    outputStream.delegate = self;
    
    NSRunLoop * networkRunLoop = [MSGRTalkConnectionThread networkRunLoop];
    
    [inputStream scheduleInRunLoop:networkRunLoop forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:networkRunLoop forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
}

- (void)close {
    NSRunLoop * networkRunLoop = [MSGRTalkConnectionThread networkRunLoop];
    [outputStream removeFromRunLoop:networkRunLoop forMode:NSDefaultRunLoopMode];
    [inputStream removeFromRunLoop:networkRunLoop forMode:NSDefaultRunLoopMode];
    inputStream.delegate = nil;
    outputStream.delegate = nil;
    [outputStream close];
    [inputStream close];
    self.state = MSGRTickConnectionStateClosed;
}

- (void)assertOnConnectionQueue;
{
    //assert(dispatch_get_specific((const void*)&specific) == maybe_bridge(_connectionQueue));
    assert(dispatch_get_specific(&specific) == (const void*)&specific);
}

- (void)trySendData {
    [self assertOnConnectionQueue];
    while (outputBufferList.count > 0 && outputStream.hasSpaceAvailable) {
        NSData * packet = outputBufferList[0];
        [outputBufferList removeObjectAtIndex:0];
        NSInteger ret = [outputStream write:packet.bytes maxLength:packet.length];
        if (ret < 0) {
            NSLog(@"Error on sending packet %d", ret);
            break;
        }
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    dispatch_async(_connectionQueue, ^{
        switch (eventCode) {
            case NSStreamEventOpenCompleted:
                if (aStream == inputStream) {
                    self.state = MSGRTickConnectionStateConnected;
                    [self connectionEstablished];
                }
                break;
            case NSStreamEventHasBytesAvailable:
                if (aStream == inputStream) {
                    uint8_t buf[1024];
                    int len = [inputStream read:buf maxLength:1024];
                    if (len > 0) {
                        [self receivedBytes:buf length:len];
                    }
                }
                break;
            case NSStreamEventHasSpaceAvailable:
                if (aStream == outputStream && outputBufferList.count > 0) {
                    [self trySendData];
                }
                break;
            case NSStreamEventErrorOccurred:
                [self close];
                self.state = MSGRTickConnectionStateError;
                [self connectionErrorOnStream:aStream];
                break;
            case NSStreamEventNone:
                NSLog(@"event none!");
                break;
            case NSStreamEventEndEncountered:
                [self close];
                [self connectionClosedOnStream:aStream];
                break;
            default:
                NSLog(@"Unknown event %d for %@", eventCode, aStream);
                break;
        }
    });
}

- (void)receivedBytes:(const uint8_t *)bytes length:(unsigned int)len {
    [_readingBuffer appendBytes:bytes length:len];
    NSInteger offset = 0;
    while(waitType != WaitTypeNone) {

        if (waitType == WaitTypeTerminator) {
            NSInteger pos = [_readingBuffer firstPostionOfData:waitingData offset:offset];
            if (pos > offset) {
                NSData * chunk = [_readingBuffer subdataWithRange:NSMakeRange(offset, pos + waitingData.length - offset)];
                offset = pos + waitingData.length;
                waitType = WaitTypeNone;
                NSInteger tag = waitingTag;
                waitingTag = 0;
                [self receivedData:chunk withTag:tag];
            
            } else {
                break;
            }
        } else if (waitType == WaitTypeLength) {
            if (_readingBuffer.length >= offset + waitingLength) {
                NSData * chunk = [_readingBuffer subdataWithRange:NSMakeRange(offset, waitingLength)];
                offset += waitingLength;
                waitType = WaitTypeNone;
                NSInteger tag = waitingTag;
                waitingTag = 0;
                [self receivedData:chunk withTag:tag];
            } else {
                break;
            }
        }
    }
    if (offset > 0) {
        if (offset == _readingBuffer.length) {
            _readingBuffer = [[NSMutableData alloc] init];
        } else {
            uint8_t * bytes = (uint8_t*)_readingBuffer.bytes;
            _readingBuffer = [NSMutableData dataWithBytes:(bytes + offset) length:(_readingBuffer.length-offset)];
        }
    }
}

- (NSData *)CRLFData {
    static NSData * _data;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _data = [NSData dataWithBytes:"\r\n" length:2];
    });
    return _data;
}

- (NSData *)CRLFCRLFData {
    static NSData * _data;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _data = [NSData dataWithBytes:"\r\n\r\n" length:4];
    });
    return _data;
}

- (void)waitForTerminator:(NSData*)data withTag:(NSInteger)tag {
    waitType = WaitTypeTerminator;
    waitingData = data;
    waitingTag = tag;
}

- (void)waitForLength:(NSInteger)dataLength withTag:(NSInteger)tag {
    waitType = WaitTypeLength;
    waitingLength = dataLength;
    waitingTag = tag;
}

- (void)sendData:(NSData *)data {
    dispatch_async(_connectionQueue, ^{
        [outputBufferList addObject:data];
        [self trySendData];
    });
}

- (void)sendString:(NSString *)str {
    NSData * data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:data];
}

- (void)sendPacket:(id)packet directive:(NSString *)directive {
    NSError * error;
    NSData * packetData = [NSJSONSerialization dataWithJSONObject:@[directive, packet] options:0 error:&error];
    assert(error == nil);
    
    NSMutableData * pac = [[NSMutableData alloc] init];
    char packLength[16];
    sprintf(packLength, "%x\r\n", packetData.length);
    
    [pac appendBytes:packLength length:strlen(packLength)];
    [pac appendData:packetData];
    [pac appendBytes:"\r\n" length:2];
    [self sendData:pac];
}


- (void)connectionClosedOnStream:(NSStream*)stream {
    NSLog(@"connection closed %@", stream);
    self.state = MSGRTickConnectionStateClosed;
    if (stream == inputStream) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(connectionLost:)]) {
                [self.delegate connectionLost:self];
            }
        });
    }
}

- (void)connectionErrorOnStream:(NSStream*)stream {
    NSError * error = [stream streamError];
    NSLog(@"connection error %@ %@", error, stream);
    if (stream == inputStream) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate) {
                [self.delegate connection:self error:error];
            }
        });
    }
}

- (void)connectionEstablished {
    NSLog(@"conn established!");
    [self waitForTerminator:[self CRLFCRLFData] withTag:kTagPacketResponseHead];
    NSURL * baseURL = [MSGRMessenger messenger].baseURL;
    NSString * headerString = [NSString stringWithFormat:@"CONNECT /api/v1/tick HTTP/1.1\r\nHost: %@:%d\r\nTransfer-Encoding: chunked\r\n\r\n", baseURL.host, [baseURL.port integerValue]];
    [self sendString:headerString];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate) {
            [self.delegate connectionEstablished:self];
        }
    });
}

- (void)receivedData:(NSData *)data withTag:(NSInteger)tag {
    if (tag == kTagPacketResponseHead) {
        [self waitForTerminator:[self CRLFData] withTag:kTagPacketLength];
    } else if (tag == kTagPacketLength) {
        NSString * s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSUInteger packetLength = 0;
        NSScanner * scanner = [[NSScanner alloc] initWithString:s];
        [scanner setScanLocation:0];
        [scanner scanHexInt:&packetLength];
        [self waitForLength:packetLength withTag:kTagPacketBody];
    } else  if(tag == kTagPacketBody){
        [self waitForLength:2 withTag:kTagPacketTail];
        NSError * error;
        id chunk = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        assert(error == nil);
        assert([chunk isKindOfClass:[NSArray class]]);
        NSString * directive = chunk[0];
        id body = chunk[1];
        [self receivedPacket:body withDirective:directive];
    } else if (tag == kTagPacketTail){
        [self waitForTerminator:[self CRLFData] withTag:kTagPacketLength];
    }
}

- (void)receivedPacket:(id)packet withDirective:(NSString *)directive {
    if ([directive isEqualToString:@"login success"]) {
        self.loginOK = YES;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate) {
            [self.delegate connection:self receivedPacket:packet withDirective:directive];
        }
    });
}

@end
