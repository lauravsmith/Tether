//
//  CommentCell.m
//  Tether
//
//  Created by Laura Smith on 2014-06-04.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "CommentCell.h"
#import "Datastore.h"

#define PROFILE_PICTURE_CORNER_RADIUS 15.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 30.0

@protocol CommentCellContentViewDelegate;

@interface CommentCellContentView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<CommentCellContentViewDelegate> delegate;
@property (nonatomic, strong) PFObject *commentObject;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *commentLabel;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView;
@property (nonatomic, strong) UIButton *settingsButton;
@end

@protocol CommentCellContentViewDelegate <NSObject>
-(void)postSettingsClicked;
@end

@implementation CommentCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.nameLabel = [[UILabel alloc] init];
        [self addSubview:self.nameLabel];
        self.commentLabel = [[UILabel alloc] init];
        [self addSubview:self.commentLabel];
        self.settingsButton = [[UIButton alloc] init];
        [self addSubview:self.settingsButton];
    }
    return self;
}

- (void)prepareForReuse {
    [self layoutSubviews];
}

- (void)layoutSubviews {
}

-(void)setCommentObject:(PFObject *)commentObject {
    _commentObject = commentObject;
    self.friendProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)[self.commentObject objectForKey:@"facebookId"] pictureCropping:FBProfilePictureCroppingSquare];
    self.friendProfilePictureView.frame = CGRectMake(PROFILE_PICTURE_OFFSET_X, 10.0, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
    self.friendProfilePictureView.layer.cornerRadius = PROFILE_PICTURE_CORNER_RADIUS;
    self.friendProfilePictureView.clipsToBounds = YES;
    self.friendProfilePictureView.tag = 0;
    [self addSubview:self.friendProfilePictureView];
    
    self.nameLabel.text = [[self.commentObject objectForKey:@"user"] objectForKey:@"firstName"];
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.nameLabel.font = montserrat;
    [self.nameLabel setTextColor:UIColorFromRGB(0x8e0528)];
    CGSize size = [self.nameLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.nameLabel.frame = CGRectMake(50.0, 10.0, size.width, size.height);
    
    self.commentLabel.text = [self.commentObject objectForKey:@"content"];
    [self.commentLabel setTextColor:UIColorFromRGB(0x1d1d1d)];
    self.commentLabel.font = montserrat;
    size = [self.commentLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.commentLabel.frame = CGRectMake(50.0, self.nameLabel.frame.size.height + 15.0, size.width, size.height);
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if ([[self.commentObject objectForKey:@"facebookId"] isEqualToString:sharedDataManager.facebookId]) {
        [self.settingsButton addTarget:self action:@selector(postSettingsClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.settingsButton setTitle:@"..." forState:UIControlStateNormal];
        [self.settingsButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 8.0, 0.0)];
        [self.settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.settingsButton.frame= CGRectMake(self.frame.size.width - 32.0, self.frame.size.height - 12.0, 30.0, 10.0);
        [self.settingsButton setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
        self.settingsButton.layer.cornerRadius = 2.0;
        self.settingsButton.layer.masksToBounds = YES;
    }
}

-(void)postSettingsClicked {
    if ([self.delegate respondsToSelector:@selector(postSettingsClicked)]) {
        [self.delegate postSettingsClicked];
    }
}

@end

@interface CommentCell() <CommentCellContentViewDelegate>
@property (nonatomic, strong) CommentCellContentView *cellContentView;
@end

@implementation CommentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (CommentCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[CommentCellContentView alloc] initWithFrame:self.contentView.bounds];
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_cellContentView];
        _cellContentView.delegate = self;
    }
    return _cellContentView;
}

-(void)setCommentObject:(PFObject *)commentObject {
    _commentObject = commentObject;
    [self.cellContentView setCommentObject:commentObject];
}

-(void)postSettingsClicked {
    if ([self.delegate respondsToSelector:@selector(postSettingsClicked:)]) {
        [self.delegate postSettingsClicked:self.commentObject];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
