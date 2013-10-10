//
//  MSGRMessenger.m
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-9.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRMessenger.h"
#import "MSGRAPIClient.h"
#import "MSGRConvObject.h"
#import "MSGRUserObject.h"
#import "MSGRMsgObject.h"
#import "MSGRConvListViewController.h"
#import "MSGRTalkWithUserViewController.h"
#import "MSGRUtilities.h"
#import "MSGRNavigationController.h"

NSString * kMSGRRequireLogin = @"com.zengke.Msgr.RequireLogin";
static NSString * kUDConnectionInfoKey = @"com.zengke.Msgr.connectionInfo";
static NSString * kUDLoginUser = @"com.zengke.Msgr.loginUser";

@implementation MSGRMessenger {
    NSInteger reconnectingTimes;
}
@synthesize token;
@synthesize tickConnection;
@synthesize baseURL, httpURL;
@synthesize objectStore;
@synthesize convListViewController;
@synthesize loginBlock;

+ (MSGRMessenger *)messenger {
    static MSGRMessenger * _controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _controller = [[MSGRMessenger alloc] init];
    });
    return _controller;
}

//
- (id)init {
    self = [super init];
    if (self) {
        reconnectingTimes = 0;
        NSData * loginUserData = [[NSUserDefaults standardUserDefaults] objectForKey:kUDLoginUser];
        if (loginUserData) {
            self.loginUser = [NSKeyedUnarchiver unarchiveObjectWithData:loginUserData];
        }
        // Parse connectInfo
        NSDictionary * connInfo = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kUDConnectionInfoKey];
        if (connInfo) {
            self.token = connInfo[@"token"];
            self.baseURL =[NSURL URLWithString:connInfo[@"url"]];
        }
        
        NSLog(@"found token %@ baseurl %@", self.token, self.baseURL);
        [self setupObjectStore];
    }
    return self;
}

- (void)setLoginUser:(MSGRUserObject *)loginUser {
    _loginUser = loginUser;
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:_loginUser];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kUDLoginUser];
}

- (void)setupObjectStore {
    if (self.objectStore) {
        [self.objectStore closeStore];
        self.objectStore = nil;
    }
    
    if (self.loginUser) {
        self.objectStore = [[MSGRObjectSQLiteStore alloc] initWithLoginUser:self.loginUser];
    } else {
        self.objectStore = [[MSGRObjectStore alloc] init];
    }
}

- (NSDictionary *)paramsWithSinceId:(NSString*)sinceId maxId:(NSString *)maxId {
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    if (![MSGRUtilities isEmptyText:sinceId]) {
        params[@"since_id"] = sinceId;
    }
    if (![MSGRUtilities isEmptyText:maxId]) {
        params[@"max_id"] = maxId;
    }
    return params;
}

- (MSGRMessengerConnectionState)connectionState {
    if (self.tickConnection == nil) {
        return MSGRMessengerConnectionStateNotConnected;
    } else if (self.tickConnection.loginOK) {
        return MSGRMessengerConnectionStateLoginSuccess;
    } else {
        return MSGRMessengerConnectionStateConnecting;
    }
}

- (void)requireLogin {
    [self closeConnection];
    [self setupObjectStore];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.loginBlock) {
            self.loginBlock();
        }
    });
}

- (void)connect {
    [self connectWithToken:self.token connectionURL:self.baseURL];
}

- (void)connectWithToken:(NSString *)newToken connectionURL:(NSURL *)newURL {
    if (self.connectionState != MSGRMessengerConnectionStateNotConnected) {
        NSLog(@"different state on connect %d", self.connectionState);
        return;
    }
    if (newToken == nil || newURL == nil) {
        NSLog(@"nil token or url");
        [self requireLogin];
        return;        
    }
    
    reconnectingTimes++;

    self.token = newToken;
    self.baseURL = newURL;

    NSLog(@"connect %@ using token %@", self.baseURL, self.token);
    
    // Save token and baseURL
    NSDictionary * connInfo = @{@"token":self.token, @"url":self.baseURL.absoluteString};
    [[NSUserDefaults standardUserDefaults] setObject:connInfo forKey:kUDConnectionInfoKey];
    
    self.tickConnection = [[MSGRTickConnection alloc] init];
    self.tickConnection.delegate = self;
    [self.tickConnection connect];
}

- (void)closeConnection {
    if (self.tickConnection != nil) {
        [self.tickConnection close];
        self.tickConnection = nil;
    }
    [self blockForEachDelegate:^(id<MSGRMessengerDelegate> delegate) {
        [delegate connectionClosed];
    }];
}

- (void)logout {
    [self closeConnection];
    self.token = nil;
    self.baseURL = nil;
    self.loginUser = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUDConnectionInfoKey];
    [self connect];
}

