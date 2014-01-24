//
//  NotificationCell.m
//  Tether
//
//  Created by Laura Smith on 12/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "NotificationCell.h"

#import <FacebookSDK/FacebookSDK.h>

#define CELL_HEIGHT 90.0
#define PADDING 10.0
#define PROFILE_PICTURE_CORNER_RADIUS 22.0
#define PROFILE_PICTURE_SIZE 45.0

@interface NotificationCell () <TTTAttributedLabelDelegate>

@end

@implementation NotificationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

-(void)loadNotification {
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    if (self.notification.sender) {
        FBProfilePictureView *profileView = [[FBProfilePictureView alloc] initWithProfileID:self.notification.sender.friendID
                                                                            pictureCropping:FBProfilePictureCroppingSquare];
        profileView.frame = CGRectMake(PADDING, (CELL_HEIGHT - PROFILE_PICTURE_SIZE) / 2.0, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
        profileView.layer.cornerRadius = PROFILE_PICTURE_CORNER_RADIUS;
        [self addSubview:profileView];
    }

    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
    self.messageHeaderLabel = [[TTTAttributedLabel alloc] init];
    [self.messageHeaderLabel setFont:montserrat];
    if ([self.notification.type isEqualToString:@"acceptance"]) {
        self.text = [[NSMutableAttributedString alloc] initWithString:self.notification.messageHeader];
        self.messageHeaderLabel.text = self.notification.messageHeader;
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
        if (!self.notification.message || [self.notification.message isEqualToString:@""]) {
            self.messageHeaderLabel.text = messageHeader;
        } else {
            self.messageHeaderLabel.text = [NSString stringWithFormat:@"%@ : \n%@", messageHeader, self.notification.message];
        }
        self.text = [[NSMutableAttributedString alloc] initWithString:self.messageHeaderLabel.text];
    }
    
    // add font and color attributes
    NSRange stringRange = (NSRange){0, [self.messageHeaderLabel.text length]};
    CTFontRef fontNormal = CTFontCreateWithName((__bridge CFStringRef)montserrat.fontName, montserrat.pointSize, NULL);
    [self.text addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)fontNormal range:stringRange];
    [self.text addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[UIColor whiteColor].CGColor range:stringRange];
    
    [self.messageHeaderLabel setText:self.text];
    
    CGRect contentRect;
    contentRect = [self.text boundingRectWithSize:CGSizeMake(190.0, 500.f)
                                        options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                        context:nil];
    self.messageHeaderLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.messageHeaderLabel.numberOfLines = 0;
    self.messageHeaderLabel.frame = CGRectMake(60.0, PADDING / 2.0, contentRect.size.width, ceil(contentRect.size.height) + 1.0);
    
    self.messageHeaderLabel.delegate = self;
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if ([sharedDataManager.placesDictionary objectForKey:self.notification.placeId]) {
        // bold place names and link to open place
        NSRange placeRange = [self.messageHeaderLabel.text rangeOfString:self.notification.placeName];
        UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:12.0f];
        CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)montserratBold.fontName, montserratBold.pointSize, NULL);
        
        NSArray *keys = [[NSArray alloc] initWithObjects:(id)kCTForegroundColorAttributeName,(id)kCTUnderlineStyleAttributeName
                         ,(id)kCTFontAttributeName, nil];
        NSArray *objects = [[NSArray alloc] initWithObjects:UIColorFromRGB(0xc8c8c8),[NSNumber numberWithInt:kCTUnderlineStyleNone],(__bridge id)font, nil];
        NSDictionary *linkAttributes = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
        self.messageHeaderLabel.linkAttributes = linkAttributes;
        self.messageHeaderLabel.activeLinkAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        (id)[UIColorFromRGB(0x8e0528) CGColor], (NSString*)kCTForegroundColorAttributeName, nil];
        [self.messageHeaderLabel addLinkToURL:[NSURL URLWithString:@"action://show-place"] withRange:placeRange];
    }
    
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
    self.time = self.timeLabel.text;

    CGSize size = [self.timeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.timeLabel.frame = CGRectMake(self.frame.size.width - 60.0 - size.width - PADDING, MAX(self.messageHeaderLabel.frame.size.height, CELL_HEIGHT - size.height - PADDING / 2.0), size.width, size.height);
    [self.timeLabel setTextColor:[UIColor whiteColor]];
    [self.timeLabel setUserInteractionEnabled:YES];
    
    self.changeToDeleteTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeToDelete:)];
    self.changeToTimeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeToTime:)];
    self.deleteTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deleteNotification:)];
    [self.timeLabel addGestureRecognizer:self.changeToDeleteTap];
    
    [self addSubview:self.timeLabel];
}

-(void)changeToDelete:(UIGestureRecognizer*)recognizer {
    self.timeLabel.text = @"Delete";
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
    CGSize size = [self.timeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.timeLabel.frame = CGRectMake(self.frame.size.width - size.width - PADDING, MAX(self.messageHeaderLabel.frame.size.height, CELL_HEIGHT - size.height - PADDING / 2.0), size.width, size.height);
//    [self.timeLabel setTextColor:UIColorFromRGB(0x8e0528)];
    
    [self.timeLabel removeGestureRecognizer:self.changeToDeleteTap];
    [self.messageHeaderLabel addGestureRecognizer:self.changeToTimeTap];
    [self.timeLabel addGestureRecognizer:self.deleteTap];
}

-(void)changeToTime:(UIGestureRecognizer*)recognizer {
    self.timeLabel.text = self.time;
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
    CGSize size = [self.timeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.timeLabel.frame = CGRectMake(self.frame.size.width - size.width - PADDING, MAX(self.messageHeaderLabel.frame.size.height, CELL_HEIGHT - size.height - PADDING / 2.0), size.width, size.height);
    [self.timeLabel setTextColor:[UIColor whiteColor]];
    [self.messageHeaderLabel removeGestureRecognizer:self.changeToTimeTap];
    [self.timeLabel removeGestureRecognizer:self.deleteTap];
    [self.timeLabel addGestureRecognizer:self.changeToDeleteTap];
}

-(void)deleteNotification:(UIGestureRecognizer*)recognizer {
    if ([self.delegate respondsToSelector:@selector(deleteNotification:)]) {
        [self.delegate deleteNotification:self.notification];
    }
}

#pragma mark TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([[url scheme] hasPrefix:@"action"]) {
        if ([[url host] hasPrefix:@"show-place"]) {
            if ([self.delegate respondsToSelector:@selector(goToPlace:)]) {
                [self.delegate goToPlace:self.notification.placeId];
            }
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
