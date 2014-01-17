//
//  NotificationCell.h
//  Tether
//
//  Created by Laura Smith on 12/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Notification.h"

#import <UIKit/UIKit.h>

@interface NotificationCell : UITableViewCell

@property (nonatomic, strong) Notification *notification;
@property (nonatomic, strong) UILabel *messageHeaderLabel;
@property (nonatomic, strong) UILabel *timeLabel;
-(void)loadNotification;
@end
