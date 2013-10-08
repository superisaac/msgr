//
//  MSGRLoginViewController.m
//  MsgrDemo
//
//  Created by Ke Zeng on 13-10-8.
//  Copyright (c) 2013年 msgr. All rights reserved.
//

#import "MSGRLoginViewController.h"

@interface MSGRLoginViewController ()

@end

@implementation MSGRLoginViewController {
    UITextField * _userIdField;
    UITextField * _passwordField;
}
@synthesize userIdField=_userIdField;
@synthesize passwordField=_passwordField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView {
    [super loadView];
    CGFloat g = 0.93;
    self.view.backgroundColor = [UIColor colorWithRed:g green:g blue:g alpha:1.0];
    
    _userIdField = [[UITextField alloc] initWithFrame:CGRectMake(60, 70, 200, 30)];
    _userIdField.placeholder = @"User ID";
    _userIdField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _userIdField.backgroundColor = [UIColor whiteColor];
    _userIdField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _userIdField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:_userIdField];
    
    _passwordField = [[UITextField alloc] initWithFrame:CGRectMake(60, 115, 200, 30)];
    _passwordField.placeholder = @"Screen name";
    _passwordField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _passwordField.backgroundColor = [UIColor whiteColor];
    _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _passwordField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:_passwordField];
    
    UIButton * loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    loginButton.frame = CGRectMake(60, 165, 200, 30);
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [loginButton addTarget:self action:@selector(submitLogin) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:loginButton];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)submitLogin {
    
}
@end
