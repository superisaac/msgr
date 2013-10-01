//
//  MSGRTalkWithUserViewController.h
//  wehuibao
//
//  Created by Ke Zeng on 13-6-3.
//  Copyright (c) 2013年 Zeng Ke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSGRPopOverMenu.h"
#import "MSGRMessengerDelegate.h"
#import "MSGRAudioComposer.h"

@class MSGRConvObject;
@class MSGRUserObject;
@class MSGRMsgObject;
@interface MSGRTalkWithUserViewController : UITableViewController<UITextFieldDelegate, UIActionSheetDelegate, MSGRPopOverMenuDelegate, MSGRMessengerDelegate, MSGRAudioComposerDelegate>

@property (nonatomic, retain) MSGRUserObject * user;
@property (nonatomic, retain) NSString * editingText;

@end
