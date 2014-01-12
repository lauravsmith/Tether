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

#define NAME_LABEL_OFFSET_X 70.0
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
- (void)prepareForReuse;
@end

@protocol FriendCellContentViewDelegate <NSObject>
-(void)goToPlaceInListView:(id)placeId;
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

    UIFont *champagneBold = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:18.0f];
    CGSize size = [self.friendNameLabel.text sizeWithAttributes:@{NSFontAttributeName: champagneBold}];
    self.friendNameLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, self.friendProfilePictureView.frame.origin.y, size.width, size.height);
    [self.friendNameLabel setTextColor:UIColorFromRGB(0x8e0528)];
    [self.friendNameLabel setFont:champagneBold];
    
    UIFont *champagne = [UIFont fontWithName:@"Champagne&Limousines" size:16.0f];
    [self.placeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    size = [self.placeButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: champagne}];
    self.placeButton.frame = CGRectMake(NAME_LABEL_OFFSET_X, self.friendNameLabel.frame.origin.y + self.friendNameLabel.frame.size.height,  size.width, size.height);
    self.placeButton.titleLabel.font = champagne;
    [self.placeButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [self.placeButton addTarget:self action:@selector(friendsCommitmentPressed) forControlEvents:UIControlEventTouchUpInside];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (self.friend.placeId != NULL) {
        if ([sharedDataManager.placesDictionary objectForKey:self.friend.placeId]) {
            Place *place = [sharedDataManager.placesDictionary objectForKey:self.friend.placeId];
            [self.placeButton setTitle:place.name forState:UIControlStateNormal];
        }
    } else {
        [self.placeButton setTitle:@"" forState:UIControlStateNormal];
    }
    
    self.statusLabel = [[UILabel alloc] init];
    [self.statusLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
    if (self.friend.statusMessage.length > 0) {
        self.statusLabel.text = [NSString stringWithFormat:@"\"%@\"", self.friend.statusMessage];
    } else {
        self.statusLabel.text = @"";
    }
    UIFont *champagneSmall = [UIFont fontWithName:@"Champagne&Limousines" size:14.0f];
    size = [self.statusLabel.text sizeWithAttributes:@{NSFontAttributeName: champagneSmall}];
    self.statusLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, self.friendNameLabel.frame.origin.y + self.friendNameLabel.frame.size.height + self.placeButton.frame.size.height, size.width, size.height);
    [self.statusLabel setFont:champagneSmall];
    [self addSubview:self.statusLabel];
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
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (self.friend.placeId != NULL) {
        if ([sharedDataManager.placesDictionary objectForKey:self.friend.placeId]) {
            Place *place = [sharedDataManager.placesDictionary objectForKey:friend.placeId];
            [self.placeButton setTitle:place.name forState:UIControlStateNormal];
        }
    } else {
        [self.placeButton setTitle:@"" forState:UIControlStateNormal];
    }
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
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

@end
