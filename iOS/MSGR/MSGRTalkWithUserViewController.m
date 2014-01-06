//
//  MSGRTalkWithUserViewController.m
//  wehuibao
//
//  Created by Ke Zeng on 13-6-3.
//  Copyright (c) 2013年 Zeng Ke. All rights reserved.
//

#import "MSGRTalkWithUserViewController.h"
#import "MSGRCategories.h"
#import "MSGRMsgObject.h"
#import "MSGRUserObject.h"
#import <QuartzCore/QuartzCore.h>
#import "MSGRMessenger.h"
#import "MSGRUtilities.h"
#import "MSGRMsgBubbleCell.h"
#import "MSGRPopOverMenu.h"
#import "MSGRImageComposeViewController.h"

@interface MSGRMsgSection : NSObject

@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSMutableArray * messageList;
@end

@implementation MSGRMsgSection
@synthesize label;
@synthesize messageList;
@end

@interface MSGRTalkWithUserViewController ()

@end

@implementation MSGRTalkWithUserViewController {
    NSMutableArray * messageSectionList;
    UIToolbar * inputAccessory;
    UITextField * textInput;
    BOOL _keyboardVisible;
    BOOL _inputIsAudio;
    MSGRPopOverMenu * _composerMethodsMenu;
    MSGRAudioComposer * _audioComposer;
    AVAudioPlayer * _player;
}
@synthesize user;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        _inputIsAudio = NO;
    }
    return self;
}

- (void)dealloc {
    if (_audioComposer) {
        _audioComposer.delegate = nil;
    }
    UITextField * textField = [self accessoryTextField];
    if (textField) {
        textField.delegate = nil;
        [textField removeTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
}

- (NSInteger)countOfExistingMsgs {
    NSInteger count = 0;
    for(MSGRMsgSection * sec in messageSectionList) {
        count += sec.messageList.count;
    }
    return count;
}

- (void)sectionListOfMessages:(NSArray *)messageList {
    MSGRMsgSection * msgSect = nil;
    messageSectionList = [[NSMutableArray alloc] init];
    for (MSGRMsgObject * msg in messageList) {
        NSString * timeLabel = [MSGRUtilities labelOfDate:msg.dateCreated];
        if (msgSect == nil) {
            msgSect = [[MSGRMsgSection alloc] init];
            msgSect.label = timeLabel;
            msgSect.messageList  = [[NSMutableArray alloc] initWithObjects:msg, nil];
        } else if ([msgSect.label isEqualToString:timeLabel]){
            [msgSect.messageList addObject:msg];
        } else {
            [messageSectionList addObject:msgSect];
            msgSect = [[MSGRMsgSection alloc] init];
            msgSect.label = timeLabel;
            msgSect.messageList  = [[NSMutableArray alloc] initWithObjects:msg, nil];
        }
    }
    if (msgSect) {
        [messageSectionList addObject:msgSect];
    }
}

- (void)addMessageToSectionList:(MSGRMsgObject *)msg {
    NSString * timeLabel = [MSGRUtilities labelOfDate:msg.dateCreated];
    MSGRMsgSection * msgSect = [messageSectionList lastObject];
    if (msgSect == nil || ![msgSect.label isEqualToString:timeLabel]) {
        msgSect = [[MSGRMsgSection alloc] init];
        msgSect.label = timeLabel;
        msgSect.messageList  = [[NSMutableArray alloc] initWithObjects:msg, nil];
        [messageSectionList addObject:msgSect];
    } else {
        [msgSect.messageList addObject:msg];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.user.screenName;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self resetToolbarItems];
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(moreData) forControlEvents:UIControlEventValueChanged];
    
    [self refreshData];
}

- (void)loadView {
    [super loadView];
    UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(restoreInput:)];
    [self.tableView addGestureRecognizer:recognizer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [self scrollToBottomAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self scrollToBottomAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self resignInput];
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

- (void)refreshData {
    NSInteger msgCount = [self countOfExistingMsgs];
    msgCount = MAX(10, msgCount);
    NSArray * arr = [[MSGRMessenger messenger].objectStore messageListOfUser:self.user range:NSMakeRange(0, msgCount)];
    if (arr && arr.count > 0) {
        [self sectionListOfMessages:[arr reversedArray]];
    }
    [self.tableView reloadData];
    [self scrollToBottomAnimated:NO];
}

- (void)moreData {
    NSInteger msgCount = [self countOfExistingMsgs];
    NSArray * arr = [[MSGRMessenger messenger].objectStore messageListOfUser:self.user range:NSMakeRange(0, msgCount + 10)];
    if (arr && arr.count > msgCount) {
        [self sectionListOfMessages:[arr reversedArray]];
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
    } else {
        [self.refreshControl endRefreshing];
        [self.refreshControl removeFromSuperview];
    }
}

- (void)setEditingText:(NSString *)editingText from:(UIView *)fromView {
    _editingText = editingText;
    if (textInput) {
        if (textInput != fromView) {
            textInput.text = editingText;
        }
        UITextField * textField = [self accessoryTextField];
        if (textField && textField != fromView) {
            textField.text = editingText;
        }
    }
}

- (UIView *)textInputAccessoryView {
    if (inputAccessory) {
        return inputAccessory;
    }
    inputAccessory = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    NSString * typeSwitchImageName = _inputIsAudio?@"MSGRText":@"MSGRMicrophone";
    
    UIBarButtonItem * typeSwitch = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:typeSwitchImageName] style:UIBarButtonItemStylePlain target:self action:@selector(toggleAudio)];
    
    UITextField * input = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 240, 30)];
    input.backgroundColor = [UIColor whiteColor];
    input.tag = 1101;
    input.delegate = self;
    [input addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    input.layer.borderWidth = 1;
    input.layer.borderColor = [UIColor grayColor].CGColor;
    input.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    UIBarButtonItem * itemText = [[UIBarButtonItem alloc] initWithCustomView:input];
    
    UIBarButtonItem * space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    
    UIBarButtonItem * space1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem * send = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(resignInput)];
    
    inputAccessory.items = @[typeSwitch, space, itemText, space1, send];
    return inputAccessory;
}

