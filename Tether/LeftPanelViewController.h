//
//  LeftPanelViewController.h
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Friend.h"
#import "ViewController.h"

#import <Parse/Parse.h>

@protocol LeftPanelViewControllerDelegate;

@interface LeftPanelViewController : ViewController

@property (nonatomic, assign) id<LeftPanelViewControllerDelegate> delegate;
-(void)hideSearchBar;
-(void)updateFriendsList;
-(void)addTutorialView;
@end

@protocol LeftPanelViewControllerDelegate <NSObject>
-(void)goToPlaceInListView:(id)placeId;
-(void)openPageForPlaceWithId:(id)placeId;
-(void)pollDatabase;
-(void)inviteFriend:(Friend*)friend;
-(void)sortTetherFriends;
@end