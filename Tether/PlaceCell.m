//
//  PlaceCell.m
//  Tether
//
//  Created by Laura Smith on 11/30/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Datastore.h"
#import "CenterViewController.h"
#import "Place.h"
#import "PlaceCell.h"

#define degreesToRadian(x) (M_PI * (x) / 180.0)

@protocol PlaceCellContentViewDelegate;

@interface PlaceCellContentView : UIView
@property (nonatomic, weak) id<PlaceCellContentViewDelegate> delegate;
@property (nonatomic, strong) Place *place;
@property (nonatomic, strong) UILabel *placeNameLabel;
@property (nonatomic, strong) UIButton *commitButton;
@property (nonatomic, strong) UIButton *friendsGoingButton;
@property (nonatomic, strong) UIButton *arrowButton;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UIButton *inviteButton;
@property (nonatomic, strong) UIButton *inviteButtonLarge;
@property (nonatomic, strong) UIButton *moreInfoButton;
@property (nonatomic, strong) UILabel *plusIconLabel;
- (void)prepareForReuse;

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
        self.commitButton = [[UIButton alloc] init];
        self.commitButton.tag = 1;
        [self addSubview:self.commitButton];
        self.addressLabel = [[UILabel alloc] init];
        [self addSubview:self.addressLabel];
        self.friendsGoingButton = [[UIButton alloc] init];
        [self addSubview:self.friendsGoingButton];
        self.arrowButton = [[UIButton alloc] init];
        [self addSubview:self.arrowButton];
        self.inviteButton = [[UIButton alloc] init];
        [self addSubview:self.inviteButton];
        self.inviteButtonLarge = [[UIButton alloc] init];
        [self addSubview:self.inviteButtonLarge];
        self.moreInfoButton = [[UIButton alloc] init];
        [self addSubview:self.moreInfoButton];
        self.plusIconLabel = [[UILabel alloc] init];
        [self addSubview:self.plusIconLabel];
    }
    return self;
}

