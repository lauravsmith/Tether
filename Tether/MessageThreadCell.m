//
//  MessageThreadCell.m
//  Tether
//
//  Created by Laura Smith on 2014-04-24.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Datastore.h"
#import "MessageThreadCell.h"

#define degreesToRadian(x) (M_PI * (x) / 180.0)

#define MAX_LABEL_WIDTH 150.0
#define NAME_LABEL_OFFSET_X 80.0
#define PROFILE_PICTURE_CORNER_RADIUS 22.0
#define PROFILE_PICTURE_GROUP_CORNER_RADIUS 18.0
#define PROFILE_PICTURE_OFFSET_X 20.0
#define PROFILE_PICTURE_SIZE 45.0
#define PROFILE_PICTURE_GROUP_SIZE 35.0

@interface MessageThreadCellContentView : UIView

@property (nonatomic, strong) MessageThread *messageThread;
@property (nonatomic, strong) UILabel *friendNamesLabel;
@property (nonatomic, strong) UILabel *recentMessageLabel;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView2;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView3;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView4;
@property (nonatomic, strong) UIButton *arrowButton;
@property (nonatomic, strong) UIView *unreadDot;

@end

@implementation MessageThreadCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.friendNamesLabel = [[UILabel alloc] init];
        [self addSubview:self.friendNamesLabel];
        self.recentMessageLabel = [[UILabel alloc] init];
        [self addSubview:self.recentMessageLabel];
        [self setBackgroundColor:[UIColor clearColor]];
        self.arrowButton = [[UIButton alloc] init];
        [self addSubview:self.arrowButton];
    }
    return self;
}

- (void)layoutSubviews {
    UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:14.0f];
    NSString *names = @"";
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    
    int count = 0;
    for (NSString *friendName in self.messageThread.participantNames) {
        if (![friendName isEqualToString:[userDetails stringForKey:@"name"]] && ![friendName isEqualToString:[userDetails stringForKey:@"firstName"]]) {
            if (count < 3) {
                if ([names isEqualToString:@""]) {
                    names = friendName;
                } else {
                    names = [NSString stringWithFormat:@"%@, %@", names,friendName];
                }
            }
            count++;
        }
    }
    
    if (count > 3) {
        names = [NSString stringWithFormat:@"%@ + %d", names, count - 3];
    }
    
    self.friendNamesLabel.text = names;
    CGSize size = [self.friendNamesLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratBold}];
    self.friendNamesLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, 10.0, MIN(size.width, MAX_LABEL_WIDTH), size.height);
    [self.friendNamesLabel setTextColor:[UIColor whiteColor]];
    [self.friendNamesLabel setFont:montserratBold];
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.recentMessageLabel.text = self.messageThread.recentMessage;
    size = [self.recentMessageLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.recentMessageLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, self.friendNamesLabel.frame.origin.y + self.friendNamesLabel.frame.size.height + 10.0, MIN(size.width, MAX_LABEL_WIDTH), size.height);
    [self.recentMessageLabel setTextColor:[UIColor whiteColor]];
    [self.recentMessageLabel setFont:montserrat];
    
    if ([self.messageThread.participantIds count] == 2) {
        NSString *friendID = @"";
        for (NSString *participantID in self.messageThread.participantIds) {
            if (![participantID isEqualToString:sharedDataManager.facebookId]) {
                friendID = participantID;
            }
        }
        self.friendProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)friendID pictureCropping:FBProfilePictureCroppingSquare];
        self.friendProfilePictureView.clipsToBounds = YES;
        self.friendProfilePictureView.frame = CGRectMake(PROFILE_PICTURE_OFFSET_X, 10.0, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
        self.friendProfilePictureView.layer.cornerRadius = PROFILE_PICTURE_CORNER_RADIUS;
        self.friendProfilePictureView.tag = 0;
        [self addSubview:self.friendProfilePictureView];
    } else {
        NSArray *userIds = [self.messageThread.participantIds allObjects];
        int count = 0;
        int friendsCount = 0;
        while (count < 4 && count < [userIds count] && friendsCount < 3) {
            NSString *friendID = [userIds objectAtIndex:count];
            
            if (![friendID isEqualToString:sharedDataManager.facebookId]) {
                FBProfilePictureView *fbProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)friendID pictureCropping:FBProfilePictureCroppingSquare];
                fbProfilePictureView.clipsToBounds = YES;
                
                float leftOffset = PROFILE_PICTURE_OFFSET_X;
                if (friendsCount%2 == 1) {
                    leftOffset += 15.0;
                }
                
                fbProfilePictureView.frame = CGRectMake(leftOffset, 10.0 + (friendsCount) * 15.0, PROFILE_PICTURE_GROUP_SIZE, PROFILE_PICTURE_GROUP_SIZE);
                fbProfilePictureView.layer.cornerRadius = PROFILE_PICTURE_GROUP_CORNER_RADIUS;
                fbProfilePictureView.tag = 0;
                [self addSubview:fbProfilePictureView];
                friendsCount++;
            }
            count++;
        }
    }
    
    self.arrowButton.frame = CGRectMake(self.frame.size.width - 25.0, (self.frame.size.height - 10.0) / 2, 7.0, 11.0);
    self.arrowButton.transform = CGAffineTransformMakeRotation(degreesToRadian(180));
    [self.arrowButton setImage:[UIImage imageNamed:@"WhiteTriangle"] forState:UIControlStateNormal];
    
    if (self.messageThread.unread) {
        self.unreadDot = [[UIView alloc] initWithFrame:CGRectMake(self.arrowButton.frame.origin.x - 15.0, self.arrowButton.frame.origin.y, 10.0, 10.0)];
        self.unreadDot.layer.cornerRadius = 5.0;
        [self.unreadDot setBackgroundColor:UIColorFromRGB(0x8e0528)];
        [self addSubview:self.unreadDot];
    }
}

- (void)prepareForReuse {
    [self layoutSubviews];
}

- (void)setMessageThread:(MessageThread *)thread {
    _messageThread = thread;
    
    [self setNeedsLayout];
}
@end


@interface MessageThreadCell()
@property (nonatomic, strong) MessageThreadCellContentView *cellContentView;
@end

@implementation MessageThreadCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}

- (MessageThreadCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[MessageThreadCellContentView alloc] initWithFrame:self.contentView.bounds];
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_cellContentView];
    }
    return _cellContentView;
}

- (void)setMessageThread:(MessageThread*)thread {
    _messageThread = thread;
    [self.cellContentView setMessageThread:thread];
}

@end