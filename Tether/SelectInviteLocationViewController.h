//
//  SelectInviteLocationViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-05-02.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "ViewController.h"

@protocol SelectInviteLocationViewControllerDelegate;

@interface SelectInviteLocationViewController : ViewController

@property (nonatomic, weak) id<SelectInviteLocationViewControllerDelegate> delegate;

@end

@protocol SelectInviteLocationViewControllerDelegate <NSObject>
-(void)inviteToPlace:(Place*) place;
-(void)closeSelectInviteLocationView;
@end