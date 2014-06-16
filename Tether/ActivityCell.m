//
//  ActivityCell.m
//  Tether
//
//  Created by Laura Smith on 2014-05-26.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "ActivityCell.h"
#import "CenterViewController.h"
#import "Constants.h"
#import "Datastore.h"

#import <FacebookSDK/FacebookSDK.h>
#import <TTTAttributedLabel.h>
#import <QuartzCore/QuartzCore.h>

#define PROFILE_PICTURE_CORNER_RADIUS 17.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 35.0

@protocol ActivityCellContentViewDelegate;

@interface ActivityCellContentView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<ActivityCellContentViewDelegate> delegate;
@property (nonatomic, strong) PFObject *activityObject;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIButton *placeButton;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *likeCountButton;
@property (nonatomic, strong) UIImageView *likeCountImage;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) NSMutableSet *likesSet;
@property (nonatomic, strong) UIButton *commentCountButton;
@property (nonatomic, strong) UIButton *commentButton;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *feedType;
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIImageView *heartImageView;
@property (nonatomic, assign) BOOL animating;
- (void)prepareForReuse;
@end

@protocol ActivityCellContentViewDelegate <NSObject>
- (void)openPlace;
- (void)openProfile;
- (void)showLikes:(NSMutableSet*)likes;
-(void)showComments;
-(void)postSettingsClicked;
@end

@implementation ActivityCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.timeLabel = [[UILabel alloc] init];
        [self addSubview:self.timeLabel];
        self.contentLabel = [[UILabel alloc] init];
        [self addSubview:self.contentLabel];
        self.likeButton = [[UIButton alloc] init];
        [self addSubview:self.likeButton];
        self.likesSet = [[NSMutableSet alloc] init];
        self.likeCountButton = [[UIButton alloc] init];
        [self addSubview:self.likeCountButton];
        self.likeCountImage = [[UIImageView alloc] init];
        [self addSubview:self.likeCountImage];
        self.settingsButton = [[UIButton alloc] init];
        [self addSubview:self.settingsButton];
        self.commentButton = [[UIButton alloc] init];
        [self addSubview:self.commentButton];
        self.commentCountButton = [[UIButton alloc] init];
        [self addSubview:self.commentCountButton];
        self.heartImageView = [[UIImageView alloc] init];
        [self addSubview:self.heartImageView];
    }
    return self;
}

- (void)prepareForReuse {
    self.image = nil;
    self.imageView = nil;
    [self layoutSubviews];
}

