//
//  LeftPanelViewController.h
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "ViewController.h"

#import <Parse/Parse.h>

@protocol LeftPanelViewControllerDelegate;

@interface LeftPanelViewController : ViewController

@property (nonatomic, assign) id<LeftPanelViewControllerDelegate> delegate;
-(void)updateFriendsList;
@end

@protocol LeftPanelViewControllerDelegate <NSObject>
-(void)goToPlaceInListView:(id)placeId;
-(void)pollDatabase;
@end