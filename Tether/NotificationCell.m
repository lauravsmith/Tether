//
//  NotificationCell.m
//  Tether
//
//  Created by Laura Smith on 12/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "NotificationCell.h"

#import <FacebookSDK/FacebookSDK.h>

#define PROFILE_PICTURE_CORNER_RADIUS 22.0
#define PROFILE_PICTURE_SIZE 45.0

@implementation NotificationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

-(void)loadNotification {
        UIImage *backgroundImage = [UIImage imageNamed:@"BlackTexture"];
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
        backgroundImageView.frame = CGRectMake(0, 0, self.frame.size.width, 100.0);
        [self addSubview:backgroundImageView];
    
        if (self.notification.sender) {
            FBProfilePictureView *profileView = [[FBProfilePictureView alloc] initWithProfileID:self.notification.sender.friendID
                                                                                pictureCropping:FBProfilePictureCroppingSquare];
            profileView.frame = CGRectMake(10.0, 10.0, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
            profileView.layer.cornerRadius = PROFILE_PICTURE_CORNER_RADIUS;
            [self addSubview:profileView];
        }
    
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
        self.messageHeaderLabel = [[UILabel alloc] init];
        [self.messageHeaderLabel setFont:montserrat];
        CGRect contentRect;
        if ([self.notification.type isEqualToString:@"acceptance"]) {
            self.messageHeaderLabel.text = self.notification.messageHeader;
            contentRect = [self.messageHeaderLabel.text boundingRectWithSize:CGSizeMake(200.0, 100.0)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName:montserrat}
                                                       context:nil];
        } else {
            NSString *friendListString = [[NSString alloc] init];
            if ([self.notification.allRecipients count] > 10.0) {
                friendListString = [NSString stringWithFormat:@" and %d other friends", [self.notification.allRecipients count]];
            } else {
                for (Friend *friend in self.notification.allRecipients) {
                    if ([self.notification.allRecipients indexOfObject:friend] == [self.notification.allRecipients count] - 1) {
                        friendListString = [NSString stringWithFormat:@"%@ and %@", friendListString, friend.name];
                    } else {
                        friendListString = [NSString stringWithFormat:@"%@, %@", friendListString, friend.name];
                    }
                }
            }
            
            NSString *messageHeader = [NSString stringWithFormat:@"%@ invited you%@ to %@", self.notification.sender.name, friendListString, self.notification.placeName];
            NSString *content;
            if (!self.notification.message || [self.notification.message isEqualToString:@""]) {
                content = messageHeader;
            } else {
                content = [NSString stringWithFormat:@"%@ : \n%@", messageHeader, self.notification.message];
            }

            contentRect = [content boundingRectWithSize:CGSizeMake(200.0, 100.0)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName:montserrat}
                                                       context:nil];
            self.messageHeaderLabel.text = content;
        }

        self.messageHeaderLabel.frame = CGRectMake(60.0, 0, contentRect.size.width, contentRect.size.height);
        self.messageHeaderLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.messageHeaderLabel.numberOfLines = 0;
        [self.messageHeaderLabel setTextColor:[UIColor whiteColor]];
        [self addSubview:self.messageHeaderLabel];
    
        self.timeLabel = [[UILabel alloc] init];
        [self.timeLabel setFont:montserrat];
        NSTimeInterval timeInterval = [self.notification.time timeIntervalSinceNow];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HHmmss"];
        NSInteger ti = abs((int)timeInterval);
        NSInteger seconds = ti % 60;
        NSInteger minutes = (ti / 60) % 60;
        NSInteger hours = (ti / 3600);
        NSInteger days = (ti / 86400);
        NSInteger weeks = (ti / 604800);
    
        NSString *plural = @"";
        if (weeks > 0) {
            if (weeks > 1)
                plural = @"s";
            self.timeLabel.text = [NSString stringWithFormat:@"%ld week%@ ago", (long)weeks, plural];
        } else if (days > 0) {
            if (days > 1)
                plural = @"s";
            self.timeLabel.text = [NSString stringWithFormat:@"%ld day%@ ago", (long)days, plural];
        } else if (hours > 0) {
            if (hours > 1)
                plural = @"s";
            self.timeLabel.text = [NSString stringWithFormat:@"%ld hour%@ ago", (long)hours, plural];
        } else if (minutes > 0) {
            if (minutes > 1)
                plural = @"s";
            self.timeLabel.text = [NSString stringWithFormat:@"%ld minute%@ ago", (long)minutes, plural];
        } else if (seconds > 0) {
            if (seconds > 1)
                plural = @"s";
            self.timeLabel.text = [NSString stringWithFormat:@"%ld second%@ ago", (long)seconds, plural];
        }
    
        CGSize size = [self.timeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
        self.timeLabel.frame = CGRectMake(self.frame.size.width - 60.0 - size.width, MAX(self.messageHeaderLabel.frame.size.height, 80.0- size.height), size.width, size.height);
        [self.timeLabel setTextColor:[UIColor whiteColor]];
        [self addSubview:self.timeLabel];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
