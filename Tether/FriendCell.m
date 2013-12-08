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

#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 50.0
#define NAME_LABEL_OFFSET_X 70.0
#define BORDER_WIDTH 4.0

@interface FriendCellContentView : UIView
@property (nonatomic, strong) Friend *friend;
@property (nonatomic, strong) UILabel *friendNameLabel;
@property (nonatomic, strong) UILabel *placeNameLabel;
@property (nonatomic, assign) NSString *friendID;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView;
- (void)prepareForReuse;
@end

@implementation FriendCellContentView


- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColorFromRGB(0xD6D6D6);
        self.friendNameLabel = [[UILabel alloc] init];
        self.friendNameLabel.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.friendNameLabel];
        self.placeNameLabel = [[UILabel alloc] init];
        [self addSubview:self.placeNameLabel];
        self.layer.delegate = self;
    }
    return self;
}

- (void)prepareForReuse {
    self.friendProfilePictureView = nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.friendNameLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, 0.0, 300.0, 40.0);
    [self.friendNameLabel setTextColor:[UIColor whiteColor]];
    UIFont *champagneBold = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:18.0f];
    [self.friendNameLabel setFont:champagneBold];
    self.friendProfilePictureView.frame = CGRectMake(PROFILE_PICTURE_OFFSET_X, (self.frame.size.height - PROFILE_PICTURE_SIZE) / 2, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
    self.friendProfilePictureView.layer.cornerRadius = 24.0;
    self.friendProfilePictureView.clipsToBounds = YES;
    [self.friendProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.friendProfilePictureView.layer setBorderWidth:BORDER_WIDTH];
    
    self.placeNameLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, self.friendNameLabel.frame.origin.y + self.friendNameLabel.frame.size.height,  300.0, 40.0);
    [self.placeNameLabel setTextColor:[UIColor whiteColor]];
    [self.placeNameLabel setFont:champagneBold];
}

- (void)setFriend:(Friend *)friend {
    _friend = friend;
    self.friendNameLabel.text = friend.name;
    self.friendID = friend.friendID;
    self.friendProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)self.friendID pictureCropping:FBProfilePictureCroppingSquare];
    
    self.friendProfilePictureView.clipsToBounds = YES;
    [self addSubview:self.friendProfilePictureView];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (friend.placeId) {

        if ([sharedDataManager.placesDictionary objectForKey:friend.placeId]) {
            Place *place = [sharedDataManager.placesDictionary objectForKey:friend.placeId];
            self.placeNameLabel.text = place.name;
        }
    }
    
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

@end

@interface FriendCell()
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
    self.cellContentView = nil;
}

- (FriendCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[FriendCellContentView alloc] initWithFrame:self.contentView.bounds];
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
