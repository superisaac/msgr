//
//  MSGRDEMOLoginCell.h
//  MsgrDemo
//
//  Created by Ke Zeng on 13-10-12.
//  Copyright (c) 2013年 msgr. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MSGRDEMOLoginCell;

@protocol MSGRDEMOLoginCellDelegate <NSObject>
@required
- (void)cellTextDidChanged:(MSGRDEMOLoginCell*)cell;
@end

@interface MSGRDEMOLoginCell : UITableViewCell<UITextFieldDelegate>

@property (nonatomic) NSInteger tag;
@property (nonatomic, retain) UITextField * textField;
@property (nonatomic, weak) id<MSGRDEMOLoginCellDelegate> delegate;

- (void)reset;

@end