- (void)prepareForReuse {
    [self layoutSubviews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.placeNameLabel setTextColor:UIColorFromRGB(0x8e0528)];
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    CGSize size = [self.placeNameLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.placeNameLabel.frame = CGRectMake(10.0, 10.0, MIN(self.frame.size.width - 100.0, size.width), size.height);
    self.placeNameLabel.adjustsFontSizeToFitWidth = YES;
    [self.placeNameLabel setFont:montserrat];
    
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:10.0f];
    [self.addressLabel setText:self.place.address];
    size = [self.addressLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratSmall}];
    self.addressLabel.frame = CGRectMake(self.placeNameLabel.frame.origin.x, self.placeNameLabel.frame.origin.y + self.placeNameLabel.frame.size.height, size.width, size.height);
    [self.addressLabel setFont:montserratSmall];
    [self.addressLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
    
    UIFont *montserratExtraSmall = [UIFont fontWithName:@"Montserrat" size:8.0f];
    [self.moreInfoButton setTitle:@"(more info)" forState:UIControlStateNormal];
    [self.moreInfoButton setTitleColor:UIColorFromRGB(0x05528e)  forState:UIControlStateNormal];
    self.moreInfoButton.titleLabel.font = montserratExtraSmall;
    size = [self.moreInfoButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratExtraSmall}];
    self.moreInfoButton.frame = CGRectMake(self.placeNameLabel.frame.origin.x + self.placeNameLabel.frame.size.width + 5.0, self.placeNameLabel.frame.origin.y + self.placeNameLabel.frame.size.height - size.height, size.width, size.height);
    [self.moreInfoButton addTarget:self
                          action:@selector(moreInfoClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    
    [self.commitButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    self.commitButton.titleLabel.font = montserrat;
    [self.commitButton addTarget:self
                          action:@selector(commitClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    [self layoutCommitButton];
    
    self.arrowButton.frame = CGRectMake(self.frame.size.width - 20.0, (self.frame.size.height - 10.0) / 2, 10.0, 10.0);
    self.arrowButton.transform = CGAffineTransformMakeRotation(degreesToRadian(180));
    UIImage *btnImage = [UIImage imageNamed:@"RedTriangle"];
    [self.arrowButton setImage:btnImage forState:UIControlStateNormal];
    [self.arrowButton addTarget:self
                                action:@selector(friendsGoingClicked:)
                      forControlEvents:UIControlEventTouchUpInside];
    
    UIFont *helveticaNeue = [UIFont fontWithName:@"HelveticaNeue" size:30.0f];
    if (self.place.numberCommitments > 0) {
        [self.friendsGoingButton setTitle:[NSString stringWithFormat:@"%d", self.place.numberCommitments] forState:UIControlStateNormal];
        size = [self.friendsGoingButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeue}];
        self.friendsGoingButton.frame = CGRectMake(self.frame.size.width - size.width - 20.0, (self.frame.size.height - size.height) / 2, size.width, size.height);
        [self.friendsGoingButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
        self.friendsGoingButton.titleLabel.font = helveticaNeue;
        [self.friendsGoingButton addTarget:self
                                    action:@selector(friendsGoingClicked:)
                          forControlEvents:UIControlEventTouchUpInside];
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if (self.place.numberCommitments == 1 && [self.place.friendsCommitted containsObject:sharedDataManager.facebookId]) {
            [self.arrowButton setHidden:YES];
            [self.friendsGoingButton setEnabled:NO];
        } else {
            [self.arrowButton setHidden:NO];
            [self.friendsGoingButton setEnabled:YES];
        }
    } else {
        [self.friendsGoingButton setTitle:@"" forState:UIControlStateNormal];
        [self.arrowButton setHidden:YES];
    }
    
    self.inviteButton.tag = 0;
    self.inviteButton.frame = CGRectMake(90.0, self.frame.size.height - 35.0, 30, 40);
    [self.inviteButton setImage:[UIImage imageNamed:@"FriendIcon"] forState:UIControlStateNormal];
    [self.inviteButton addTarget:self
                          action:@selector(inviteClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    
    self.inviteButtonLarge.frame = CGRectMake(self.inviteButton.frame.origin.x, self.inviteButton.frame.origin.y, 60.0, 60.0);
    [self.inviteButtonLarge addTarget:self
                          action:@selector(inviteClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    
    self.plusIconLabel.frame = CGRectMake(self.inviteButton.frame.origin.x + 6.0, self.inviteButton.frame.origin.y + 8.0, 10.0, 10.0);
    [self.plusIconLabel setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.plusIconLabel setTextColor:[UIColor whiteColor]];
    self.plusIconLabel.layer.borderWidth = 1.0;
    self.plusIconLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    UIFont *montserratExtraExtraSmall = [UIFont fontWithName:@"Montserrat" size:8];
    self.plusIconLabel.font = montserratExtraExtraSmall;
    self.plusIconLabel.text = @"+";
    self.plusIconLabel.textAlignment = NSTextAlignmentCenter;
    self.plusIconLabel.layer.cornerRadius = 5.0;
}

- (void)setPlace:(Place *)place {
    _place = place;
    self.placeNameLabel.text = place.name;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

-(void)layoutCommitButton {
    if (self.commitButton.tag == 1) {
        [self.commitButton setTitle:@"Tethr" forState:UIControlStateNormal];
        [self.commitButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    } else {
        [self.commitButton setTitle:@"Tethred" forState:UIControlStateNormal];
        [self.commitButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    }
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    CGSize size = [self.commitButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.commitButton.frame = CGRectMake(self.placeNameLabel.frame.origin.x, self.frame.size.height - size.height - 5.0, size.width, size.height);
}

-(IBAction)commitClicked:(id)sender {
    if (self.commitButton.tag == 1) {
        if([self.delegate respondsToSelector:@selector(commitToPlace:)]) {
            NSLog(@"CONTENT VIEW: commiting to %@", self.place.name);
            [self.delegate commitToPlace:self.place];
            self.commitButton.tag = 2;
            [self layoutCommitButton];
        }
    } else {
        if([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
            [self.delegate removePreviousCommitment];
        }
        if ([self.delegate respondsToSelector:@selector(removeCommitmentFromDatabase)]) {
            [self.delegate removeCommitmentFromDatabase];
        }
        
        self.commitButton.tag = 1;
        [self layoutCommitButton];
    }
}

-(IBAction)inviteClicked:(id)sender {
    if (self.inviteButton.tag == 0) {
        if ([self.delegate respondsToSelector:@selector(inviteToPlace:)]) {
            [self.delegate inviteToPlace:self.place];
        }
    } else {
        self.inviteButton.tag = 0;
    }
}

-(IBAction)friendsGoingClicked:(id)sender {
    if ([self.delegate respondsToSelector:@selector(showFriendsView)]) {
        [self.delegate showFriendsView];
    }
}

-(IBAction)moreInfoClicked:(id)sender {
    NSString *urlString = [NSString stringWithFormat:@"http://foursquare.com/v/%@", self.place.placeId];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (![[UIApplication sharedApplication] openURL:url])
        NSLog(@"%@%@",@"Failed to open url:",[url description]);
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
        self.selectionStyle = UITableViewCellSelectionStyleNone;
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
