//
//  ProfileViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-05-26.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Friend.h"

#import <UIKit/UIKit.h>

@protocol ProfileViewControllerDelegate;

@interface ProfileViewController : UIViewController

@property (nonatomic, weak) id<ProfileViewControllerDelegate> delegate;
@property (nonatomic, retain) Friend *user;
@property (nonatomic, retain) NSString *postId;
@property (nonatomic, assign) BOOL openComment;
-(void)scrollToPost:(NSString*)postId;
@end

@protocol ProfileViewControllerDelegate <NSObject>

-(void)closeProfileViewController:(ProfileViewController*)profileVC;
-(void)openMessageForFriend:(Friend*)user;
-(void)openPageForPlaceWithId:(NSString*)placeId;
-(void)showProfileOfFriend:(Friend*)user;
-(void)removePreviousCommitment;
-(void)removeCommitmentFromDatabase;
-(void)pollDatabase;
-(void)userChangedSettingsToUseCurrentLocation;
-(void)userChangedLocationInSettings:(CLLocation*)newLocation;
-(void)blockFriend:(Friend*)friend block:(BOOL)block;
@end