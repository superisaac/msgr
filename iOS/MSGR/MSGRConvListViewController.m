//
//  MSGRTalkListViewController.m
//  wehuibao
//
//  Created by Ke Zeng on 13-6-3.
//  Copyright (c) 2013年 Zeng Ke. All rights reserved.
//

#import "MSGRCategories.h"
#import "MSGRConvListViewController.h"
#import "MSGRConvListCell.h"
#import "MSGRUtilities.h"
#import "MSGRSearchBar.h"

#import "MSGRTalkWithUserViewController.h"
#import "MSGRTickConnection.h"
#import "MSGRMessenger.h"


@interface MSGRConvListViewController ()

@end

@implementation MSGRConvListViewController {
    NSArray * conversations;
    NSArray * userSearchResults;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        conversations = @[];
        userSearchResults = @[];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNavigationTitle];
    [self initSearchBar];
    
    UIBarButtonItem * logoutButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logout)];
    self.navigationItem.leftBarButtonItem = logoutButton;

    
    UIBarButtonItem * addConvButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addConvUser)];
    self.navigationItem.rightBarButtonItem = addConvButton;
    //conversations = [Msgr.objectStore conversationList];
}

// for iOS 5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

// For iOS 6
- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)setNavigationTitle {
    MSGRMessenger * msgr = [MSGRMessenger messenger];
    NSString * connectStateDisplay = @"";
    if (msgr.connectionState == MSGRMessengerConnectionStateConnecting) {
        connectStateDisplay = @"(Connecting)";
    } else if (msgr.connectionState == MSGRMessengerConnectionStateNotConnected) {
        connectStateDisplay = @"(Not Connected)";
    }
    self.title = [NSString stringWithFormat:@"%@%@",
                  msgr.loginUser?msgr.loginUser.screenName:@"Anonymous",
                  connectStateDisplay
                  ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshData];
}

- (void)initSearchBar {
    UISearchBar * searchBar = [[MSGRSearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    searchBar.delegate = self;
    
    self.xSearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    self.xSearchDisplayController.searchResultsDataSource = self;
    self.xSearchDisplayController.searchResultsDelegate = self;
    self.xSearchDisplayController.searchBar.placeholder = @"Search users by name";
    self.xSearchDisplayController.delegate = self;
    self.xSearchDisplayController.searchBar.tintColor = [UIColor grayLevelColor:0.92];
}


- (void)refreshData {
    [self setNavigationTitle];
    MSGRMessenger * msgr = [MSGRMessenger messenger];
    conversations = [msgr.objectStore conversationList];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    if (tableView == self.xSearchDisplayController.searchResultsTableView) {
        return userSearchResults.count;
    } else {
        return conversations.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.xSearchDisplayController.searchResultsTableView) {
        return 40;
    } else {
        return [MSGRConvListCell cellHeightForTalk:conversations[indexPath.row]];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.xSearchDisplayController.searchResultsTableView) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchCell"];
        if (cell == nil) {
            cell  = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SearchCell"];
        }
        // Configure the cell...
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        MSGRUserObject * u = userSearchResults[indexPath.row];
        cell.textLabel.text = u.screenName;
        return cell;
        
    } else {
        MSGRConvListCell *cell = (MSGRConvListCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (cell == nil) {
            cell  = [[MSGRConvListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        }
        // Configure the cell...
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.conv = conversations[indexPath.row];
        return cell;
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if (tableView == self.xSearchDisplayController.searchResultsTableView) {
        MSGRUserObject * u = userSearchResults[indexPath.row];
        MSGRMessenger * msgr = [MSGRMessenger messenger];
        if (![u isEqual:msgr.loginUser]) {
            MSGRTalkWithUserViewController * vc = [[MSGRTalkWithUserViewController alloc] init];
            vc.user = u;
            [self.navigationController pushViewController:vc animated:YES];
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self.tableView reloadData];
            });
        } else {
            NSLog(@"");
        }
    } else {
        MSGRConvObject * conv = conversations[indexPath.row];
        MSGRTalkWithUserViewController * vc = [[MSGRTalkWithUserViewController alloc] init];
        vc.user = conv.user;
        [self.navigationController pushViewController:vc animated:YES];
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.tableView reloadData];
        });
    }
}

- (void)cancelTalk {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)logout {
    [[MSGRMessenger messenger] logout];
}

- (void)addConvUser {
    if (self.tableView.tableHeaderView != self.xSearchDisplayController.searchBar) {
        self.tableView.tableHeaderView = self.xSearchDisplayController.searchBar;
    } else {
        self.tableView.tableHeaderView = nil;
    }
}

#pragma mark - Scroll view delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == self.tableView) {
        NSLog(@"scroll view did end dragging %g", scrollView.contentOffset.y);
        if (scrollView.contentOffset.y < -40) {
            NSLog(@"refresh data");
            [self refreshData];
        }
    }
}

#pragma mark - UISearchBarDelegate
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchUsersByName:searchBar.text];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
}

- (void)searchUsersByName:(NSString *)keyword {
    if([MSGRUtilities isEmptyText:keyword]) {
        return;
    }

    MSGRMessenger * msgr = [MSGRMessenger messenger];
    
    [msgr searchUsersByName:keyword completion:^(NSArray *users) {
        userSearchResults = users;
        [self.xSearchDisplayController.searchResultsTableView reloadData];
    }];
}

#pragma mark - Messenger Controller Delegate
- (void)connectionClosed {
    [self setNavigationTitle];
}

- (void)loginSuccess {
    [self setNavigationTitle];
    [self refreshData];
}

- (void)localMessage:(MSGRMsgObject *)msg {
    [self refreshData];
}

- (void)receivedMessage:(MSGRMsgObject *)msg {
    __weak typeof (self) wself = self;
    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!wself) {
            return;
        }
        [wself refreshData];
    });
}


@end