- (void)layoutSubviews {
    Datastore *sharedDataManager = [Datastore sharedDataManager];

    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.contentLabel.font = montserrat;
    self.contentLabel.textColor = UIColorFromRGB(0x1d1d1d);
    self.contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.contentLabel.numberOfLines = 0;
    
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:12.0f];
    self.timeLabel.font = montserratSmall;
    self.timeLabel.textColor = UIColorFromRGB(0xc8c8c8);
    
    
    if ([[self.activityObject objectForKey:@"type"] isEqualToString:@"photo"]) {
        if ([self.feedType isEqualToString:@"place"]) {
            NSString *contentString = @"";
            if ([self.activityObject objectForKey:@"content"]) {
                contentString = [NSString stringWithFormat:@"%@ posted a photo: \n\"%@\"",  [[self.activityObject objectForKey:@"user"] objectForKey:@"firstName"], [self.activityObject objectForKey:@"content"]];
            } else {
                contentString = [NSString stringWithFormat:@"%@ posted a photo",  [[self.activityObject objectForKey:@"user"] objectForKey:@"firstName"]];
            }
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:contentString];
            [attrStr addAttribute:NSForegroundColorAttributeName
                            value:UIColorFromRGB(0x8e0528)
                            range:[contentString
                                   rangeOfString:[[self.activityObject objectForKey:@"user"] objectForKey:@"firstName"]]];
            self.contentLabel.attributedText = attrStr;
            CGRect textRect = [contentString boundingRectWithSize:CGSizeMake(self.frame.size.width - 60.0, 1000.0)
                                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                                attributes:@{NSFontAttributeName:montserrat}
                                                                   context:nil];
            self.contentLabel.frame = CGRectMake(60.0, 10.0, textRect.size.width, textRect.size.height);
            self.timeLabel.frame = CGRectMake(self.contentLabel.frame.origin.x, self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + 5.0, 40.0, 10.0);
            
            UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openProfile)];
            [self.contentLabel addGestureRecognizer:tapGesture];
            self.contentLabel.userInteractionEnabled = YES;
        } else if ([self.feedType isEqualToString:@"profile"]) {
            self.placeButton = [[UIButton alloc] init];
            [self.placeButton addTarget:self action:@selector(openPlace) forControlEvents:UIControlEventTouchUpInside];
            [self.placeButton setTitle:[self.activityObject objectForKey:@"placeName"] forState:UIControlStateNormal];
            [self.placeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            self.placeButton.titleLabel.font = montserrat;
            CGSize size = [self.placeButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
            self.placeButton.frame = CGRectMake(60.0, 10.0, size.width, size.height);
            [self addSubview:self.placeButton];
            if (self.contentLabel.text && ![self.contentLabel.text isEqualToString:@""]) {
                self.contentLabel.text = [NSString stringWithFormat:@"\"%@\"", [self.activityObject objectForKey:@"content"]];
            }
            if (self.contentLabel.text && ![self.contentLabel.text isEqualToString:@""]) {
                CGRect textRect = [self.contentLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - 60.0, 1000.0)
                                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                                    attributes:@{NSFontAttributeName:montserrat}
                                                                       context:nil];
                self.contentLabel.frame = CGRectMake(60.0, self.placeButton.frame.origin.y + self.placeButton.frame.size.height, textRect.size.width, textRect.size.height);
                self.timeLabel.frame = CGRectMake(self.contentLabel.frame.origin.x, self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + 5.0, 40.0, 10.0);
            } else {
                self.timeLabel.frame = CGRectMake(self.placeButton.frame.origin.x, self.placeButton.frame.origin.y + self.placeButton.frame.size.height + 5.0, 40.0, 10.0);
            }
            NSMutableAttributedString* attrStr = [[NSMutableAttributedString alloc] initWithString:self.placeButton.titleLabel.text];
            [attrStr addAttribute:NSForegroundColorAttributeName
                            value:UIColorFromRGB(0x8e0528)
                            range:[self.placeButton.titleLabel.text
                                   rangeOfString:[self.activityObject objectForKey:@"placeName"]]];
            self.placeButton.titleLabel.attributedText = attrStr;
        } else {
            NSString *contentString = @"";
            if ([self.activityObject objectForKey:@"content"]) {
                contentString = [NSString stringWithFormat:@"%@ posted a photo to %@: \n\"%@\"",  [[self.activityObject objectForKey:@"user"] objectForKey:@"firstName"], [self.activityObject objectForKey:@"placeName"], [self.activityObject objectForKey:@"content"]];
            } else {
                contentString = [NSString stringWithFormat:@"%@ posted a photo to %@",  [[self.activityObject objectForKey:@"user"] objectForKey:@"firstName"], [self.activityObject objectForKey:@"placeName"]];
            }
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:contentString];
            [attrStr addAttribute:NSForegroundColorAttributeName
                            value:UIColorFromRGB(0x8e0528)
                            range:[contentString
                                   rangeOfString:[self.activityObject objectForKey:@"placeName"]]];
            self.contentLabel.attributedText = attrStr;
            CGRect textRect = [contentString boundingRectWithSize:CGSizeMake(self.frame.size.width - 60.0, 1000.0)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName:montserrat}
                                                          context:nil];
            self.contentLabel.frame = CGRectMake(60.0, 10.0, textRect.size.width, textRect.size.height);
            self.timeLabel.frame = CGRectMake(self.contentLabel.frame.origin.x, self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + 5.0, 40.0, 10.0);
            
            UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPlace)];
            [self.contentLabel addGestureRecognizer:tapGesture];
            self.contentLabel.userInteractionEnabled = YES;
        }
    } else if ([[self.activityObject objectForKey:@"type"] isEqualToString:@"comment"]){
        NSMutableAttributedString* attrStr;
        if ([self.feedType isEqualToString:@"place"]) {
            attrStr  = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ commented: \n\"%@\"", [[self.activityObject objectForKey:@"user"] objectForKey:@"firstName"], [self.activityObject objectForKey:@"content"]]];

            [attrStr addAttribute:NSForegroundColorAttributeName
                            value:UIColorFromRGB(0x8e0528)
                            range:[self.contentLabel.text
                   rangeOfString:[[self.activityObject objectForKey:@"user"] objectForKey:@"firstName"]]];
            UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openProfile)];
            [self.contentLabel addGestureRecognizer:tapGesture];
        } else {
            NSString *userName = [[self.activityObject objectForKey:@"user"] objectForKey:@"firstName"];
            NSString * placeName = [self.activityObject objectForKey:@"placeName"];
            NSString *content = [self.activityObject objectForKey:@"content"];
            attrStr  = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ commented on %@: \n\"%@\"", userName, placeName, content]];
            [attrStr addAttribute:NSForegroundColorAttributeName
                            value:UIColorFromRGB(0x8e0528)
                            range:[self.contentLabel.text
                                   rangeOfString:[self.activityObject objectForKey:@"placeName"]]];
            UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPlace)];
            [self.contentLabel addGestureRecognizer:tapGesture];
        }
        self.contentLabel.attributedText = attrStr;
        self.contentLabel.userInteractionEnabled = YES;
        
        CGRect textRect = [self.contentLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - 70.0, 1000.0)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{NSFontAttributeName:montserrat}
                                                        context:nil];
        
        self.contentLabel.frame = CGRectMake(60.0, 10.0, textRect.size.width, textRect.size.height);
        self.timeLabel.frame = CGRectMake(self.contentLabel.frame.origin.x, self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + 5.0, 40.0, 10.0);
    } else if ([[self.activityObject objectForKey:@"type"] isEqualToString:@"createLocation"]) {
        self.contentLabel.text = [self.activityObject objectForKey:@"content"];
        CGRect textRect = [self.contentLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - 60.0, 1000.0)
                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                            attributes:@{NSFontAttributeName:montserrat}
                                                               context:nil];
        self.contentLabel.frame = CGRectMake(60.0, 10.0, textRect.size.width, textRect.size.height);
        self.timeLabel.frame = CGRectMake(self.contentLabel.frame.origin.x, self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + 5.0, 40.0, 10.0);
        NSMutableAttributedString* attrStr = [[NSMutableAttributedString alloc] initWithString:self.contentLabel.text];
        if ([self.feedType isEqualToString:@"place"]) {
            [attrStr addAttribute:NSForegroundColorAttributeName
                            value:UIColorFromRGB(0x8e0528)
                            range:[self.contentLabel.text
                                   rangeOfString:[[self.activityObject objectForKey:@"user"] objectForKey:@"firstName"]]];
            UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openProfile)];
            [self.contentLabel addGestureRecognizer:tapGesture];
        } else {
            [attrStr addAttribute:NSForegroundColorAttributeName
                            value:UIColorFromRGB(0x8e0528)
                            range:[self.contentLabel.text
                                   rangeOfString:[self.activityObject objectForKey:@"placeName"]]];
            UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPlace)];
            [self.contentLabel addGestureRecognizer:tapGesture];
        }
        self.contentLabel.userInteractionEnabled = YES;
        self.contentLabel.attributedText = attrStr;
    } else {
        CGRect textRect = [self.contentLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - 60.0, 1000.0)
                                                               options:NSStringDrawingUsesLineFragmentOrigin
                                                            attributes:@{NSFontAttributeName:montserrat}
                                                               context:nil];
        self.contentLabel.frame = CGRectMake(60.0, 10.0, textRect.size.width, textRect.size.height);
        
        if ([self.activityObject objectForKey:@"placeName"] && self.contentLabel.text) {
            NSMutableAttributedString* attrStr = [[NSMutableAttributedString alloc] initWithString:self.contentLabel.text];
            if ([self.feedType isEqualToString:@"place"]) {
                [attrStr addAttribute:NSForegroundColorAttributeName
                                value:UIColorFromRGB(0x8e0528)
                                range:[self.contentLabel.text
                                       rangeOfString:[[self.activityObject objectForKey:@"user"] objectForKey:@"firstName"]]];
                UITapGestureRecognizer *tapGesture =
                [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openProfile)];
                [self.contentLabel addGestureRecognizer:tapGesture];
            } else {
                [attrStr addAttribute:NSForegroundColorAttributeName
                                value:UIColorFromRGB(0x8e0528)
                                range:[self.contentLabel.text
                                       rangeOfString:[self.activityObject objectForKey:@"placeName"]]];
                UITapGestureRecognizer *tapGesture =
                [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPlace)];
                [self.contentLabel addGestureRecognizer:tapGesture];
            }
            self.contentLabel.attributedText = attrStr;
            self.contentLabel.userInteractionEnabled = YES;
        }
        self.timeLabel.frame = CGRectMake(self.contentLabel.frame.origin.x, self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + 5.0, 40.0, 10.0);
    }

    if (!self.animating) {
        if (self.activityObject && [[self.activityObject objectForKey:@"type"] isEqualToString:@"photo"]) {
            if ([self.feedType isEqualToString:@"place"]) {
                self.likeButton.frame = CGRectMake(60.0, self.frame.size.width + self.contentLabel.frame.size.height + 40.0, 20.0, 20.0);
            } else if ([self.feedType isEqualToString:@"profile"]){
                self.likeButton.frame = CGRectMake(60.0, self.frame.size.width + self.contentLabel.frame.size.height + 60.0, 20.0, 20.0);
            } else {
                self.likeButton.frame = CGRectMake(60.0, self.frame.size.width + self.contentLabel.frame.size.height + 40.0, 20.0, 20.0);
            }
        } else {
            self.likeButton.frame = CGRectMake(self.contentLabel.frame.origin.x, self.timeLabel.frame.origin.y + self.timeLabel.frame.size.height + 10.0, 20.0, 20.0);
        }
        
        [self.likeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        if ([self.likesSet containsObject:sharedDataManager.facebookId]) {
            [self.heartImageView setImage:[UIImage imageNamed:@"redHeart.png"]];
            self.likeButton.tag = 1;
        } else {
            [self.heartImageView setImage:[UIImage imageNamed:@"greyHeart.png"]];
            self.likeButton.tag = 0;
        }
        self.heartImageView.frame = self.likeButton.frame;
        [self.likeButton addTarget:self action:@selector(likeClicked:) forControlEvents:UIControlEventTouchUpInside];

    
    self.commentButton.frame = CGRectMake(self.likeButton.frame.origin.x + self.likeButton.frame.size.width + 15.0, self.likeButton.frame.origin.y, 20.0, 20.0);
    [self.commentButton addTarget:self action:@selector(showComments) forControlEvents:UIControlEventTouchUpInside];
    [self.commentButton setImage:[UIImage imageNamed:@"Comment.png"] forState:UIControlStateNormal];
    
    if ([self.activityObject objectForKey:@"commentCount"] && [[self.activityObject objectForKey:@"commentCount"] integerValue] > 0) {
        int count = [[self.activityObject objectForKey:@"commentCount"] intValue];
        [self.commentCountButton addTarget:self action:@selector(showComments) forControlEvents:UIControlEventTouchUpInside];
        [self.commentCountButton setTitle:[NSString stringWithFormat:@"%d", count] forState:UIControlStateNormal];
        [self.commentCountButton setTitleColor:UIColorFromRGB(0x1d1d1d) forState:UIControlStateNormal];
        self.commentCountButton.titleLabel.font = montserratSmall;
        CGSize size = [self.commentCountButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratSmall}];
        self.commentCountButton.frame = CGRectMake(self.commentButton.frame.origin.x + self.commentButton.frame.size.width + 4.0, self.commentButton.frame.origin.y + 2.0, size.width, size.height);
    }
    
    if ([self.likesSet count] > 0) {
        [self setupLikeCount];
    }
    
    if ([[self.activityObject objectForKey:@"facebookId"] isEqualToString:sharedDataManager.facebookId]) {
        [self.settingsButton addTarget:self action:@selector(postSettingsClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.settingsButton setTitle:@"..." forState:UIControlStateNormal];
        [self.settingsButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 8.0, 0.0)];
        [self.settingsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.settingsButton.frame= CGRectMake(self.frame.size.width - 32.0, self.likeButton.frame.origin.y, 30.0, 17.0);
        [self.settingsButton setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
        self.settingsButton.layer.cornerRadius = 2.0;
        self.settingsButton.layer.masksToBounds = YES;
    }
    }
}

-(void)setFile:(PFFile *)file {
    NSString *requestURL = file.url; // Save copy of url locally (will not change in block)
    
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            if ([requestURL isEqualToString:requestURL]) {
                
                [self setImage:image];
                self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, self.placeButton.frame.size.height + self.contentLabel.frame.size.height + 30.0, self.frame.size.width, self.frame.size.width)];
                [self.imageView setImage:self.image];
                self.imageView.contentMode = UIViewContentModeScaleAspectFit;
                [self addSubview:self.imageView];

                [self setNeedsDisplay];
            }
        } else {
            NSLog(@"Error on fetching file");
        }
    }];
}

