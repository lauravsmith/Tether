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
@property (nonatomic, strong) FBProfilePictureView *profilePictureView;
@property (nonatomic, strong) NSMutableArray * tetherFriendsGoingOut;
@property (nonatomic, strong) NSMutableArray * tetherFriendsNotGoingOut;
@property (nonatomic, strong) NSMutableArray * tetherFriendsUndecided;
@property (retain, nonatomic) NSString * userName;
@property (retain, nonatomic) UILabel * userNameLabel;
-(void)updateStatus;
-(void)updateFriendsList;
-(void)updateNameLabel;
@end

@protocol LeftPanelViewControllerDelegate <NSObject>
-(void)goToPlaceInListView:(id)placeId;
@end