//
//  NotificationCell.m
//  Tether
//
//  Created by Laura Smith on 12/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Constants.h"
#import "Datastore.h"
#import "NotificationCell.h"

#import <FacebookSDK/FacebookSDK.h>

#define PADDING 10.0
#define PROFILE_PICTURE_CORNER_RADIUS 14.0
#define PROFILE_PICTURE_SIZE 28.0

@interface NotificationCell () <UIGestureRecognizerDelegate>

@end

@implementation NotificationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.profileView = [[FBProfilePictureView alloc] initWithFrame: CGRectMake(PADDING, PADDING, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE)];
        [self addSubview:self.profileView];
        self.contentLabel = [[UILabel alloc] init];
        [self addSubview:self.contentLabel];
        self.timeLabel = [[UILabel alloc] init];
        [self addSubview:self.timeLabel];
        self.followButton = [[UIButton alloc] init];
        [self addSubview:self.followButton];
    }
    return self;
}

-(void)layoutSubviews {
    [self setBackgroundColor:[UIColor clearColor]];
    
    self.profileView.profileID = [[self.notificationObject objectForKey:@"fromUser"]  objectForKey:@"facebookId"];
    self.profileView.pictureCropping = FBProfilePictureCroppingSquare;
    self.profileView.layer.cornerRadius = PROFILE_PICTURE_CORNER_RADIUS;
    
    UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openProfile)];
    [self.profileView addGestureRecognizer:tapGesture];
    self.profileView.userInteractionEnabled = YES;
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
    
    NSString *contentText = [self.notificationObject objectForKey:@"content"];
    self.contentLabel.text = contentText;
    
    CGRect textRect = [contentText boundingRectWithSize:CGSizeMake(self.frame.size.width - 70.0, 1000.0)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName:montserrat}
                                                context:nil];
    self.contentLabel.frame = CGRectMake(50.0, 10.0, textRect.size.width, textRect.size.height);
    self.contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.contentLabel.numberOfLines = 0.0;
    self.contentLabel.font = montserrat;

    [self.timeLabel setFont:montserrat];
    NSDate *date = self.notificationObject.createdAt;
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:date];
    if (interval < 60) {
        self.timeLabel.text = [NSString stringWithFormat:@"%ld s", (long)interval %60];
    } else if (interval > 60 && interval < 60*60) {
        int minutes = floor(interval / 60.0);
        self.timeLabel.text = [NSString stringWithFormat:@"%d m", minutes];
    } else if (interval > 60*60 && interval < 60*60*24) {
        int hours = floor(interval / (60.0*60.0));
        self.timeLabel.text = [NSString stringWithFormat:@"%d h", hours];
    } else if (interval > 60*60*24 && interval < 60*60*24*7) {
        int days = floor(interval / (60*60*24));
        self.timeLabel.text = [NSString stringWithFormat:@"%d d", days];
    } else {
        int weeks = floor(interval / (60*60*24*7));
        self.timeLabel.text = [NSString stringWithFormat:@"%d w", weeks];
    }
    
    CGSize size = [self.timeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.timeLabel.frame = CGRectMake(self.contentLabel.frame.origin.x, self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height, size.width, size.height);
    self.timeLabel.font = montserrat;
    self.timeLabel.textColor = UIColorFromRGB(0xc8c8c8);
    
    if ([[self.notificationObject objectForKey:@"type"] isEqualToString:@"following"]) {
        self.followButton.frame = CGRectMake(self.frame.size.width - 70.0, 5.0, 65.0, 35.0);
        self.followButton.titleLabel.font = montserrat;
        self.followButton.layer.cornerRadius = 4.0;
        self.followButton.layer.masksToBounds = YES;
        self.followButton.layer.borderWidth = 1.0;
        self.followButton.layer.borderColor = UIColorFromRGB(0x8e0528).CGColor;
        [self.followButton addTarget:self action:@selector(followClicked:) forControlEvents:UIControlEventTouchUpInside];
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if ([sharedDataManager.tetherFriendsDictionary objectForKey:[[self.notificationObject objectForKey:@"fromUser"] objectForKey:@"facebookId"]]) {
            self.followButton.tag = 0;
        } else {
            NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
            NSMutableArray *requestArray = [userDetails objectForKey:@"requests"];
            if ([requestArray containsObject:[[self.notificationObject objectForKey:@"fromUser"] objectForKey:@"facebookId"]]) {
                self.followButton.tag = 2;
            } else {
                self.followButton.tag = 1;
            }
        }
        [self setupFollowButton];
    }
}

-(void)setupFollowButton {
    if (self.followButton.tag == 0) {
        [self.followButton setTitle:@"following" forState:UIControlStateNormal];
        [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.followButton setBackgroundColor:UIColorFromRGB(0x8e0528)];
    } else if (self.followButton.tag == 1) {
        [self.followButton setTitle:@"follow" forState:UIControlStateNormal];
        [self.followButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
        [self.followButton setBackgroundColor:[UIColor whiteColor]];
    } else {
        [self.followButton setTitle:@"pending" forState:UIControlStateNormal];
        [self.followButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
        [self.followButton setBackgroundColor:[UIColor whiteColor]];
    }
}

-(IBAction)followClicked:(id)sender {
    PFUser *user = [self.notificationObject objectForKey:@"fromUser"];
    Friend *friend = [[Friend alloc] init];
    friend.friendID = user[kUserFacebookIDKey];
    friend.name = user[kUserDisplayNameKey];
    friend.firstName = user[@"firstName"];
    friend.friendsArray = user[@"tethrFriends"];
    friend.followersArray = user[@"followers"];
    friend.tethrCount = [user[@"tethrs"] intValue];
    friend.object = user;
    friend.isPrivate = [user[@"private"] boolValue];
    friend.city = user[@"cityLocation"];
    friend.timeLastUpdated = user[kUserTimeLastUpdatedKey];
    friend.status = [user[kUserStatusKey] boolValue];
    friend.statusMessage = user[kUserStatusMessageKey];
    
    if (self.followButton.tag == 0) {
        self.followButton.tag = 1;
        if ([self.delegate respondsToSelector:@selector(followUser:following:)]) {
            [self.delegate followUser:friend following:NO];
        }
    } else if (self.followButton.tag == 1) {
        if (friend.isPrivate) {
            self.followButton.tag = 2;
        } else {
            self.followButton.tag = 0;
        }
        if ([self.delegate respondsToSelector:@selector(followUser:following:)]) {
            [self.delegate followUser:friend following:YES];
        }
    }
    [self setupFollowButton];
}

-(void)setNotificationObject:(PFObject *)notificationObject {
    _notificationObject = notificationObject;
    [self layoutSubviews];
}

-(void)openProfile {
    if ([self.delegate respondsToSelector:@selector(showProfileOfFriend:)]) {
        PFUser *user = [self.notificationObject objectForKey:@"fromUser"];
        Friend *friend = [[Friend alloc] init];
        friend.friendID = user[kUserFacebookIDKey];
        friend.name = user[kUserDisplayNameKey];
        friend.firstName = user[@"firstName"];
        friend.friendsArray = user[@"tethrFriends"];
        friend.followersArray = user[@"followers"];
        friend.tethrCount = [user[@"tethrs"] intValue];
        friend.object = user;
        friend.isPrivate = [user[@"private"] boolValue];
        friend.city = user[@"cityLocation"];
        friend.timeLastUpdated = user[kUserTimeLastUpdatedKey];
        friend.status = [user[kUserStatusKey] boolValue];
        friend.statusMessage = user[kUserStatusMessageKey];
        [self.delegate showProfileOfFriend:friend];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
