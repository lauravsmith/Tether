//
//  FollowRequestCell.h
//  Tether
//
//  Created by Laura Smith on 2014-06-12.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Friend.h"

#import <Parse/Parse.h>
#import <UIKit/UIKit.h>

@protocol FollowRequestCellDelegate;

@interface FollowRequestCell : UITableViewCell

@property (nonatomic, weak) id<FollowRequestCellDelegate> delegate;
@property (nonatomic, strong) PFObject *requestObject;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) FBProfilePictureView *profileView;
@property (nonatomic, strong) UIButton *acceptButton;
@property (nonatomic, strong) UIButton *declineButton;
-(void)setRequestObject:(PFObject *)requestObject;
@end

@protocol FollowRequestCellDelegate <NSObject>
-(void)showProfileOfFriend:(Friend*)user;
-(void)acceptRequest:(PFObject*)requestObject;
-(void)declineRequest:(PFObject*)requestObject;
@end