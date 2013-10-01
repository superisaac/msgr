//
//  MSGRTalkListViewController.h
//  wehuibao
//
//  Created by Ke Zeng on 13-6-3.
//  Copyright (c) 2013年 Zeng Ke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSGRMessengerDelegate.h"

@class MSGRMsgObject;
@interface MSGRConvListViewController : UITableViewController<UISearchBarDelegate, UISearchDisplayDelegate, MSGRMessengerDelegate>

@property (nonatomic, retain) UISearchDisplayController * xSearchDisplayController;

@end