-(void)setActivityObject:(PFObject*)object {
    _activityObject = object;
    
    if ([[self.activityObject objectForKey:@"type"] isEqualToString:@"photo"]) {
        PFObject *object = [self.activityObject objectForKey:@"photo"];
        PFFile *file = [object objectForKey:@"photoFile"];
        [self setFile:file];
    }
    
    NSDate *date = [self.activityObject objectForKey:@"date"];
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:date];
    if (interval < 60) {
        self.timeLabel.text = [NSString stringWithFormat:@"%ld s", (long)interval %60];
    } else if (interval > 60 && interval < 60*60) {
        int minutes = floor(interval / 60.0);
        self.timeLabel.text = [NSString stringWithFormat:@"%d m", minutes];
    } else if (interval > 60*60 && interval < 60*60*24) {
        int hours = floor(interval / (60.0*60.0));
        self.timeLabel.text = [NSString stringWithFormat:@"%d h", hours];
    } else if (interval > 60*60*24 && interval < 60*60*24*7) {
        int days = floor(interval / (60*60*24));
        self.timeLabel.text = [NSString stringWithFormat:@"%d d", days];
    } else {
        int weeks = floor(interval / (60*60*24*7));
        self.timeLabel.text = [NSString stringWithFormat:@"%d w", weeks];
    }
    
    if ([self.activityObject objectForKey:@"content"]) {
        PFUser *user = [self.activityObject objectForKey:@"user"];
        if ([self.feedType isEqualToString:@"place"] && ![[self.activityObject objectForKey:@"type"] isEqualToString:@"photo"]) {
            self.content = [NSString stringWithFormat:@"%@ tethred here", [user objectForKey:@"firstName"]];
        } else {
            self.content = [NSString stringWithFormat:@"%@ tethred to %@", [user objectForKey:@"firstName"], [self.activityObject objectForKey:@"placeName"]];
        }
         self.contentLabel.text = self.content;
    }
    
    NSMutableArray *array = [self.activityObject objectForKey:@"likes"];
    self.likesSet = [NSMutableSet setWithArray:array];
    
    self.friendProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)[self.activityObject objectForKey:@"facebookId"] pictureCropping:FBProfilePictureCroppingSquare];
    self.friendProfilePictureView.frame = CGRectMake(PROFILE_PICTURE_OFFSET_X, 10.0, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
    self.friendProfilePictureView.layer.cornerRadius = PROFILE_PICTURE_CORNER_RADIUS;
    self.friendProfilePictureView.clipsToBounds = YES;
    self.friendProfilePictureView.tag = 0;
    [self addSubview:self.friendProfilePictureView];
    
    if (![self.feedType isEqualToString:@"profile"]) {
        UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openProfile)];
        [self.friendProfilePictureView addGestureRecognizer:tapGesture];
    }
}

