//
//  FriendsListViewController.h
//  Tether
//
//  Created by Laura Smith on 12/11/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FriendsListViewControllerDelegate;

@interface FriendsListViewController : UIViewController
@property (nonatomic, weak) id<FriendsListViewControllerDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *friendsArray;
@property (nonatomic, retain) Place *place;
-(void)loadFriendsOfFriends;

@end

@protocol FriendsListViewControllerDelegate <NSObject>

-(void)closeFriendsView:(FriendsListViewController*)friendsListVC;
-(void)commitToPlace:(Place *)place;
-(void)removePreviousCommitment;
-(void)removeCommitmentFromDatabase;
-(void)selectAnnotationForPlace:(Place*)place;
-(void)refreshList;
-(void)showProfileOfFriend:(Friend*)user;

@end