- (void)registerWithUserId:(NSString *)userId screenName:(NSString *)screenName completion:(void (^)(NSString * token, NSURL * url))completion
{
    MSGRAPIClient * client = [[MSGRAPIClient alloc] init];
    [client setSuccessHandler:^(id responseObject) {
        NSLog(@"register %@ got %@", userId, completion);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL * url = [NSURL URLWithString:responseObject[@"url"]];
            NSString * aToken = responseObject[@"token"];
            completion(aToken, url);
        });
    }];
    //NSDictionary * params = @{@"uid":userId};
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    params[@"uid"] = userId;
    if (![MSGRUtilities isEmptyText:screenName]) {
        params[@"screen_name"] = screenName;
    }
    [client get:@"/api/v1/register" params:params];
}

- (void)loginWithUserId:(NSString *)userId password:(NSString *)password completion:(void(^)(NSError * error, NSString * token, NSURL * url))completion
{
    MSGRAPIClient * client = [[MSGRAPIClient alloc] init];
    [client setSuccessHandler:^(id responseObject) {
        NSLog(@"register %@ got %@", userId, completion);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL * url = [NSURL URLWithString:responseObject[@"url"]];
            NSString * aToken = responseObject[@"token"];
            completion(nil, aToken, url);
        });
    }];
    [client setErrorHandler:^(NSError * err) {
        completion(err, nil, nil);
    }];
    //NSDictionary * params = @{@"uid":userId};
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    params[@"user_id"] = userId;
    params[@"password"] = password;
    [client post:@"/auth/login" params:params];
}


- (void)sendText:(NSString *)text toUser:(MSGRUserObject *)user completion:(void(^)(MSGRMsgObject * msg))completion {
    MSGRMsgObject * localMsg = [MSGRMsgObject localMessage];
    localMsg.toUser = user;
    localMsg.msgType = @"text";
    localMsg.content = text;
    localMsg.dateCreated = [NSDate date];
    
    [self.objectStore addMessage:localMsg];
    
    [self blockForEachDelegate:^(id<MSGRMessengerDelegate> delegate) {
        [delegate localMessage:localMsg];
    }];
    
    MSGRAPIClient * client = [[MSGRAPIClient alloc] initWithToken:self.token];
    [client setSuccessHandler:^(id responseObject) {
        MSGRMsgObject * msg = [[MSGRMsgObject alloc] initWithJson:responseObject];
        localMsg.globalId = msg.identifier;
        localMsg.msgState = msg.msgState;
        localMsg.jsonMetadata = msg.jsonMetadata;
        
        [self receivedMsg:localMsg];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(msg);
        });
    }];
    assert(![MSGRUtilities isEmptyText:text]);
    NSDictionary * params= @{@"uid": user.identifier, @"text":text};
    [client post:@"/api/v1/messages/" params:params];
}

- (void)sendImage:(UIImage *)image toUser:(MSGRUserObject *)user completion:(void(^)(MSGRMsgObject * msg))completion {
    MSGRMsgObject * localMsg = [MSGRMsgObject localMessage];
    localMsg.toUser = user;
    localMsg.msgType = @"image";
    localMsg.content = [NSString stringWithFormat:@"%@.jpg", localMsg.identifier];
    localMsg.dateCreated = [NSDate date];
    NSData * imageData = UIImageJPEGRepresentation(image, 0.9);
    [self.objectStore saveData:imageData toAsset:localMsg.content];
    [self.objectStore addMessage:localMsg];
    
    [self blockForEachDelegate:^(id<MSGRMessengerDelegate> delegate) {
        [delegate localMessage:localMsg];
    }];
    
    MSGRAPIClient * client = [[MSGRAPIClient alloc] initWithToken:self.token];
    
    [client setSuccessHandler:^(id responseObject) {
        NSLog(@"response Object %@", responseObject);
        MSGRMsgObject * msg = [[MSGRMsgObject alloc] initWithJson:responseObject];
        localMsg.globalId = msg.identifier;
        localMsg.msgState = msg.msgState;
        localMsg.jsonMetadata = msg.jsonMetadata;
        
        [self receivedMsg:localMsg];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(msg);
        });
    }];
    NSDictionary * params= @{@"uid": user.identifier};
    NSDictionary * files = @{@"image": imageData};
    [client upload:@"/api/v1/messages/" params:params files:files];
}

- (void)sendAudio:(NSData *)audioData duration:(NSTimeInterval)duration toUser:(MSGRUserObject * )user completion:(void(^)(MSGRMsgObject * msg))completion {
    MSGRMsgObject * localMsg = [MSGRMsgObject localMessage];
    localMsg.toUser = user;
    localMsg.msgType = @"audio";
    localMsg.metadata = @{@"duration": @(duration)};
    localMsg.content = [NSString stringWithFormat:@"%@.aac", localMsg.identifier];
    localMsg.dateCreated = [NSDate date];
    [self.objectStore saveData:audioData toAsset:localMsg.content];
    [self.objectStore addMessage:localMsg];
    
    [self blockForEachDelegate:^(id<MSGRMessengerDelegate> delegate) {
        [delegate localMessage:localMsg];
    }];
    
    MSGRAPIClient * client = [[MSGRAPIClient alloc] initWithToken:self.token];
    
    [client setSuccessHandler:^(id responseObject) {
        NSLog(@"response Object %@", responseObject);
        MSGRMsgObject * msg = [[MSGRMsgObject alloc] initWithJson:responseObject];
        localMsg.globalId = msg.identifier;
        localMsg.msgState = msg.msgState;
        localMsg.jsonMetadata = msg.jsonMetadata;
        [self receivedMsg:localMsg];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(msg);
        });
    }];
    NSDictionary * params= @{@"uid": user.identifier, @"duration": @(duration)};
    NSDictionary * files = @{@"audio": audioData};
    [client upload:@"/api/v1/messages/" params:params files:files];
}

