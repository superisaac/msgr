//
//  MSGRImageComposeViewController.m
//  AnyTellDemo
//
//  Created by Zeng Ke on 13-7-30.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRImageComposeViewController.h"
#import "MSGRCanvasImageView.h"

@interface MSGRImageComposeViewController ()

@end

@implementation MSGRImageComposeViewController {
    BOOL viewReady;
    MSGRCanvasImageView * _imageView;
    void (^imageSelected)(UIImage * image);
}
@synthesize sourceType;
@synthesize imageView=_imageView;


- (id)initWithImageSelected:(void(^)(UIImage *))aImageSelected
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization
        imageSelected = aImageSelected;
        viewReady = NO;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    _imageView = [[MSGRCanvasImageView alloc] init];
    _imageView.frame = self.view.bounds;
    [self.view addSubview:_imageView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Edit image", nil);
    //self.view.backgroundColor = [UIColor lightGrayColor];
    
    UIBarButtonItem * okButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"OK", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(finish)];
    self.navigationItem.rightBarButtonItem = okButton;
    
    UIBarButtonItem * dismissButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    
    UISegmentedControl * colorControl = [[UISegmentedControl alloc] initWithItems:@[@"Blue", @"Red", @"Black"]];
    [colorControl setSelectedSegmentIndex:0];
    [colorControl addTarget:self action:@selector(colorChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.navigationItem.titleView = colorControl;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!viewReady) {
        viewReady = YES;
        [self selectImage];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)finish {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if (imageSelected) {
            imageSelected(_imageView.image);
        }
    }];
}

- (void)dismiss {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectImage {
    if (self.sourceType == MSGRImageComposeSourceDoodle) {
        _imageView.image = [UIImage imageNamed:@"canvasBackground"];
        return;
    }
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    if (self.sourceType == MSGRImageComposeSourceCamera) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
        }
    } else if(self.sourceType == MSGRImageComposeSourcePhotoLibrary) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
        }
    }
    picker.delegate = self;
    picker.allowsEditing = NO;
    [self.navigationController presentViewController:picker animated:NO completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        CGRect imageFrame = [self frameOfImage:image];
        _imageView.image = [self scaleImage:image toSize:imageFrame.size];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"picker cancel");
    __weak typeof(self) wself = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        if(wself) {
            [wself dismiss];
        }
    }];
}


- (UIImage *)outcomeImage {
    return _imageView.image;
}

- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage * newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (CGRect)frameOfImage:(UIImage *)image {
    CGSize viewSize = self.imageView.bounds.size;
    CGSize imageSize = image.size;
    if (imageSize.width <= viewSize.width &&
        imageSize.height <= viewSize.height) {
        return CGRectMake((viewSize.width - imageSize.width)/2, (viewSize.height - imageSize.height)/2,
                          imageSize.width, imageSize.height);
    } else if (imageSize.width / imageSize.height > viewSize.width / viewSize.height) {
        // wider
        CGFloat newImageHeight = imageSize.height * viewSize.width / imageSize.width;
        return CGRectMake(0, (viewSize.height - newImageHeight)/2, viewSize.width, newImageHeight);
    } else {
        CGFloat newImageWidth = imageSize.width * viewSize.height / imageSize.height;
        return CGRectMake((viewSize.width - newImageWidth)/2, 0, newImageWidth, viewSize.height);
    }
}

- (void)colorChanged:(UISegmentedControl *)segment {
    switch (segment.selectedSegmentIndex) {
        case 1:
            _imageView.strokeColor = [UIColor redColor];
            break;
        case 2:
            _imageView.strokeColor = [UIColor blackColor];
            break;
        default:
            _imageView.strokeColor = [UIColor blueColor];
            break;
    }
}

@end