-(void)setfeedType:(NSString*)feedType {
    _feedType = feedType;
}

-(void)openPlace {
    if ([self.delegate respondsToSelector:@selector(openPlace)]) {
        [self.delegate openPlace];
    }
}

-(void)openProfile {
    if ([self.delegate respondsToSelector:@selector(openProfile)]) {
        [self.delegate openProfile];
    }
}

-(IBAction)likeClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSMutableSet *set = [[NSMutableSet alloc] init];
    
    if (self.likeButton.tag == 0) {
        if ([self.activityObject objectForKey:@"likes"]) {
            set = [NSMutableSet setWithArray:[self.activityObject objectForKey:@"likes"]];
        }
        [set addObject:sharedDataManager.facebookId];
        self.likesSet = set;
        self.likeButton.tag = 1;
        
        CGRect frameNormal = self.likeButton.frame;
        CGRect frameLarge = self.likeButton.frame;
        frameLarge.size.width = 25.0;
        frameLarge.size.height = 25.0;
        frameLarge.origin.x = frameNormal.origin.x - 2.5;
        frameLarge.origin.y = frameNormal.origin.y - 2.5;

        self.animating = YES;
    [UIView animateWithDuration:0.2
                         animations:^{
                              self.likeButton.frame = frameLarge;
                             self.heartImageView.frame = self.likeButton.frame;
                              [self.heartImageView setImage:[UIImage imageNamed:@"redHeartBig.png"]];

                         } completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.2
                                              animations:^{
                                                  self.likeButton.frame = frameNormal;
                                                  self.heartImageView.frame = frameNormal;
                                                  [self.heartImageView setImage:[UIImage imageNamed:@"redHeart.png"]];
                                                  self.animating = NO;
                                              }];
    }];
        
        [self sendLikePush];
    } else {
        if ([self.activityObject objectForKey:@"likes"]) {
            set = [NSMutableSet setWithArray:[self.activityObject objectForKey:@"likes"]];
        }
        [set removeObject:sharedDataManager.facebookId];
        self.likesSet = set;
        self.likeButton.tag = 0;
      [self.heartImageView setImage:[UIImage imageNamed:@"greyHeart.png"]];
    }
    
    if ([self.likesSet count] > 0) {
        [self setupLikeCount];
        self.likeCountButton.hidden = NO;
        self.likeCountImage.hidden = NO;
    } else {
        self.likeCountButton.hidden = YES;
        self.likeCountImage.hidden = YES;
    }
    
    [self.activityObject setObject:[set allObjects] forKey:@"likes"];
    [self.activityObject saveInBackground];
}

