//
//  NotificationCell.h
//  Tether
//
//  Created by Laura Smith on 12/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Notification.h"

#import <TTTAttributedLabel.h>
#import <UIKit/UIKit.h>

@protocol NotificationCellDelegate;

@interface NotificationCell : UITableViewCell

@property (nonatomic, weak) id<NotificationCellDelegate> delegate;
@property (nonatomic, strong) Notification *notification;
@property (nonatomic, strong) TTTAttributedLabel *messageHeaderLabel;
@property (nonatomic, strong) NSMutableAttributedString *text;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) NSString *time;
@property (nonatomic, strong) NSString *cityChange;
@property (nonatomic, strong) UITapGestureRecognizer *changeToDeleteTap;
@property (nonatomic, strong) UITapGestureRecognizer *deleteTap;
@property (nonatomic, strong) UITapGestureRecognizer *changeToTimeTap;
@property (nonatomic, strong) FBProfilePictureView *profileView;
-(void)loadNotification;
@end

@protocol NotificationCellDelegate <NSObject>

-(void)goToPlace:(id)placeId;
-(void)userChangedLocationToCityName:(NSString*)city;

@end
