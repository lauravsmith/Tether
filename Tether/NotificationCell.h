//
//  NotificationCell.h
//  Tether
//
//  Created by Laura Smith on 12/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Notification.h"

#import <UIKit/UIKit.h>

@protocol NotificationCellDelegate;

@interface NotificationCell : UITableViewCell

@property (nonatomic, weak) id<NotificationCellDelegate> delegate;
@property (nonatomic, strong) PFObject *notificationObject;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) FBProfilePictureView *profileView;
@property (nonatomic, strong) UIButton *followButton;
-(void)setNotificationObject:(PFObject *)notificationObject;
@end

@protocol NotificationCellDelegate <NSObject>
-(void)showProfileOfFriend:(Friend*)user;
-(void)followUser:(Friend*)user following:(BOOL)adding;
@end
