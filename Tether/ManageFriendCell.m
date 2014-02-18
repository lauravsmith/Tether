//
//  ManageFriendCell.m
//  Tether
//
//  Created by Laura Smith on 2/11/2014.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#define NAME_LABEL_OFFSET_X 70.0
#define PANEL_WIDTH 45.0
#define PROFILE_PICTURE_CORNER_RADIUS 22.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 45.0

#import "CenterViewController.h"
#import "Constants.h"
#import "FriendAtPlaceCell.h"
#import "ManageFriendCell.h"

#import <FacebookSDK/FacebookSDK.h>

@protocol ManageFriendCellContentViewDelegate;

@interface ManageFriendCellContentView : UIView
@property (nonatomic, weak) id<ManageFriendCellContentViewDelegate> delegate;
@property (nonatomic, strong) Friend *friend;
@property (nonatomic, strong) UILabel *friendNameLabel;
@property (nonatomic, strong) UILabel *unblockLabel;
@property (nonatomic, strong) UIButton *addRemoveLabel;
@property (nonatomic, assign) NSString *friendID;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView;
@property (nonatomic, assign) BOOL showingStatusMessage;
- (void)prepareForReuse;
@end

@protocol ManageFriendCellContentViewDelegate <NSObject>

- (void)blockFriend:(Friend*)friend setBlocked:(BOOL)block;

@end

@implementation ManageFriendCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.friendNameLabel = [[UILabel alloc] init];
        self.friendNameLabel.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.friendNameLabel];
        self.addRemoveLabel = [[UIButton alloc] init];
        [self addSubview:self.addRemoveLabel];
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

    if (self.friend.blocked) {
        [self.addRemoveLabel setTitle:@"  add  " forState:UIControlStateNormal];
        [self.addRemoveLabel setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
        self.addRemoveLabel.tag = 0;
    } else {
        [self.addRemoveLabel setTitle:@"  remove  " forState:UIControlStateNormal];
        [self.addRemoveLabel setBackgroundColor:UIColorFromRGB(0x8e0528)];
        self.addRemoveLabel.tag = 1;
    }
    [self.addRemoveLabel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.addRemoveLabel.titleLabel.font = montserrat;
    self.addRemoveLabel.layer.cornerRadius = 5.0;
    size = [self.addRemoveLabel.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.addRemoveLabel.frame = CGRectMake(self.frame.size.width - size.width - 10.0, (self.frame.size.height - size.height - 20.0) / 2.0, size.width, size.height + 20.0);
    [self.addRemoveLabel addTarget:self action:@selector(addRemoveClicked:) forControlEvents:UIControlEventTouchUpInside];
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

-(IBAction)addRemoveClicked:(id)sender {
    if (self.addRemoveLabel.tag == 0) {
        self.friend.blocked = NO;
    } else {
        self.friend.blocked = YES;
    }
    if ([self.delegate respondsToSelector:@selector(blockFriend:setBlocked:)]) {
        [self.delegate blockFriend:self.friend setBlocked:self.friend.blocked];
    }
    
    [self layoutSubviews];
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if (![userDetails boolForKey:kUserDefaultsHasSeenBlockTutorialKey]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:[NSString stringWithFormat:@"%@ will not be able to view your activity on tethr", self.friend.name]
                                                           delegate:self
                                                  cancelButtonTitle:@"Okay"
                                                  otherButtonTitles:nil];
        [alertView show];
        [userDetails setBool:YES forKey:kUserDefaultsHasSeenBlockTutorialKey];
    }
}

@end

@interface ManageFriendCell() <ManageFriendCellContentViewDelegate>
@property (nonatomic, strong) ManageFriendCellContentView *cellContentView;
@end

@implementation ManageFriendCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)prepareForReuse {
    [self.cellContentView prepareForReuse];
}

- (ManageFriendCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[ManageFriendCellContentView alloc] initWithFrame:self.contentView.bounds];
        _cellContentView.delegate = self;
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_cellContentView];
    }
    return _cellContentView;
}

- (void)setFriend:(id<FBGraphUser>)friend {
    _friend = friend;
    [self.cellContentView setFriend:friend];
}

#pragma mark ManageFriendCellContentViewDelegate

- (void)blockFriend:(Friend*)friend setBlocked:(BOOL)block {
    if ([self.delegate respondsToSelector:@selector(blockFriend:setBlocked:)]) {
        [self.delegate blockFriend:friend setBlocked:block];
    }
}

@end
