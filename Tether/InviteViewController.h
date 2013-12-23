//
//  InviteViewController.h
//  Tether
//
//  Created by Laura Smith on 12/19/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Place.h"
#import <UIKit/UIKit.h>

@protocol InviteViewControllerDelegate;

@interface InviteViewController : UIViewController
@property (nonatomic, weak) id<InviteViewControllerDelegate> delegate;
@property (retain, nonatomic) Place *place;
@end

@protocol InviteViewControllerDelegate <NSObject>
-(void)closeInviteView;
@end