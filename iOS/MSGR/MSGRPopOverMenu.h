//
//  MSGRPopOverMenuViewController.h
//  MOMAIphone
//
//  Created by Ke Zeng on 13-7-24.
//  Copyright (c) 2013年 Sankuai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MSGRPopOverMenu;
@protocol MSGRPopOverMenuDelegate <NSObject>

@required
- (void)popOverMenu:(MSGRPopOverMenu*)popOverMenu itemSelectedAtIndex:(NSInteger)itemIndex;
@end

@interface MSGRPopOverMenu : UIViewController<UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, retain) UITableView * itemsTableView;
@property (nonatomic) NSInteger tag;
@property (nonatomic, weak) id<MSGRPopOverMenuDelegate> delegate;

- (id)initWithItems:(NSArray *)menuItems;
- (void)showInViewController:(UIViewController*)parentViewController anchorView:(UIView * )aView position:(CGPoint)position;

@end
