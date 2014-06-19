//
//  FindFriendCell.m
//  Tether
//
//  Created by Laura Smith on 2014-06-17.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Constants.h"
#import "Datastore.h"
#import "FindFriendCell.h"

#import <FacebookSDK/FacebookSDK.h>

#define NAME_LABEL_OFFSET_X 70.0
#define PANEL_WIDTH 45.0
#define PROFILE_PICTURE_CORNER_RADIUS 22.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 45.0

@protocol FindFriendCellContentViewDelegate;

@interface FindFriendCellContentView : UIView
@property (nonatomic, weak) id<FindFriendCellContentViewDelegate> delegate;
@property (nonatomic, strong) Friend *user;
@property (nonatomic, strong) UILabel *friendNameLabel;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView;
@property (nonatomic, assign) BOOL showingStatusMessage;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) NSMutableDictionary *findFriendsDictionary;
- (void)prepareForReuse;
-(void)setFindFriendsDictionary:(NSMutableDictionary *)findFriendsDictionary;
@end

@protocol FindFriendCellContentViewDelegate <NSObject>

-(void)followFriend:(Friend*)user following:(BOOL)follow;

@end

@implementation FindFriendCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.friendNameLabel = [[UILabel alloc] init];
        self.friendNameLabel.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.friendNameLabel];
        self.followButton = [[UIButton alloc] init];
        [self addSubview:self.followButton];
    }
    return self;
}

- (void)prepareForReuse {
    [self layoutSubviews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.friendProfilePictureView.frame = CGRectMake(PROFILE_PICTURE_OFFSET_X, (self.frame.size.height - PROFILE_PICTURE_SIZE) / 2, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
    self.friendProfilePictureView.layer.cornerRadius = 22.0;
    self.friendProfilePictureView.clipsToBounds = YES;
    self.friendProfilePictureView.tag = 0;
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    CGSize size = [self.friendNameLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.friendNameLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, (self.frame.size.height - size.height) / 2.0, MIN(self.frame.size.width - NAME_LABEL_OFFSET_X - PANEL_WIDTH,size.width), size.height);
    self.friendNameLabel.adjustsFontSizeToFitWidth = YES;
    [self.friendNameLabel setTextColor:UIColorFromRGB(0x8e0528)];
    [self.friendNameLabel setFont:montserrat];
    
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:12.0f];
    self.followButton.frame = CGRectMake(self.frame.size.width - 70.0, 5.0, 65.0, 35.0);
    self.followButton.titleLabel.font = montserratSmall;
    self.followButton.layer.cornerRadius = 4.0;
    self.followButton.layer.masksToBounds = YES;
    self.followButton.layer.borderWidth = 1.0;
    self.followButton.layer.borderColor = UIColorFromRGB(0x8e0528).CGColor;
    [self.followButton addTarget:self action:@selector(followClicked:) forControlEvents:UIControlEventTouchUpInside];
    if ([self.findFriendsDictionary objectForKey:self.user.friendID]) {
        self.followButton.tag = 0;
    } else {
        NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
        NSMutableArray *requestArray = [userDetails objectForKey:@"requests"];
        if ([requestArray containsObject:self.user.friendID]) {
            self.followButton.tag = 2;
        } else {
            self.followButton.tag = 1;
        }
    }
    [self setupFollowButton];
}

-(IBAction)followClicked:(id)sender {
    if (self.followButton.tag == 0) {
        self.followButton.tag = 1;
        if ([self.delegate respondsToSelector:@selector(followFriend:following:)]) {
            [self.delegate followFriend:self.user following:NO];
        }
    } else if (self.followButton.tag == 1) {
        if (self.user.isPrivate) {
            self.followButton.tag = 2;
        } else {
            self.followButton.tag = 0;
        }
        if ([self.delegate respondsToSelector:@selector(followFriend:following:)]) {
            [self.delegate followFriend:self.user following:NO];
        }
    }
    [self setupFollowButton];
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

- (void)setUser:(Friend *)user {
    _user = user;
    self.friendNameLabel.text = user.name;
    self.friendProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)self.user.friendID pictureCropping:FBProfilePictureCroppingSquare];
    [self addSubview:self.friendProfilePictureView];
    [self layoutSubviews];
}

-(void)setFindFriendsDictionary:(NSMutableDictionary *)findFriendsDictionary {
    _findFriendsDictionary = findFriendsDictionary;
}

@end

@interface FindFriendCell() <FindFriendCellContentViewDelegate>
@property (nonatomic, strong) FindFriendCellContentView *cellContentView;
@end

@implementation FindFriendCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [self.cellContentView prepareForReuse];
}

- (FindFriendCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[FindFriendCellContentView alloc] initWithFrame:self.contentView.bounds];
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_cellContentView];
    }
    return _cellContentView;
}

- (void)setUser:(Friend*)user {
    _user = user;
    [self.cellContentView setUser:user];
}

-(void)setFindFriendsDictionary:(NSMutableDictionary *)findFriendsDictionary {
    _findFriendsDictionary = findFriendsDictionary;
    [self.cellContentView setFindFriendsDictionary:findFriendsDictionary];
}

#pragma mark FindFriendCellContentViewDelegate

-(void)followFriend:(Friend *)user following:(BOOL)follow {
    if ([self.delegate respondsToSelector:@selector(followFriend:following:)]) {
        [self.delegate followFriend:user following:follow];
    }
}

@end