-(void)setupLikeCount {
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:12.0f];
    [self.likeCountButton addTarget:self action:@selector(showLikes) forControlEvents:UIControlEventTouchUpInside];
    if ([self.likesSet count] > 1) {
        [self.likeCountButton setTitle:[NSString stringWithFormat:@" %d LIKES ", [self.likesSet count]] forState:UIControlStateNormal];
    } else {
        [self.likeCountButton setTitle:[NSString stringWithFormat:@" %d LIKE ", [self.likesSet count]] forState:UIControlStateNormal];
    }
    self.likeCountButton.titleLabel.font = montserratSmall;
    CGSize size = [self.likeCountButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratSmall}];
    self.likeCountButton.frame = CGRectMake(self.frame.size.width - size.width - 35.0, self.commentButton.frame.origin.y, size.width, size.height + 2.0);
    [self.likeCountButton.titleLabel setTextColor:UIColorFromRGB(0x1d1d1d)];
    [self.likeCountButton setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    UIImage *smallHeart= [UIImage imageNamed:@"smallRedHeart"];
    self.likeCountImage.image = smallHeart;
    self.likeCountImage.frame = CGRectMake(self.likeCountButton.frame.origin.x - 25.0, self.likeCountButton.frame.origin.y - 2.0, 20.0, 20.0);
    self.likeCountButton.layer.cornerRadius = 4.0;
    self.likeCountButton.layer.masksToBounds = YES;
}

