//
//  PlaceCell.m
//  Tether
//
//  Created by Laura Smith on 11/30/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "Flurry.h"
#import "Place.h"
#import "PlaceCell.h"
#import "TethrButton.h"

#define degreesToRadian(x) (M_PI * (x) / 180.0)

@protocol PlaceCellContentViewDelegate;

@interface PlaceCellContentView : UIView
@property (nonatomic, weak) id<PlaceCellContentViewDelegate> delegate;
@property (nonatomic, strong) Place *place;
@property (nonatomic, strong) UILabel *placeNameLabel;
@property (nonatomic, strong) TethrButton *commitButton;
@property (nonatomic, strong) UIButton *friendsGoingButton;
@property (nonatomic, strong) UIButton *friendsGoingButtonLarge;
@property (nonatomic, strong) UIButton *arrowButton;
@property (nonatomic, strong) UILabel *addressLabel;
@property (retain, nonatomic) UIImageView *pinImageView;

- (void)prepareForReuse;
-(void)layoutCommitButton;

@end

@protocol PlaceCellContentViewDelegate <NSObject>

- (void)commitToPlace:(Place *)place;
- (void)removePreviousCommitment;
- (void)removeCommitmentFromDatabase;
- (void)showFriendsView;
- (void)inviteToPlace:(Place *)place;

@end

@implementation PlaceCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.placeNameLabel = [[UILabel alloc] init];
        self.placeNameLabel.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:self.placeNameLabel];
        self.commitButton = [[TethrButton alloc] init];
        self.commitButton.tag = 1;
        [self addSubview:self.commitButton];
        self.addressLabel = [[UILabel alloc] init];
        [self addSubview:self.addressLabel];
        self.friendsGoingButton = [[UIButton alloc] init];
        [self addSubview:self.friendsGoingButton];
        self.friendsGoingButtonLarge = [[UIButton alloc] init];
        [self addSubview:self.friendsGoingButtonLarge];
        self.arrowButton = [[UIButton alloc] init];
        [self addSubview:self.arrowButton];
    }
    return self;
}

- (void)prepareForReuse {
    [self layoutSubviews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.placeNameLabel setTextColor:UIColorFromRGB(0x8e0528)];
    [self.placeNameLabel setLineBreakMode:NSLineBreakByWordWrapping];
    self.placeNameLabel.numberOfLines = 0;
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    
    CGRect textRect = [self.placeNameLabel.text boundingRectWithSize:CGSizeMake(150.0, self.bounds.size.height)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName:montserrat}
                                         context:nil];
    
    CGSize size = textRect.size;
    self.placeNameLabel.textAlignment = NSTextAlignmentCenter;
    [self.placeNameLabel setFont:montserrat];
    
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:10.0f];
    [self.addressLabel setText:self.place.address];
    
    CGRect textRectAddress = [self.addressLabel.text boundingRectWithSize:CGSizeMake(150.0, self.bounds.size.height)
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:@{NSFontAttributeName:montserratSmall}
                                                             context:nil];
    CGSize sizeAddress = textRectAddress.size;
    
    [self.placeNameLabel setFrame:CGRectMake((self.bounds.size.width - size.width) / 2.0, (self.bounds.size.height - size.height - sizeAddress.height) / 2.0, size.width, size.height)];
    
    self.addressLabel.frame = CGRectMake((self.bounds.size.width - sizeAddress.width) / 2.0, self.placeNameLabel.frame.origin.y + self.placeNameLabel.frame.size.height, sizeAddress.width, sizeAddress.height);
    [self.addressLabel setFont:montserratSmall];
    [self.addressLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
    
    UIFont *missionGothic = [UIFont fontWithName:@"MissionGothic-BoldItalic" size:14.0f];
    [self.commitButton setNormalColor:[UIColor whiteColor]];
    [self.commitButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [self.commitButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    self.commitButton.titleLabel.font = missionGothic;
    [self.commitButton addTarget:self
                          action:@selector(commitClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    self.commitButton.titleEdgeInsets = UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0);
    self.commitButton.frame = CGRectMake(0.0, 0.0, 70.0, self.bounds.size.height);
    [self.commitButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    
    self.pinImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.commitButton.frame.size.width - 25.0) / 2.0, 20.0, 25.0, 25.0)];
    self.pinImageView.image = [UIImage imageNamed:@"GreyPinIcon"];
    self.pinImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.commitButton addSubview:self.pinImageView];
    
    [self layoutCommitButton];
    
    self.arrowButton.frame = CGRectMake(self.frame.size.width - 30.0, (self.frame.size.height - 10.0) / 2, 7.0, 11.0);
    self.arrowButton.transform = CGAffineTransformMakeRotation(degreesToRadian(180));
    [self.arrowButton addTarget:self
                                action:@selector(friendsGoingClicked:)
                      forControlEvents:UIControlEventTouchUpInside];
    
    self.friendsGoingButtonLarge.frame = CGRectMake(self.frame.size.width - 88.0, 0.0, 88.0, self.frame.size.height);
    [self.friendsGoingButtonLarge addTarget:self
                                     action:@selector(friendsGoingClicked:)
                           forControlEvents:UIControlEventTouchUpInside];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    UIFont *helveticaNeue = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30.0f];
    [self.friendsGoingButton addTarget:self
                                action:@selector(friendsGoingClicked:)
                      forControlEvents:UIControlEventTouchUpInside];
    [self.friendsGoingButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    self.friendsGoingButton.titleLabel.font = helveticaNeue;

    Place *p = [sharedDataManager.placesDictionary objectForKey:self.place.placeId];
    if ([p.totalCommitted count] > 0 || self.commitButton.tag == 2) {
        [self.friendsGoingButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)MAX(1, [p.totalCommitted count])] forState:UIControlStateNormal];
        size = [self.friendsGoingButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeue}];
        self.friendsGoingButton.frame = CGRectMake(self.frame.size.width - MIN(60.0,size.width) - 33.0, (self.frame.size.height - size.height) / 2, MIN(60.0,size.width), size.height);
        self.friendsGoingButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        UIImage *btnImage = [UIImage imageNamed:@"RedTriangle"];
        [self.arrowButton setImage:btnImage forState:UIControlStateNormal];
    } else {
        [self.friendsGoingButton setTitle:@"" forState:UIControlStateNormal];
        [self.arrowButton setImage:[UIImage imageNamed:@"GreyTriangle"] forState:UIControlStateNormal];
    }
}

