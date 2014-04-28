//
//  LeftPanelViewController.h
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Friend.h"

#import <Parse/Parse.h>

@protocol LeftPanelViewControllerDelegate;

@interface LeftPanelViewController : UIViewController

@property (nonatomic, assign) id<LeftPanelViewControllerDelegate> delegate;
-(void)hideSearchBar;
-(void)updateFriendsList;
@end

@protocol LeftPanelViewControllerDelegate <NSObject>
-(void)goToPlaceInListView:(id)placeId;
-(void)openPageForPlaceWithId:(id)placeId;
-(void)pollDatabase;
-(void)inviteFriend:(Friend*)friend;
-(void)sortTetherFriends;
-(void)showShareViewController;
@end