-(void)showLikes {
    if ([self.delegate respondsToSelector:@selector(showLikes:)]) {
        [self.delegate showLikes:self.likesSet];
    }
}

-(void)showComments {
    if ([self.delegate respondsToSelector:@selector(showComments)]) {
        [self.delegate showComments];
    }
}

-(void)sendLikePush {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    NSString *type = [self.activityObject objectForKey:@"type"];
    if ([type isEqualToString:@"createLocation"]) {
        type = @"location";
    }
    
    NSString *messageHeader = [NSString stringWithFormat:@"%@ liked your %@", sharedDataManager.firstName, type];
    PFObject *personalNotificationObject = [PFObject objectWithClassName:@"PersonalNotification"];
    [personalNotificationObject setObject:[PFUser currentUser] forKey:@"fromUser"];
    [personalNotificationObject setObject:[self.activityObject objectForKey:@"user"] forKey:@"toUser"];
    [personalNotificationObject setObject:messageHeader forKey:@"content"];
    [personalNotificationObject setObject:self.activityObject forKey:@"activity"];
    [personalNotificationObject setObject:@"like" forKey:@"type"];
    [personalNotificationObject saveInBackground];
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"owner" equalTo:[self.activityObject objectForKey:@"user"]];

    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          messageHeader, @"alert",
                          @"like", @"type",
                          self.activityObject.objectId, @"postId",
                          nil];
    
    // Send push notification to query
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery]; // Set our Installation query
    [push setData:data];
    [push sendPushInBackground];
}

