//
//  MSGRTickConnection.h
//  wehuibao
//
//  Created by Ke Zeng on 13-6-20.
//  Copyright (c) 2013年 Zeng Ke. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MSGRTickConnectionStateNotConnected=0,
    MSGRTickConnectionStateConnecting,
    MSGRTickConnectionStateConnected,
    MSGRTickConnectionStateClosed,
    MSGRTickConnectionStateError
} MSGRTickConnectionState;

@class MSGRTickConnection;
@protocol MSGRTickConnectionDelegate <NSObject>

@optional
- (void)connectionLost:(MSGRTickConnection *)connection;
- (void)connection:(MSGRTickConnection *)connection error:(NSError *)error;

@required
- (void)connectionEstablished:(MSGRTickConnection *)connection;
- (void)connection:(MSGRTickConnection *)connection receivedPacket:(id)packet withDirective:(NSString *)directive;
@end

@interface MSGRTickConnection: NSObject<NSStreamDelegate>

@property (nonatomic) MSGRTickConnectionState state;
@property (nonatomic) BOOL loginOK;
@property (nonatomic, weak) id<MSGRTickConnectionDelegate> delegate;

- (void)connect;
- (void)close;
- (void)sendPacket:(id)packet directive:(NSString *)directive;

@end
