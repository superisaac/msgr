//
//  WHAPI.m
//  wehuibao
//
//  Created by 曾科 on 12-10-7.
//  Copyright (c) 2012年 Zeng Ke. All rights reserved.
//

#import "MSGRAPIClient.h"
#import "MSGRMessenger.h"

@implementation MSGRAPIClient {
    NSString * _token;
}

@synthesize token=_token;

@synthesize successHandler, errorHandler;

- (id)initWithToken:(NSString *)aToken {
    self = [self init];
    if (self) {
        _token = aToken;
    }
    return self;
}

- (NSString * )fullPath:(NSString *)path {
    NSURL * baseURL = [MSGRMessenger messenger].httpURL;
    return [NSString stringWithFormat:@"http://%@:%@%@", baseURL.host, baseURL.port, path];
}

+ (NSOperationQueue *)requestQueue {
    static NSOperationQueue * _requestQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _requestQueue = [[NSOperationQueue alloc] init];
        [_requestQueue setMaxConcurrentOperationCount:5];
    });
    return _requestQueue;
}

- (void)requestWithMethod:(NSString*)method path:(NSString *)path params:(NSDictionary *)params {
    NSLog(@"request %@ %@ %@ %@", [self fullPath:path], method, path, params);
    NSMutableString * urlBuffer =[[NSMutableString alloc] init];
    [urlBuffer appendString:[self fullPath:path]];
    
    NSMutableString * queryBuffer = [[NSMutableString alloc] init];
    if (_token) {
        [queryBuffer appendFormat:@"token=%@", _token];
    }

    if(params != nil) {
        for(NSString * key in params) {
            NSString *value = [params objectForKey:key];
            value = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString * pair = [NSString stringWithFormat:@"&%@=%@", key, value, nil];
            [queryBuffer appendString:pair];
        }
    }
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:method];
    if([method isEqualToString:@"GET"]) {
        if(queryBuffer.length > 0 ) {
            [urlBuffer appendString:@"?"];
            [urlBuffer appendString:queryBuffer];
            [queryBuffer setString:@""];
        }
    } else {
        // method is POST
        [request setHTTPBody: [queryBuffer dataUsingEncoding:NSStringEncodingConversionAllowLossy]];
    }
    
    NSURL * url = [NSURL URLWithString:urlBuffer];
    [request setURL:url];
    [request setTimeoutInterval:60.0f];
    [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [NSURLConnection sendAsynchronousRequest:request queue:[[self class] requestQueue] completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error != nil) {
            NSLog(@"Error on requesting %@ %@", path, [error description]);
            if (self.errorHandler) {
                self.errorHandler(errorHandler);
            }
        } else {
            NSError * jsonError;
            id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
            
            NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = [httpResponse statusCode];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (statusCode == 401) {
                    NSLog(@"Need authenticate");
                } else if (self.successHandler){
                    self.successHandler(obj);
                }
            });
        }
    }];
}

// Convenience functions
- (void) get:(NSString *)path params:(NSDictionary *)params {
    [self requestWithMethod:@"GET" path:path params:params];
}

- (void) post:(NSString *)path params:(NSDictionary *)params {
    [self requestWithMethod:@"POST" path:path params:params];
}