- (void)resetToolbarItems {
    NSString * typeSwitchImageName = _inputIsAudio?@"MSGRText":@"MSGRMicrophone";
    UIBarButtonItem * typeSwitch = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:typeSwitchImageName] style:UIBarButtonItemStylePlain target:self action:@selector(toggleAudio)];

    UIBarButtonItem * space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem * itemText;
    
    if (!_inputIsAudio) {
        textInput = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 240, 32)];
        textInput.inputAccessoryView = [self textInputAccessoryView];
        textInput.text = _editingText;
        textInput.backgroundColor = [UIColor whiteColor];
        textInput.layer.borderWidth = 1;
        textInput.layer.borderColor = [UIColor grayColor].CGColor;
        textInput.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        itemText = [[UIBarButtonItem alloc] initWithCustomView:textInput];
    } else {
        UIButton * audioButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        audioButton.frame = CGRectMake(0, 0, 240, 32);
        [audioButton setTitle:NSLocalizedString(@"Press to record audio", nil) forState:UIControlStateNormal];
        [audioButton setTitle:NSLocalizedString(@"Press to record audio", nil) forState:UIControlStateHighlighted];
        [audioButton addTarget:self action:@selector(audioButtonDown) forControlEvents:UIControlEventTouchDown];
        [audioButton addTarget:self action:@selector(audioButtonUp) forControlEvents:UIControlEventTouchUpInside];
        [audioButton addTarget:self action:@selector(audioButtonUp) forControlEvents:UIControlEventTouchUpOutside];
        itemText = [[UIBarButtonItem alloc] initWithCustomView:audioButton];
    }
    UIBarButtonItem * space1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIBarButtonItem * send = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showMethods:)];
    
    self.toolbarItems = @[typeSwitch, space, itemText, space1, send];
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
    return messageSectionList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    MSGRMsgSection * msgSect = messageSectionList[section];
    return msgSect.messageList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    MSGRMsgSection * msgSect = messageSectionList[section];
    return msgSect.label;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel * timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    timeLabel.backgroundColor = [UIColor clearColor];
    timeLabel.textColor = [UIColor lightGrayColor];
    timeLabel.font = [UIFont systemFontOfSize:16];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    
    MSGRMsgSection * msgSect = messageSectionList[section];
    timeLabel.text = msgSect.label;
    return timeLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    MSGRMsgSection * msgSect = messageSectionList[indexPath.section];
    MSGRMsgObject * msg = msgSect.messageList[indexPath.row];
    return [MSGRMsgBubbleCell cellHeightForMsg:msg];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    MSGRMsgBubbleCell * cell = (MSGRMsgBubbleCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell) {
        cell = [[MSGRMsgBubbleCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    [cell resetCell];
    
    // Configure the cell...
    MSGRMsgSection * msgSect = messageSectionList[indexPath.section];
    MSGRMsgObject * msg = msgSect.messageList[indexPath.row];
    cell.msg = msg;
    return cell;
}

- (void)resignFirstResponderForView:(UIView *)view
{
    if (view.isFirstResponder) {
        [view resignFirstResponder];
    } else {
        for (UIView *subView in view.subviews) {
            if(subView.isFirstResponder) {
                [subView resignFirstResponder];
                break;
            }
        }
    }
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
/*    MSGRMsgSection * msgSect = messageSectionList[indexPath.section];
    MSGRMsgObject * msg = msgSect.messageList[indexPath.row]; */
}

#pragma mark - keyboard events
- (UITextField *)accessoryTextField {
    if (textInput == nil) {
        return nil;
    }
    UITextField * textField = (UITextField *)[textInput.inputAccessoryView viewWithTag:1101];
    return textField;
}

- (void)keyboardDidShow:(NSNotification *)notification {
    UITextField * textField = [self accessoryTextField];
    if (textField && !_keyboardVisible) {
        [textField becomeFirstResponder];
    }
    _keyboardVisible = YES;
    [self scrollToBottomAnimated:YES];
}

-(void)keyboardWillShow:(NSNotification *)notification {
    
}


- (void)keyboardDidHide:(NSNotification *)notification {
    _keyboardVisible = NO;
    //get the size of the keyboard.
    [self scrollToBottomAnimated:YES];
}

//method to move the view up/down whenever the keyboard is shown/dismissed
-(void)scrollToBottomAnimated:(BOOL)animated
{
   //if (messageList.count > 0) {
    NSInteger numberOfSections = [self numberOfSectionsInTableView:self.tableView];
    if (numberOfSections > 0) {
        NSInteger numRows = [self tableView:self.tableView numberOfRowsInSection:(numberOfSections-1)];
        if (numRows > 0) {
            NSIndexPath * indexPath = [NSIndexPath indexPathForRow:(numRows - 1) inSection:(numberOfSections-1)];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:animated];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendTextAsync];
    return NO;
}

- (void)textFieldDidChange:(UITextField *)textField {
    [self setEditingText:textField.text from:textField];
}

- (void)sendTextAsync {
    [self resignInput];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self sendText];
    });    
}

