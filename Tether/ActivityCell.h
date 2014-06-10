//
//  ActivityCell.h
//  Tether
//
//  Created by Laura Smith on 2014-05-26.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//
#import "Friend.h"
#import "Place.h"

#import <Parse/Parse.h>
#import <UIKit/UIKit.h>

@protocol ActivityCellDelegate;

@interface ActivityCell : UITableViewCell

@property (nonatomic, strong) PFObject *activityObject;
@property (nonatomic, strong) NSString *feedType;
@property (nonatomic, weak) id<ActivityCellDelegate> delegate;

@end

@protocol ActivityCellDelegate <NSObject>

- (void)openPlace:(Place*)place;
- (void)showProfileOfFriend:(Friend*)user;
-(void)showLikes:(NSMutableSet*)friendIdSet;
-(void)showComments:(PFObject*)activityObject;
-(void)postSettingsClicked:(PFObject*)postObject;

@end