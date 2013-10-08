//
//  MSGRAppDelegate.h
//  MsgrDemo
//
//  Created by Ke Zeng on 13-10-8.
//  Copyright (c) 2013年 msgr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MSGRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController * viewController;

- (void)showConversationListView;

@end