- (void)sendText {
    if (textInput.text == nil || textInput.text.length == 0) {
        NSLog(@"empty text");
        return;
    }

    
    [[MSGRMessenger messenger] sendText:textInput.text toUser:self.user completion:^(MSGRMsgObject *msg) {
        //[self refreshData];
    }];
    [self setEditingText:@"" from:nil];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    textInput.text = textField.text;
}



#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
}

#pragma mark - Actions
- (void)moreInput {
    UIActionSheet * sheet = [[UIActionSheet alloc] initWithTitle:@"Message" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Audio message", @"Take a photo", @"Album", nil];
    [sheet showInView:self.navigationController.view];
}

- (void)toggleAudio {
    _inputIsAudio = !_inputIsAudio;
    [self resignInput];
}

- (void)audioButtonDown {
    if (_audioComposer == nil) {
        _audioComposer = [[MSGRAudioComposer alloc] init];
        _audioComposer.delegate = self;
    }
    [_audioComposer startRecording];
}

- (void)audioButtonUp {
    if (_audioComposer) {
        [_audioComposer stopRecording];
    }
}

- (void)audioComposer:(MSGRAudioComposer *)composer savedFileName:(NSString *)fileName duration:(NSTimeInterval)duration {
    MSGRMessenger * msgr = [MSGRMessenger messenger];
    NSData * audioData = [NSData dataWithContentsOfFile:fileName];
    [msgr sendAudio:audioData duration:duration toUser:self.user completion:^(MSGRMsgObject *msg) {
        NSLog(@"aaa");
        //[self refreshData];
    }];
    _audioComposer.delegate = nil;
    _audioComposer = nil;
}

- (void)resignInput {
    [self resignFirstResponderForView:textInput.inputAccessoryView];
    [self resetToolbarItems];
}


- (void)showMethods:(UIBarButtonItem *)barItem {
    [self resignInput];
    _composerMethodsMenu = [[MSGRPopOverMenu alloc] initWithItems:@[NSLocalizedString(@"Camera", nil),
                                                                   NSLocalizedString(@"Album", nil),
                                                                   NSLocalizedString(@"Doodle", nil)]];
    _composerMethodsMenu.delegate = self;
    CGPoint origin = [self.navigationController.toolbar originInView:self.navigationController.view];
    origin = CGPointMake(origin.x + self.navigationController.toolbar.frame.size.width, origin.y);
    [_composerMethodsMenu showInViewController:self.navigationController anchorView:self.navigationController.toolbar position:CGPointMake(1.0, 0)];
}

- (void)popOverMenu:(MSGRPopOverMenu *)popOverMenu itemSelectedAtIndex:(NSInteger)itemIndex {
    _composerMethodsMenu = nil;
    BOOL imageType = NO;
    MSGRImageComposeSourceType sourceType = MSGRImageComposeSourceDoodle;
    if (itemIndex == 0) {
        /*MSGRMessenger * Msgr = [MSGRMessenger sharedController];
        [Msgr sendImage:[UIImage imageNamed:@"atDefaultContact"] toUser:self.user completion:^(MSGRMsgObject *msg) {
            [self refreshData];
        }];
        return; */
        
        // Camera
        sourceType = MSGRImageComposeSourceCamera;
        imageType = YES;
    } else if (itemIndex == 1) {
        // PhotoLibrary
        sourceType = MSGRImageComposeSourcePhotoLibrary;
        imageType = YES;
    } else if (itemIndex == 2) {
        sourceType = MSGRImageComposeSourceDoodle;
        imageType = YES;
    }
    if (imageType) {
        MSGRImageComposeViewController * vc = [[MSGRImageComposeViewController alloc] initWithImageSelected:^(UIImage * image) {
            if (image) {
                MSGRMessenger * Msgr = [MSGRMessenger messenger];
                [Msgr sendImage:image toUser:self.user completion:^(MSGRMsgObject *msg) {
                    //[self refreshData];
                }];
            }
        }];
        vc.sourceType = sourceType;
        UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:NO completion:nil];
    }
}

#pragma mark - messenger delegate
- (void)connectionClosed {
    
}
- (void)loginSuccess {

}
- (void)localMessage:(MSGRMsgObject *)msg {
    [self addMessageToSectionList:msg];
    [self.tableView reloadData];
    [self scrollToBottomAnimated:YES];
}

- (void)receivedMessage:(MSGRMsgObject *)msg {
    [self refreshData];
    if ([self.navigationController.viewControllers lastObject] == self && (msg.fromUser == nil || [msg.fromUser isEqual:self.user])) {
        [[MSGRMessenger messenger].objectStore clearConvOfUser:self.user];
    }
}

- (void)restoreInput:(UITapGestureRecognizer *)sender {
    [self resignInput];
}

@end
