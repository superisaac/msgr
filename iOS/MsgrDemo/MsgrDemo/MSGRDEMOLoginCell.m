//
//  MSGRDEMOLoginCell.m
//  MsgrDemo
//
//  Created by Ke Zeng on 13-10-12.
//  Copyright (c) 2013年 msgr. All rights reserved.
//

#import "MSGRDEMOLoginCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation MSGRDEMOLoginCell
@synthesize textField;
@synthesize delegate;
@synthesize tag;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self initView];
    }
    return self;
}

- (void)dealloc {
    if (self.textField.delegate) {
        self.textField.delegate = nil;
        [self.textField removeTarget:self action:@selector(textDidChanged:) forControlEvents:UIControlEventEditingChanged];
    }
    if (self.delegate) {
        self.delegate = nil;
    }
}

- (void)reset {
    self.delegate = nil;
    self.tag = 0;
    self.textField.keyboardType = UIKeyboardTypeDefault;
    self.textField.textColor = [UIColor blackColor];
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.text = @"";
    self.textField.secureTextEntry = NO;
    self.textField.placeholder = @"";
}

- (void)initView {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(self.bounds.size.width - 210, 12, 180, 32)];
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 32)];
    self.textField.leftView = paddingView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    self.textField.textColor = [UIColor blackColor];
    self.textField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    self.textField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.textField.layer.borderWidth = 1.0;
    self.textField.delegate = self;

    self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.textField.backgroundColor = [UIColor clearColor];
    [self addSubview:self.textField];
    
    [self.textField addTarget:self action:@selector(textDidChanged:) forControlEvents:UIControlEventEditingChanged];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)textDidChanged:(UITextField *)textField {
    if (self.delegate) {
        [self.delegate cellTextDidChanged:self];
    }
}

@end
