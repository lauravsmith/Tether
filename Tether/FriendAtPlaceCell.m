//
//  FriendAtPlaceCell.m
//  Tether
//
//  Created by Laura Smith on 1/7/2014.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "FriendAtPlaceCell.h"

#import <FacebookSDK/FacebookSDK.h>

#define NAME_LABEL_OFFSET_X 70.0
#define PROFILE_PICTURE_CORNER_RADIUS 22.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 45.0

@interface FriendAtPlaceCellContentView : UIView
@property (nonatomic, strong) Friend *friend;
@property (nonatomic, strong) UILabel *friendNameLabel;
@property (nonatomic, assign) NSString *friendID;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView;
@property (nonatomic, assign) BOOL showingStatusMessage;
- (void)prepareForReuse;
@end

@implementation FriendAtPlaceCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.friendNameLabel = [[UILabel alloc] init];
        self.friendNameLabel.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.friendNameLabel];
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

@end

@interface FriendAtPlaceCell()
@property (nonatomic, strong) FriendAtPlaceCellContentView *cellContentView;
@end

@implementation FriendAtPlaceCell

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

- (FriendAtPlaceCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[FriendAtPlaceCellContentView alloc] initWithFrame:self.contentView.bounds];
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_cellContentView];
    }
    return _cellContentView;
}

- (void)setFriend:(id<FBGraphUser>)friend {
    _friend = friend;
    [self.cellContentView setFriend:friend];
}

@end