- (void)setPlace:(Place *)place {
    _place = place;
    self.placeNameLabel.text = place.name;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

-(void)layoutCommitButton {
    if (self.commitButton.tag == 1) {
        [self.commitButton setTitle:@"  tethr  " forState:UIControlStateNormal];
        self.pinImageView.image = [UIImage imageNamed:@"GreyPinIcon"];
    } else {
        [self.commitButton setTitle:@"  tethred  " forState:UIControlStateNormal];
        self.pinImageView.image = [UIImage imageNamed:@"PinIcon"];
    }
}

-(IBAction)commitClicked:(id)sender {
    if (self.commitButton.tag == 1) {
        if([self.delegate respondsToSelector:@selector(commitToPlace:)]) {
            [self.delegate commitToPlace:self.place];
            [Flurry logEvent:@"Tethrd_by_tapping_tethr_button_on_cell"];
        }
    } else {
        if([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
            [self.delegate removePreviousCommitment];
        }
        if ([self.delegate respondsToSelector:@selector(removeCommitmentFromDatabase)]) {
            [self.delegate removeCommitmentFromDatabase];
        }
    }
}

-(IBAction)friendsGoingClicked:(id)sender {
    if ([self.delegate respondsToSelector:@selector(showFriendsView)]) {
        [self.delegate showFriendsView];
    }
}

@end

@interface PlaceCell() <PlaceCellContentViewDelegate>
@property (nonatomic, strong) PlaceCellContentView *cellContentView;
@end

@implementation PlaceCell

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
    [super prepareForReuse];
    [self.cellContentView setNeedsDisplay];
}

- (PlaceCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[PlaceCellContentView alloc] initWithFrame:self.contentView.bounds];
        _cellContentView.delegate = self;
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_cellContentView];
    }
    return _cellContentView;
}

- (void)setPlace:(Place*)place {
    _place = place;
    self.cellContentView.commitButton.tag = 1;
    [self.cellContentView setPlace:place];
}

- (void)setTethered:(bool)isTethered {
    if (isTethered) {
        self.cellContentView.commitButton.tag = 2;
    } else {
        self.cellContentView.commitButton.tag = 1;
    }
    [self.cellContentView layoutCommitButton];
}

-(void)inviteToPlace:(Place *)place {
    if ([self.delegate respondsToSelector:@selector(inviteToPlace:)]) {
        [self.delegate inviteToPlace:place];
    }
}

-(void)layoutCommitButton{
    [self.cellContentView layoutCommitButton];
}

#pragma mark PlaceCellContentViewDelegate Methods

-(void)commitToPlace:(Place*)place {
    if ([self.delegate respondsToSelector:@selector(commitToPlace:fromCell:)]) {
        [self.delegate commitToPlace:place fromCell:self];
        NSLog(@"PLACE CELL: commiting to %@", self.place.name);
    }
}

-(void)removePreviousCommitment {
    if ([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
        [self.delegate removePreviousCommitment];
    }
}

-(void)removeCommitmentFromDatabase {
    if ([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
        [self.delegate removeCommitmentFromDatabase];
    }
}

-(void)showFriendsView {
    if ([self.delegate respondsToSelector:@selector(showFriendsViewFromCell:)]) {
        [self.delegate showFriendsViewFromCell:self];
    }
}

@end
