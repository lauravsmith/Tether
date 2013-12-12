//
//  PlaceCell.m
//  Tether
//
//  Created by Laura Smith on 11/30/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Place.h"
#import "PlaceCell.h"

@protocol PlaceCellContentViewDelegate;

@interface PlaceCellContentView : UIView
@property (nonatomic, weak) id<PlaceCellContentViewDelegate> delegate;
@property (nonatomic, strong) Place *place;
@property (nonatomic, strong) UILabel *placeNameLabel;
@property (nonatomic, strong) UIButton *commitButton;
@property (nonatomic, strong) UIButton *friendsGoingButton;
@property (nonatomic, strong) UILabel *addressLabel;
- (void)prepareForReuse;

@end

@protocol PlaceCellContentViewDelegate <NSObject>

- (void)commitToPlace:(Place *)place;
- (void)removePreviousCommitment;
- (void)removeCommitmentFromDatabase;
- (void)showFriendsView;

@end

@implementation PlaceCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColorFromRGB(0xD6D6D6);
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
        self.layer.delegate = self;
    }
    return self;
}

- (void)prepareForReuse {

}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.placeNameLabel.frame = CGRectMake(0.0, 0.0, 300.0, 40.0);
    [self.placeNameLabel setTextColor:UIColorFromRGB(0x770051)];
    UIFont *champagneBold = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:30.0f];
    [self.placeNameLabel setFont:champagneBold];
    
    self.commitButton.frame = CGRectMake(0.0, 50.0, 100.0, 30.0);
    self.commitButton.titleLabel.text = @"Commit";
    
    [self.commitButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.commitButton addTarget:self
                          action:@selector(commitClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    [self layoutCommitButton];
    
    self.addressLabel.frame = CGRectMake(150.0, 50.0, 200.0, 30.0);
    self.addressLabel.text = self.place.address;
    
    self.friendsGoingButton.frame = CGRectMake(100.0, 50.0, 50.0, 50.0);
    [self.friendsGoingButton setBackgroundColor:[UIColor redColor]];
    [self.friendsGoingButton addTarget:self
                                action:@selector(friendsGoingClicked:)
                      forControlEvents:UIControlEventTouchUpInside];
}

- (void)setPlace:(Place *)place {
    _place = place;
    self.placeNameLabel.text = place.name;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

-(void)layoutCommitButton {
    if (self.commitButton.tag == 1) {
        [self.commitButton setBackgroundColor:[UIColor whiteColor]];
    } else {
        [self.commitButton setBackgroundColor:[UIColor blackColor]];
    }
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
    self.cellContentView = nil;
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
    if ([self.delegate respondsToSelector:@selector(showFriendsView)]) {
        [self.delegate showFriendsView];
    }
}

@end
