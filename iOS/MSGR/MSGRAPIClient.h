//
//  WHAPI.h
//  wehuibao
//
//  Created by 曾科 on 12-10-7.
//  Copyright (c) 2012年 Zeng Ke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MSGRAPIClient: NSObject

@property (nonatomic, strong) void(^successHandler)(id responseObject);
@property (nonatomic, strong) void(^errorHandler)(NSError * error);
@property (nonatomic, readonly) NSOperationQueue * requestQueue;
@property (nonatomic, retain) NSString * token;

+ (void)loadDataFromURL:(NSURL *)url completion:(void(^)(NSData * data))completion;

- (id)initWithToken:(NSString *)aToken;
- (void)requestWithMethod:(NSString*)method path:(NSString *)path params:(NSDictionary *)params;
// Convenience functions
- (void)get:(NSString *)path params:(NSDictionary *)params;
- (void)post:(NSString *)path params:(NSDictionary *)params;
- (void)upload:(NSString *)path params:(NSDictionary *)params files:(NSDictionary *)files;

@end
