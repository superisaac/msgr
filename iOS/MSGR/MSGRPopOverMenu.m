//
//  MSGRPopOverMenuViewController.m
//  MOMAIphone
//
//  Created by Ke Zeng on 13-7-24.
//  Copyright (c) 2013年 Sankuai. All rights reserved.
//

#import "MSGRPopOverMenu.h"
#import <QuartzCore/QuartzCore.h>
#import "MSGRCategories.h"

//const static CGFloat kMenuWidth = 160;
const static CGFloat kIndicatorWidth = 24;
const static CGFloat kIndicatorHeight = 16;

@interface MSGRPopOverAnchorIndicator : UIView
@property (nonatomic) BOOL directionUp;
@end
@implementation MSGRPopOverAnchorIndicator

@synthesize directionUp;

 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
     CGContextRef context = UIGraphicsGetCurrentContext();
     CGContextSetFillColorWithColor(context, [UIColor grayLevelColor:0.3].CGColor);
     CGContextSetLineWidth(context, 1.0f);
     CGContextSetShouldAntialias(context, TRUE);
     CGContextSetLineJoin(context, kCGLineJoinRound);
     CGContextBeginPath(context);
     if (self.directionUp) {
         CGContextMoveToPoint(context, rect.origin.x + rect.size.width/2, 0);
         CGContextAddLineToPoint(context, rect.origin.x, rect.size.height);
         CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.size.height);
     } else {
         CGContextMoveToPoint(context, rect.origin.x + rect.size.width/2, rect.size.height);
         CGContextAddLineToPoint(context, rect.origin.x, 0);
         CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, 0);
     }
     CGContextFillPath(context);
 }
@end

@interface MSGRPopOverMenu ()
@end

@implementation MSGRPopOverMenu {
    NSArray * items;
    CGFloat menuWidth;
    MSGRPopOverAnchorIndicator * indicator;
    UIView * padView;
    UIView * anchorView;
    CGPoint anchorPosition;
}

@synthesize itemsTableView, delegate, tag;

- (id)initWithItems:(NSArray *)menuItems
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization
        items = menuItems;
        menuWidth = 80;
        for (NSString * t in items) {
            CGSize tSize = [t sizeWithFont:[self menuTextFont] constrainedToSize:CGSizeMake(1000000, 20)];
            if (tSize.width > menuWidth) {
                menuWidth = tSize.width;
            }
        }
        menuWidth += 20;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"deallocated");
}

- (UIFont *)menuTextFont {
    return [UIFont systemFontOfSize:18];
}

- (void)loadView {
    [super loadView];
    indicator = [[MSGRPopOverAnchorIndicator alloc] initWithFrame:CGRectMake(0, 0, kIndicatorWidth, kIndicatorHeight)];
    indicator.directionUp = YES;
    indicator.backgroundColor = [UIColor clearColor];
    [self.view addSubview:indicator];
    
    padView = [[UIView alloc] initWithFrame:CGRectMake((320 - menuWidth)/2, 0, menuWidth, 120)];
               
    padView.backgroundColor = [UIColor grayLevelColor:0.3];
    padView.layer.cornerRadius = 8;
    [self.view addSubview:padView];
    
    self.itemsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 10, menuWidth, 100) style:UITableViewStylePlain];
    self.itemsTableView.dataSource = self;
    self.itemsTableView.delegate = self;
    self.itemsTableView.backgroundColor = [UIColor grayLevelColor:0.3];
    self.itemsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    [padView addSubview:self.itemsTableView];
    
    self.view.backgroundColor = [UIColor clearColor]; // grayLevelColor:0.3 alpha:0.5];
    [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin];
    
    UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    tapRecognizer.delegate = self;    
    [self.view addGestureRecognizer:tapRecognizer];
}

- (void)showInViewController:(UIViewController*)parentViewController anchorView:(UIView * )aView position:(CGPoint)position {
    anchorView = aView;
    anchorPosition = position;
    [parentViewController.view addSubview:self.view];
    [parentViewController addChildViewController:self];
    [self positionViews];
}

- (void)positionViews {
    self.view.frame = self.parentViewController.view.bounds;
    CGRect bounds = self.view.bounds;

    CGPoint anchorViewOrigin = [anchorView originInView:self.parentViewController.view];
    CGPoint anchor = CGPointMake(anchorViewOrigin.x + anchorView.frame.size.width * anchorPosition.x,
                                 anchorViewOrigin.y + anchorView.frame.size.height * anchorPosition.y);
    CGFloat originX = MIN(315 - menuWidth, MAX(5, anchor.x - menuWidth/2));
    
    if (anchor.y <= bounds.size.height/2) {
        indicator.directionUp = YES;
        CGFloat maxMenuHeight = bounds.size.height - anchor.y - kIndicatorHeight - 5;
        CGFloat menuHeight = MIN(36 * items.count + 2, maxMenuHeight);
        CGFloat padHeight = menuHeight + 20;
        
        padView.frame = CGRectMake(originX, anchor.y + kIndicatorHeight + 1, menuWidth, padHeight);
        self.itemsTableView.frame = CGRectMake(0, 10, menuWidth, menuHeight);
    
        CGFloat indicatorOriginX = anchor.x - kIndicatorWidth/2;
        indicatorOriginX = MAX(indicatorOriginX, padView.frame.origin.x + 10);
        indicatorOriginX = MIN(indicatorOriginX, padView.frame.origin.x + padView.frame.size.width - kIndicatorWidth - 8);
        indicator.frame = CGRectMake(indicatorOriginX, anchor.y, kIndicatorWidth, kIndicatorHeight);
    } else {
        indicator.directionUp = NO;
        CGFloat maxMenuHeight = anchor.y - kIndicatorHeight - 5;
        CGFloat menuHeight = MIN(36 * items.count + 2, maxMenuHeight);
        CGFloat padHeight = menuHeight + 20;

        padView.frame = CGRectMake(originX, anchor.y - kIndicatorHeight + 1 - padHeight, menuWidth, padHeight);
        self.itemsTableView.frame = CGRectMake(0, 10, menuWidth, menuHeight);
        CGFloat indicatorOriginX = anchor.x - kIndicatorWidth/2;
        indicatorOriginX = MAX(indicatorOriginX, padView.frame.origin.x + 10);
        indicatorOriginX = MIN(indicatorOriginX, padView.frame.origin.x + padView.frame.size.width - kIndicatorWidth - 10);
        indicator.frame = CGRectMake(indicatorOriginX, anchor.y - kIndicatorHeight - 1, kIndicatorWidth, kIndicatorHeight);
    }
    [indicator setNeedsDisplay];
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

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    if (self.delegate) {
        NSInteger index = indexPath.row;
        id<MSGRPopOverMenuDelegate> popOverDelegate = self.delegate;
        dispatch_async(dispatch_get_main_queue(), ^{
            [popOverDelegate popOverMenu:self itemSelectedAtIndex:index];
        });
    }
    
    [self dismissMenu];
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
    return items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 36;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [self menuTextFont];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    cell.textLabel.text = items[indexPath.row];
    return cell;
}

- (void)viewTapped:(UITapGestureRecognizer *)recognizer {
    [self dismissMenu];
}

- (void)dismissMenu {
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    anchorView = nil;
    self.delegate = nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint touchPoint = [touch locationInView:self.itemsTableView];
    return ![self.itemsTableView hitTest:touchPoint withEvent:nil];
}
@end
