//
//  MSGRMessenger.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-9.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSGRUserObject.h"
#import "MSGRMsgObject.h"
#import "MSGRTickConnection.h"
#import "MSGRObjectSQLiteStore.h"
#import "MSGRConvListViewController.h"
#import "MSGRMessengerDelegate.h"

typedef enum {
    MSGRMessengerConnectionStateNotConnected=0,
    MSGRMessengerConnectionStateConnecting,
    MSGRMessengerConnectionStateLoginSuccess
} MSGRMessengerConnectionState;

extern NSString * kMSGRRequireLogin;

@interface MSGRMessenger : NSObject<MSGRTickConnectionDelegate>

@property (nonatomic, strong) void (^loginBlock)();
@property (nonatomic, readonly) MSGRMessengerConnectionState connectionState;
@property (nonatomic, retain) MSGRTickConnection * tickConnection;
@property (nonatomic, retain) MSGRObjectStore * objectStore;
@property (nonatomic, weak) MSGRConvListViewController * convListViewController;

@property (nonatomic, retain) NSURL * baseURL;
@property (nonatomic, retain) NSURL * httpURL;
@property (nonatomic, retain) MSGRUserObject * loginUser;
@property (nonatomic, retain) NSString * token;

+ (MSGRMessenger*)messenger;

- (void)connect;
- (void)connectWithToken:(NSString *)newToken connectionURL:(NSURL *)newURL;
- (void)registerWithUserId:(NSString *)userId screenName:(NSString *)screenName completion:(void (^)(NSString * token, NSURL * url))completion;
- (void)loginWithUserId:(NSString *)userId password:(NSString *)password completion:(void(^)(NSError * error, NSString * token, NSURL * url))completion;

- (void)sendText:(NSString *)text toUser:(MSGRUserObject *)user completion:(void(^)(MSGRMsgObject * msg))completion;
- (void)sendImage:(UIImage *)image toUser:(MSGRUserObject *)user completion:(void(^)(MSGRMsgObject * msg))completion;
- (void)sendAudio:(NSData *)audioData duration:(NSTimeInterval)duration toUser:(MSGRUserObject * )user completion:(void(^)(MSGRMsgObject * msg))completion;

- (void)message:(MSGRMsgObject *)msg gotData:(void (^)(NSData * data))completion;
- (void)message:(MSGRMsgObject*)msg gotImage:(void(^)(UIImage * image))completion;

- (void)searchUsersByName:(NSString *)name completion:(void(^)(NSArray * users))completion;

// View controllers
- (UIViewController *)conversationListViewController;

- (void)logout;

@end