- (NSData *)multipartDataWithBoundary:(NSString *)boundary params:(NSDictionary *)params files:(NSDictionary *)files {
    NSData * boundaryData = [boundary dataUsingEncoding:NSASCIIStringEncoding];

    NSMutableData * buffer = [[NSMutableData alloc] init];
    for (NSString * field in [files allKeys]) {
        NSData * fileData = files[field];
        NSLog(@"file length %@ %d", field, fileData.length);
        [buffer appendBytes:"--" length:2];
        [buffer appendData:boundaryData];
        [buffer appendBytes:"\r\n" length:2];
        NSString * header = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"a.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n", field];
        [buffer appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        [buffer appendData:fileData];
        [buffer appendBytes:"\r\n" length:2];
    }
    
    for (NSString * field in [params allKeys]) {
        id value = params[field];
        NSString * pValue = value;
        if (![value isKindOfClass:[NSString class]]) {
            pValue = [value stringValue];
        }        
        [buffer appendBytes:"--" length:2];
        [buffer appendData:boundaryData];
        [buffer appendBytes:"\r\n" length:2];
        NSString * header = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\";\r\n\r\n", field];
        [buffer appendData:[header dataUsingEncoding:NSUTF8StringEncoding]];
        
        [buffer appendData:[pValue dataUsingEncoding:NSASCIIStringEncoding]];
        [buffer appendBytes:"\r\n" length:2];
    }
    [buffer appendBytes:"--" length:2];
    [buffer appendData:boundaryData];
    [buffer appendBytes:"--\r\n" length:4];
    return buffer;
}

- (void)upload:(NSString *)path params:(NSDictionary *)params files:(NSDictionary *)files {
    NSString * boundary = @"----------asdfMSGRPlusLink";
    
    NSLog(@"upload %@ %@ %@", [self fullPath:path], path, params);
    NSMutableString * urlBuffer =[[NSMutableString alloc] init];
    [urlBuffer appendString:[self fullPath:path]];
    
    if (_token) {
        [urlBuffer appendFormat:@"?token=%@", _token];
    }

    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    [request addValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[self multipartDataWithBoundary:boundary params:params files:files]];
    
    NSURL * url = [NSURL URLWithString:urlBuffer];
    [request setURL:url];
    [request setTimeoutInterval:60.0f];
    [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [NSURLConnection sendAsynchronousRequest:request queue:self.requestQueue completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (error != nil) {
            NSLog(@"Error on requesting %@ %@", path, [error description]);
            if (self.errorHandler) {
                self.errorHandler(error);
            }
        } else {
            NSError * jsonError;
            id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
            
            NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = [httpResponse statusCode];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (statusCode == 401) {
                    NSLog(@"Need authenticate");
                } else if (self.successHandler){
                    self.successHandler(obj);
                }
            });
        }
    }];
}

/* + (void)loadImageURL:(NSURL *)url completion:(void(^)(UIImage *))completion
{
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:url];
    [request setTimeoutInterval:60.0f];
    
        [request setCachePolicy:NSURLRequestReturnCacheDataDontLoad];
     NSURLResponse * response = nil;
     NSError * error = nil;
     NSData * data = [NSURLConnection  sendSynchronousRequest:request returningResponse:&response error:&error];
     if (!error) {
     completion([UIImage imageWithData:data]);
     return;
     }

    // Cache failed, load it from web asynchronisely
    [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    
    // Load Image data asynchorizly
    [NSURLConnection sendAsynchronousRequest:request queue:self.requestQueue completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        if (error) {
            NSLog(@"error on loading image %@ %@", url, [error description]);
        } else {
            // load image to UI thread
            UIImage * image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image);
            });
        }
    }];
} */


+ (void)loadDataFromURL:(NSURL *)url completion:(void(^)(NSData * data))completion
{
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:url];
    [request setTimeoutInterval:60.0f];
    
    /*    [request setCachePolicy:NSURLRequestReturnCacheDataDontLoad];
     NSURLResponse * response = nil;
     NSError * error = nil;
     NSData * data = [NSURLConnection  sendSynchronousRequest:request returningResponse:&response error:&error];
     if (!error) {
     completion([UIImage imageWithData:data]);
     return;
     }
     */
    // Cache failed, load it from web asynchronisely
    [request setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
    // Load Image data asynchorizly
    [NSURLConnection sendAsynchronousRequest:request queue:self.requestQueue completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {
        if (error) {
            NSLog(@"error on loading image %@ %@", url, [error description]);
        } else {
            // load image to UI thread
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(data);
            });
            /*UIImage * image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image);
            }); */
        }
    }];
}


@end
