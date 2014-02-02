//
//  FriendCell.m
//  Tether
//
//  Created by Laura Smith on 11/24/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "Friend.h"
#import "FriendCell.h"

#define MAX_LABEL_WIDTH 150.0
#define NAME_LABEL_OFFSET_X 70.0
#define PANEL_WIDTH 45.0
#define PROFILE_PICTURE_CORNER_RADIUS 22.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 45.0

@protocol FriendCellContentViewDelegate;

@interface FriendCellContentView : UIView
@property (nonatomic, weak) id<FriendCellContentViewDelegate> delegate;
@property (nonatomic, strong) Friend *friend;
@property (nonatomic, strong) UILabel *friendNameLabel;
@property (nonatomic, strong) UIButton *placeButton;
@property (nonatomic, assign) NSString *friendID;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, assign) BOOL showingStatusMessage;
@property (nonatomic, strong) UIButton *inviteButton;
@property (nonatomic, strong) UIButton *inviteButtonLarge;
- (void)prepareForReuse;
@end

@protocol FriendCellContentViewDelegate <NSObject>
-(void)goToPlaceInListView:(id)placeId;
-(void)inviteFriend:(Friend*)friend;
@end

@implementation FriendCellContentView


- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.friendNameLabel = [[UILabel alloc] init];
        self.friendNameLabel.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.friendNameLabel];
        self.placeButton = [[UIButton alloc] init];
        [self addSubview:self.placeButton];
        self.layer.delegate = self;
        self.showingStatusMessage = NO;
        self.inviteButton = [[UIButton alloc] init];
        [self addSubview:self.inviteButton];
        self.inviteButtonLarge = [[UIButton alloc] init];
        [self addSubview:self.inviteButtonLarge];
    }
    return self;
}

- (void)prepareForReuse {
    [self layoutSubviews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self setBackgroundColor:[UIColor whiteColor]];
    
    self.friendProfilePictureView.frame = CGRectMake(PROFILE_PICTURE_OFFSET_X, (self.frame.size.height - PROFILE_PICTURE_SIZE) / 2, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
    self.friendProfilePictureView.layer.cornerRadius = 22.0;
    self.friendProfilePictureView.clipsToBounds = YES;
    self.friendProfilePictureView.tag = 0;

    UIFont *montserratBold = [UIFont fontWithName:@"Montserrat" size:14.0f];
    CGSize size = [self.friendNameLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratBold}];
    self.friendNameLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, self.friendProfilePictureView.frame.origin.y, MIN(size.width, MAX_LABEL_WIDTH), size.height);
    self.friendNameLabel.adjustsFontSizeToFitWidth = YES;
    [self.friendNameLabel setTextColor:UIColorFromRGB(0x8e0528)];
    [self.friendNameLabel setFont:montserratBold];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (self.friend) {
        if (self.friend.placeId != NULL) {
            if ([sharedDataManager.placesDictionary objectForKey:self.friend.placeId]) {
                Place *place = [sharedDataManager.placesDictionary objectForKey:self.friend.placeId];
                [self.placeButton setTitle:place.name forState:UIControlStateNormal];
            }
        } else {
            [self.placeButton setTitle:@"" forState:UIControlStateNormal];
        }
    }
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
    [self.placeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    size = [self.placeButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.placeButton.frame = CGRectMake(NAME_LABEL_OFFSET_X + 1.0, self.friendNameLabel.frame.origin.y + self.friendNameLabel.frame.size.height, MIN(size.width, MAX_LABEL_WIDTH), size.height);
    self.placeButton.titleLabel.font = montserrat;
    self.placeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.placeButton addTarget:self action:@selector(friendsCommitmentPressed) forControlEvents:UIControlEventTouchUpInside];
    
    self.statusLabel = [[UILabel alloc] init];
    [self.statusLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
    if (self.friend) {
        if (self.friend.statusMessage.length > 0) {
            self.statusLabel.text = [NSString stringWithFormat:@"\"%@\"", self.friend.statusMessage];
        } else {
            self.statusLabel.text = @"";
        }
    }
    
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:10.0f];
    size = [self.statusLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratSmall}];
    self.statusLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, self.friendNameLabel.frame.origin.y + self.friendNameLabel.frame.size.height + self.placeButton.frame.size.height, MIN(size.width, MAX_LABEL_WIDTH), size.height);
    [self.statusLabel setFont:montserratSmall];
    self.statusLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.statusLabel];
    
    self.inviteButton.tag = 0;
    if (self.friend && ![self.friend.friendID isEqualToString:sharedDataManager.facebookId]) {
        self.inviteButton.frame = CGRectMake(self.frame.size.width - PANEL_WIDTH - 35.0, self.friendNameLabel.frame.origin.y, 20, 20);
    } else {
        self.inviteButton.frame = CGRectMake(0, 0, 0, 0);
    }
    [self.inviteButton setImage:[UIImage imageNamed:@"InviteIcon"] forState:UIControlStateNormal];
    self.inviteButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.inviteButton addTarget:self
                          action:@selector(inviteClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    self.inviteButton.contentMode = UIViewContentModeScaleAspectFit;
    self.inviteButtonLarge.frame = CGRectMake(self.inviteButton.frame.origin.x, self.inviteButton.frame.origin.y, 60.0, 60.0);
    [self.inviteButtonLarge addTarget:self
                               action:@selector(inviteClicked:)
                     forControlEvents:UIControlEventTouchUpInside];
}

