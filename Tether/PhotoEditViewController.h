//
//  PhotoEditViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-05-26.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Place.h"

#import <UIKit/UIKit.h>

@protocol PhotoEditViewControllerDelegate;

@interface PhotoEditViewController : UIViewController

@property (nonatomic, weak) id<PhotoEditViewControllerDelegate> delegate;
@property (nonatomic, strong) Place *place;
@property (nonatomic, strong) UIButton *enterLocation;
@property (nonatomic, strong) UIButton *shareButton;
- (id)initWithImage:(UIImage *)aImage;

@end

@protocol PhotoEditViewControllerDelegate <NSObject>

-(void)reloadActivity;
-(void)closePhotoEditView;
-(void)confirmPosting:(NSString*)postType;

@end