//
//  FollowRequestCell.m
//  Tether
//
//  Created by Laura Smith on 2014-06-12.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Constants.h"
#import "FollowRequestCell.h"

#define PADDING 10.0
#define PROFILE_PICTURE_CORNER_RADIUS 14.0
#define PROFILE_PICTURE_SIZE 28.0

@implementation FollowRequestCell

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
        self.acceptButton = [[UIButton alloc] init];
        [self addSubview:self.acceptButton];
        self.declineButton = [[UIButton alloc] init];
        [self addSubview:self.declineButton];
    }
    return self;
}

-(void)layoutSubviews {
    [self setBackgroundColor:[UIColor clearColor]];
    
    self.profileView.profileID = [[self.requestObject objectForKey:@"fromUser"]  objectForKey:@"facebookId"];
    self.profileView.pictureCropping = FBProfilePictureCroppingSquare;
    self.profileView.layer.cornerRadius = PROFILE_PICTURE_CORNER_RADIUS;
    
    UITapGestureRecognizer *tapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openProfile)];
    [self.profileView addGestureRecognizer:tapGesture];
    self.profileView.userInteractionEnabled = YES;
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
    
    NSString *contentText = [NSString stringWithFormat:@"%@ would like to follow you", [[self.requestObject objectForKey:@"fromUser"] objectForKey:@"firstName"]];
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
    NSDate *date = self.requestObject.createdAt;
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
    
    self.acceptButton.frame = CGRectMake(90.0, self.timeLabel.frame.origin.y + 5.0, 65.0, 35.0);
    [self.acceptButton addTarget:self action:@selector(acceptClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.acceptButton.titleLabel.font = montserrat;
    [self.acceptButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    self.acceptButton.layer.cornerRadius = 4.0;
    self.acceptButton.layer.masksToBounds = YES;
    self.acceptButton.layer.borderWidth = 1.0;
    self.acceptButton.layer.borderColor = UIColorFromRGB(0x8e0528).CGColor;
    [self.acceptButton setTitle:@"accept" forState:UIControlStateNormal];
    
    self.declineButton.frame = CGRectMake(self.frame.size.width - 155.0, self.timeLabel.frame.origin.y + 5.0, 65.0, 35.0);
    [self.declineButton addTarget:self action:@selector(declineClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.declineButton.titleLabel.font = montserrat;
    [self.declineButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    self.declineButton.layer.cornerRadius = 4.0;
    self.declineButton.layer.masksToBounds = YES;
    self.declineButton.layer.borderWidth = 1.0;
    self.declineButton.layer.borderColor = UIColorFromRGB(0x8e0528).CGColor;
    [self.declineButton setTitle:@"decline" forState:UIControlStateNormal];
}

-(IBAction)acceptClicked:(id)sender {
    if ([self.delegate respondsToSelector:@selector(acceptRequest:)]) {
        [self.delegate acceptRequest:self.requestObject];
    }
}

-(IBAction)declineClicked:(id)sender {
    if ([self.delegate respondsToSelector:@selector(declineRequest:)]) {
        [self.delegate declineRequest:self.requestObject];
    }
}

-(void)setRequestObject:(PFObject *)requestObject {
    _requestObject = requestObject;
    [self layoutSubviews];
}

-(void)openProfile {
    if ([self.delegate respondsToSelector:@selector(showProfileOfFriend:)]) {
        PFUser *user = [self.requestObject objectForKey:@"fromUser"];
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

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
