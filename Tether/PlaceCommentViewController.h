//
//  PlaceCommentViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-06-04.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlaceCommentViewControllerDelegate;

@interface PlaceCommentViewController : UIViewController

@property (nonatomic, weak) id<PlaceCommentViewControllerDelegate> delegate;
@property (nonatomic, strong) Place *place;

@end

@protocol PlaceCommentViewControllerDelegate <NSObject>

-(void)closePlaceCommentView;
-(void)reloadActivity;
-(IBAction)newsTapped:(id)sender;

@end