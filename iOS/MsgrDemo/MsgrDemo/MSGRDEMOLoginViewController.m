//
//  MSGRDEMOLoginViewController.m
//  MsgrDemo
//
//  Created by Ke Zeng on 13-10-12.
//  Copyright (c) 2013年 msgr. All rights reserved.
//

#import "MSGRDEMOLoginViewController.h"

#import "MSGRMessenger.h"
#import "MSGRAppDelegate.h"

@interface MSGRDEMOLoginViewController ()

@end

@implementation MSGRDEMOLoginViewController {
    NSString * _server;
    NSString * _userId;
    NSString * _password;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Login", nil);

    UIBarButtonItem * submitButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Submit", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(submitLogin)];
    self.navigationItem.rightBarButtonItem = submitButton;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self loadInput];
    [self checkSubmitButton];
    
    UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.view addGestureRecognizer:tapRecognizer];
}

- (UIView *)firstResponseView:(UIView *)v {
    if([v isFirstResponder]) {
        return v;
    }
    for(UIView * view in [v subviews]) {
        UIView * vv = [self firstResponseView:view];
        if (vv) {
            return vv;
        }
    }
    return nil;
}

- (void)backgroundTapped:(UIGestureRecognizer *)recognizer {
    UIView * fv = [self firstResponseView:self.view];
    if (fv) {
        [fv resignFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)saveInput {
    NSMutableDictionary * info = [[NSMutableDictionary alloc] init];
    if ([self textHasContent:_server]) {
        info[@"server"] = _server;
    }
    
    if ([self textHasContent:_userId]) {
        info[@"userId"] = _userId;
    }
    
    if ([self textHasContent:_password]) {
        info[@"password"] = _password;
    }
    [[NSUserDefaults standardUserDefaults] setObject:info forKey:@"im.msgr.msgrdemo.LoginInfo"];
}

- (void)loadInput {
    NSDictionary * info = [[NSUserDefaults standardUserDefaults] objectForKey:@"im.msgr.msgrdemo.LoginInfo"];
    if ([self textHasContent:info[@"server"]]) {
        _server = info[@"server"];
    }
    if ([self textHasContent:info[@"userId"]]) {
        _userId = info[@"userId"];
    }
    
    if ([self textHasContent:info[@"password"]]) {
        _password = info[@"password"];
    }
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    MSGRDEMOLoginCell *cell = (MSGRDEMOLoginCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MSGRDEMOLoginCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    [cell reset];
    cell.delegate = self;
    cell.tag = indexPath.row;
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Server";
            cell.textField.placeholder = @"localhost:3002";
            cell.textField.text = _server;
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"User Id", nil);
            cell.textField.placeholder = NSLocalizedString(@"Such as tom ...", nil);
            cell.textField.text = _userId;
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"Password", nil);
            cell.textField.placeholder = NSLocalizedString(@"Password", nil);
            cell.textField.secureTextEntry = YES;
            cell.textField.text = _password;
            break;
        default:
            break;
    }
    return cell;
}

- (UIView *)resignFirstResponderOfView:(UIView *)view
{
    if (view.isFirstResponder) {
        [view resignFirstResponder];
        return view;
    }
    for (UIView *subView in view.subviews) {
        UIView * v = [self resignFirstResponderOfView:subView];
        if (v) {
            return v;
        }
    }
    return nil;
}

- (void)submitLogin {
    [self resignFirstResponderOfView:self.tableView];
    
    MSGRMessenger * msgr = [MSGRMessenger messenger];
    NSString * server = [_server copy];
    if (_server.length < 7 || ![[_server substringToIndex:7] isEqualToString:@"http://"]) {
        server = [NSString stringWithFormat:@"http://%@", _server];
    }
    msgr.httpURL = [NSURL URLWithString:server];
    __weak typeof(self) wself = self;
    
    [msgr loginWithUserId:_userId password:_password completion:^(NSError * error, NSString * token, NSURL * url) {
        if (!wself) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login error!", nil) message:@"Login failed or network connection failed!" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
                [alert show];
                return;
            }
            
            [wself saveInput];
            [msgr connectWithToken:token connectionURL:url];
            MSGRAppDelegate * app = (MSGRAppDelegate *)[UIApplication sharedApplication].delegate;
            [app showConversationListView];
        });
    }];
}

- (BOOL)textHasContent:(NSString *)text {
    return text != nil && text.length > 0;
}

- (void)cellTextDidChanged:(MSGRDEMOLoginCell *)cell {
    if (cell.tag == 0) {
        _server = cell.textField.text;
    } else if (cell.tag == 1) {
        _userId = cell.textField.text;
    } else if (cell.tag == 2) {
        _password = cell.textField.text;
    }
    [self checkSubmitButton];
}

- (void)checkSubmitButton {
    if ([self textHasContent:_server] && [self textHasContent:_userId] && [self textHasContent:_password]) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

@end
