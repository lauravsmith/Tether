//
//  NotificationCell.m
//  Tether
//
//  Created by Laura Smith on 12/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "NotificationCell.h"

#import <FacebookSDK/FacebookSDK.h>

@implementation NotificationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)loadNotification {
        if (self.notification.sender) {
            FBProfilePictureView *profileView = [[FBProfilePictureView alloc] initWithProfileID:self.notification.sender.friendID
                                                                                pictureCropping:FBProfilePictureCroppingSquare];
            profileView.frame = CGRectMake(0, 0, 50, 50);
            profileView.layer.cornerRadius = 24.0;
            [self addSubview:profileView];
        }
    
        UIFont *champagneSmall = [UIFont fontWithName:@"Champagne&Limousines" size:16.0f];
        UILabel *messageHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 0, 200.0, 60.0)];
        if (self.notification.messageHeader) {
            [messageHeaderLabel setFont:champagneSmall];
            NSString *content;
            if (![self.notification.message isEqualToString:@""]) {
                content = [NSString stringWithFormat:@"%@ : %@", self.notification.messageHeader, self.notification.message];
            } else {
                content = self.notification.messageHeader;
            }
            messageHeaderLabel.text = content;
            messageHeaderLabel.lineBreakMode = NSLineBreakByWordWrapping;
            messageHeaderLabel.numberOfLines = 0;
            [self addSubview:messageHeaderLabel];
        }
        
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, messageHeaderLabel.frame.size.height, 200.0, 60.0)];
        [timeLabel setFont:champagneSmall];
        NSTimeInterval timeInterval = [self.notification.time timeIntervalSinceNow];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HHmmss"];
        NSInteger ti = abs((NSInteger)timeInterval);
        NSInteger seconds = ti % 60;
        NSInteger minutes = (ti / 60) % 60;
        NSInteger hours = (ti / 3600);
        
        if (hours > 0) {
            timeLabel.text = [NSString stringWithFormat:@"%ld hours ago", (long)hours];
        } else if (abs(minutes) > 0) {
            timeLabel.text = [NSString stringWithFormat:@"%ld minutes ago", (long)minutes];
        } else if (abs(seconds) > 0) {
            timeLabel.text = [NSString stringWithFormat:@"%ld seconds ago", (long)seconds];
        }
        
        [self addSubview:timeLabel];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