-(void)friendsCommitmentPressed {
    if (![self.placeButton.titleLabel.text isEqualToString:@""] && self.placeButton.titleLabel.text != nil) {
        if ([self.delegate respondsToSelector:@selector(goToPlaceInListView:)]) {
            if (self.friend.placeId) {
               [self.delegate goToPlaceInListView:self.friend.placeId];
            }
        }
    }
}

- (void)setFriend:(Friend *)friend {
    _friend = friend;
    self.friendNameLabel.text = friend.name;
    self.friendID = friend.friendID;
    self.friendProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)self.friendID pictureCropping:FBProfilePictureCroppingSquare];
    
    self.friendProfilePictureView.clipsToBounds = YES;
    [self addSubview:self.friendProfilePictureView];
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

-(IBAction)inviteClicked:(id)sender {
    if (self.inviteButton.tag == 0) {
        if ([self.delegate respondsToSelector:@selector(inviteFriend:)]) {
            [self.delegate inviteFriend:self.friend];
            self.inviteButton.tag = 1;
        }
    } else {
        self.inviteButton.tag = 0;
    }
}

@end

@interface FriendCell() <FriendCellContentViewDelegate>
@property (nonatomic, strong) FriendCellContentView *cellContentView;
@end

@implementation FriendCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(handleLongPress:)];
        lpgr.minimumPressDuration = 0.5; //seconds
        [self addGestureRecognizer:lpgr];
    }
    return self;
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    Datastore *sharedDatastore = [Datastore sharedDataManager];
    if (![self.friend.friendID isEqualToString:sharedDatastore.facebookId]) {
        if ([self.delegate respondsToSelector:@selector(showBlockFriendAlertView:)]) {
            [self.delegate showBlockFriendAlertView:self.friend];
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [self.cellContentView prepareForReuse];
}

- (FriendCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[FriendCellContentView alloc] initWithFrame:self.contentView.bounds];
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_cellContentView];
        _cellContentView.delegate = self;
    }
    return _cellContentView;
}

- (void)setFriend:(id<FBGraphUser>)friend {
    _friend = friend;
    [self.cellContentView setFriend:friend];
}

#pragma mark FriendCellContentViewDelegate methods

-(void)goToPlaceInListView:(id)placeId {
    if ([self.delegate respondsToSelector:@selector(goToPlaceInListView:)]) {
        [self.delegate goToPlaceInListView:placeId];
    }
}

-(void)inviteFriend:(Friend *)friend {
    if ([self.delegate respondsToSelector:@selector(inviteFriend:)]) {
        [self.delegate inviteFriend:friend];
    }
}

@end