-(void)postSettingsClicked {
    if ([self.delegate respondsToSelector:@selector(postSettingsClicked)]) {
        [self.delegate postSettingsClicked];
    }
}

#pragma mark TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([[url scheme] hasPrefix:@"action"]) {
        if ([[url host] hasPrefix:@"show-place"]) {
            [self openPlace];
        } else {
            [self openProfile];
        }
    }
}

@end

@interface ActivityCell() <ActivityCellContentViewDelegate>
@property (nonatomic, strong) ActivityCellContentView *cellContentView;
@end

@implementation ActivityCell

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

- (ActivityCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[ActivityCellContentView alloc] initWithFrame:self.contentView.bounds];
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_cellContentView];
        _cellContentView.delegate = self;
        _cellContentView.feedType = self.feedType;
    }
    return _cellContentView;
}

-(void)setActivityObject:(PFObject*)object {
    _activityObject = object;
    [self.cellContentView setActivityObject:object];
}

-(void)setfeedType:(NSString*)feedType {
    _feedType = feedType;
    [self.cellContentView setFeedType:feedType];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)openPlace {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    if ([self.delegate respondsToSelector:@selector(openPlace:)]) {
        if ([sharedDataManager.placesDictionary objectForKey:[self.activityObject objectForKey:@"placeId"]]) {
            [self.delegate openPlace:[sharedDataManager.placesDictionary objectForKey:[self.activityObject objectForKey:@"placeId"]]];
        } else {
            Place *place = [[Place alloc] init];
            PFGeoPoint * geoPoint = [self.activityObject objectForKey:@"coordinate"];
            place.city = [self.activityObject objectForKey:@"city"];
            place.state = [self.activityObject objectForKey:@"state"];
            place.name = [self.activityObject objectForKey:@"placeName"];
            place.address = [self.activityObject objectForKey:@"address"];
            place.coord = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
            place.placeId = [self.activityObject objectForKey:@"placeId"];
            place.numberCommitments = 0;
            place.numberPastCommitments = 0;
            place.friendsCommitted = [[NSMutableSet alloc] init];
            place.memo = [self.activityObject objectForKey:@"memo"];
            place.owner = [self.activityObject objectForKey:@"owner"];
            [sharedDataManager.foursquarePlacesDictionary setObject:place forKey:place.placeId];
            [sharedDataManager.placesDictionary setObject:place forKey:place.placeId];
            [self.delegate openPlace:place];
        }
    }
}

- (void)openProfile {
    if ([self.delegate respondsToSelector:@selector(showProfileOfFriend:)]) {
        PFUser *user = [self.activityObject objectForKey:@"user"];
        Friend *friend = [[Friend alloc] init];
        friend.friendID = user[kUserFacebookIDKey];
        friend.name = user[kUserDisplayNameKey];
        friend.firstName = user[@"firstName"];
        friend.friendsArray = user[@"tethrFriends"];
        friend.followersArray = user[@"followers"];
        friend.tethrCount = [user[@"tethrs"] integerValue];
        friend.object = user;
        friend.isPrivate = [user[@"private"] boolValue];
        friend.city = user[@"cityLocation"];
        friend.timeLastUpdated = user[kUserTimeLastUpdatedKey];
        friend.status = [user[kUserStatusKey] boolValue];
        friend.statusMessage = user[kUserStatusMessageKey];
        [self.delegate showProfileOfFriend:friend];
    }
}

-(void)showLikes:(NSMutableSet*)likes{
    if ([self.delegate respondsToSelector:@selector(showLikes:)]) {
        [self.delegate showLikes:likes];
    }
}

-(void)showComments {
    if ([self.delegate respondsToSelector:@selector(showComments:)]) {
        [self.delegate showComments:self.activityObject];
    }
}

-(void)postSettingsClicked {
    if ([self.delegate respondsToSelector:@selector(postSettingsClicked:)]) {
        [self.delegate postSettingsClicked:self.activityObject];
    }
}

@end