- (void)searchUsersByName:(NSString *)name completion:(void(^)(NSArray * users))completion {
    MSGRAPIClient * client = [[MSGRAPIClient alloc] initWithToken:self.token];
    [client setSuccessHandler:^(id responseObject) {
        NSMutableArray * users = [[NSMutableArray alloc] init];
        for (NSDictionary * userInfo in responseObject) {
            MSGRUserObject * user = [[MSGRUserObject alloc] initWithJson:userInfo];
            [users addObject:user];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(users);
        });
    }];
    assert(![MSGRUtilities isEmptyText:name]);
    NSDictionary * params= @{@"name": name};
    [client get:@"/api/v1/usersearch/" params:params];
}

- (UIViewController *)conversationListViewController {
    MSGRConvListViewController * vc = [[MSGRConvListViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController * nav = [[MSGRNavigationController alloc] initWithRootViewController:vc];
    self.convListViewController = vc;
    return nav;
}

#pragma mark - MSGRTickConnectionDelegate
- (void)connection:(MSGRTickConnection *)connection receivedPacket:(id)packet withDirective:(NSString *)directive
{
    NSLog(@"received packet %@ %@", directive, packet);
    if ([directive isEqualToString:@"message comes"]) {
        MSGRMsgObject * msg = [[MSGRMsgObject alloc] initWithJson:packet];
        [self receivedMsg:msg];
    } else if([directive isEqualToString:@"login success"]) {
        self.loginUser = [[MSGRUserObject alloc] initWithJson:packet];
        [self loginSuccess];
    } else if ([directive isEqualToString:@"login failed"]) {
        self.loginUser = nil;
        [self loginFailed];
    } else if ([directive isEqualToString:@"ping"]) {
        [connection sendPacket:@{} directive:@"pong"];
    }
}

- (void)connection:(MSGRTickConnection *)connection error:(NSError *)error {
    [self closeConnection];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self connect];
    });
}

- (void)connectionLost:(MSGRTickConnection *)connection {
    [self closeConnection];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self connect];
    });
}

- (void)loginSuccess {
    [self setupObjectStore];
    reconnectingTimes = 0;
    
    [self blockForEachDelegate:^(id<MSGRMessengerDelegate> delegate) {
        [delegate loginSuccess];
    }];
}

- (void)loginFailed {
    self.loginUser = nil;
    if (reconnectingTimes < 5) {
        [self requireLogin];
    }
}

- (void)connectionEstablished:(MSGRTickConnection *)connection {
    [connection sendPacket:self.token directive:@"login"];
}

- (void)receivedMsg:(MSGRMsgObject *)msg {
    if (msg.isLocal) {
        [self.objectStore saveMessage:msg];
    } else {
        [self.objectStore addMessage:msg];
    }    
    [self blockForEachDelegate:^(id<MSGRMessengerDelegate> delegate) {
        [delegate receivedMessage:msg];
    }];
}

- (void)blockForEachDelegate:(void(^)(id<MSGRMessengerDelegate> delegate))handler {
    if (self.convListViewController) {
        for(id vc in self.convListViewController.navigationController.viewControllers) {
            if ([vc conformsToProtocol:@protocol(MSGRMessengerDelegate)]) {
                handler(vc);                
            }
        }
    }
}

- (void)message:(MSGRMsgObject *)msg gotData:(void (^)(NSData * data))completion {
    if (![msg isImage] && ![msg isAudio]) {
        completion(nil);
        return;
    }
    
    NSData * data = [self.objectStore dataFromAssetPath:[msg assetPath]];
    if (data) {
        NSLog(@"get data from local");
        completion(data);
        return;
    }
    
    NSURL * imageURL = [NSURL URLWithString:msg.content];
    [MSGRAPIClient loadDataFromURL:imageURL completion:^(NSData *data) {
        [self.objectStore saveData:data toAsset:[msg assetPath]];
        completion(data);
    }];
}

- (void)message:(MSGRMsgObject*)msg gotImage:(void(^)(UIImage * image))completion {
    assert([msg isImage]);

    [self message:msg gotData:^(NSData *data) {
        if (data) {
            UIImage * image = [UIImage imageWithData:data];
            completion(image);
        } else {
            completion(nil);
        }
    }];
}


@end
