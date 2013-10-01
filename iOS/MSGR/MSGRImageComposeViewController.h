//
//  MSGRImageComposeViewController.h
//  AnyTellDemo
//
//  Created by Zeng Ke on 13-7-30.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    MSGRImageComposeSourceCamera,
    MSGRImageComposeSourcePhotoLibrary,
    MSGRImageComposeSourceDoodle
} MSGRImageComposeSourceType;

@interface MSGRImageComposeViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) MSGRImageComposeSourceType sourceType;
@property (strong, nonatomic) UIImageView * imageView;
@property (nonatomic, readonly) UIImage * outcomeImage;

- (id)initWithImageSelected:(void(^)(UIImage *))aImageSelected;
@end
