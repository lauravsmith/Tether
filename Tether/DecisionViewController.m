//
//  DecisionViewController.m
//  Tether
//
//  Created by Laura Smith on 11/24/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "DecisionViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#define BOTTOM_BAR_HEIGHT 45.0
#define PADDING 20.0
#define PROFILE_IMAGE_VIEW_SIZE 80.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

@interface DecisionViewController ()

@property (strong, nonatomic) UILabel *tethrLabel;
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UISlider *slider;
@property (nonatomic, strong) FBProfilePictureView *userProfilePictureView;

@end

@implementation DecisionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BlackTexture"]];
    backgroundImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - BOTTOM_BAR_HEIGHT);
    backgroundImageView.alpha = 0.80;
    [self.view addSubview:backgroundImageView];
    
    // top bar setup
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:self.topBar];
    
    self.tethrLabel = [[UILabel alloc] init];
    UIFont *helvetica = [UIFont fontWithName:@"HelveticaNeueLTStd-UltLt" size:25];
    self.tethrLabel.font = helvetica;
    self.tethrLabel.text = @"tethr";
    [self.tethrLabel setTextColor:[UIColor whiteColor]];
    CGSize size = [self.tethrLabel.text sizeWithAttributes:@{NSFontAttributeName:helvetica}];
    self.tethrLabel.frame = CGRectMake((self.topBar.frame.size.width - size.width) / 2, (self.topBar.frame.size.height - size.height +STATUS_BAR_HEIGHT) / 2 + 5.0, size.width, size.height);
    [self.topBar addSubview:self.tethrLabel];
    
    UIFont *helveticaNeueLarge = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
    self.numberLabel = [[UILabel alloc] init];
    self.numberLabel.font = helveticaNeueLarge;
    self.numberLabel.textColor = [UIColor whiteColor];
    [self.topBar addSubview:self.numberLabel];
    
    UILabel *questionLabel = [[UILabel alloc] init];
    questionLabel.text = @"Are you going out?";
    questionLabel.textColor = [UIColor whiteColor];
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:15];
    questionLabel.font = montserrat;
    size = [questionLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    questionLabel.frame = CGRectMake((self.view.frame.size.width - size.width)/ 2, self.topBar.frame.size.height +  200.0, size.width, size.height);
    [self.view addSubview:questionLabel];
    
    self.slider = [[UISlider alloc] initWithFrame:CGRectMake(0, self.topBar.frame.size.height, 80.0, 20.0)];
    self.slider.transform = CGAffineTransformMakeScale(0.75, 0.75);
    CGRect frame = self.slider.frame;
    frame.origin.x = (self.view.frame.size.width - self.slider.frame.size.width) / 2.0;
    frame.origin.y = questionLabel.frame.origin.y + questionLabel.frame.size.height + 15.0;
    self.slider.frame = frame;
    [self.slider setMinimumTrackTintColor:[UIColor clearColor]];
    [self.slider setMaximumTrackTintColor:[UIColor clearColor]];
    self.slider.backgroundColor = [UIColor grayColor];
    self.slider.layer.cornerRadius = 8.0;
    self.slider.value = 1;
    self.slider.minimumValue = 0;
    self.slider.maximumValue = 2;
    self.slider.continuous = NO;
    
    [self.slider addTarget:self
                    action:@selector(sliderDidEndSliding:)
          forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
    [self.view addSubview:self.slider];
    
    UIButton *noButton = [[UIButton alloc] init];
    noButton.titleLabel.font = montserrat;
    [noButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [noButton setTitle:@"NO" forState:UIControlStateNormal];
    size = [noButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    noButton.frame = CGRectMake(self.slider.frame.origin.x - size.width - 5.0, self.slider.frame.origin.y, size.width, size.height);
    [noButton addTarget:self action:@selector(handleNoButton:) forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview:noButton];
    
    UIButton *yesButton = [[UIButton alloc] init];
    yesButton.titleLabel.font = montserrat;
    [yesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [yesButton setTitle:@"YES" forState:UIControlStateNormal];
    size = [yesButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    yesButton.frame = CGRectMake(self.slider.frame.origin.x + self.slider.frame.size.width + 5.0, self.slider.frame.origin.y, size.width, size.height);
    [yesButton addTarget:self action:@selector(handleYesButton:) forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview:yesButton];
    
    self.view.backgroundColor = [UIColor clearColor];
}

-(void)layoutNumberLabel {
    UIFont *helveticaNeue = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
    CGSize size = [self.numberLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeue}];
    self.numberLabel.frame = CGRectMake(PADDING, self.tethrLabel.frame.origin.y - STATUS_BAR_HEIGHT / 2.0 - 1.0, size.width, size.height);
    [self.topBar addSubview:self.numberLabel];
}

-(void)addProfileImageView {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.userProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)sharedDataManager.facebookId pictureCropping:FBProfilePictureCroppingSquare];
    self.userProfilePictureView.layer.cornerRadius = 12.0;
    self.userProfilePictureView.clipsToBounds = YES;
    [self.userProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    self.userProfilePictureView.frame = CGRectMake((self.view.frame.size.width - PROFILE_IMAGE_VIEW_SIZE) / 2.0 , self.topBar.frame.size.height + 100.0, PROFILE_IMAGE_VIEW_SIZE, PROFILE_IMAGE_VIEW_SIZE);

    UIImage *maskingImage = [UIImage imageNamed:@"LocationIcon"];
    CALayer *maskingLayer = [CALayer layer];
    CGRect frame = self.userProfilePictureView.bounds;
    frame.origin.x = -7.0;
    frame.origin.y = -7.0;
    frame.size.width += 14.0;
    frame.size.height += 14.0;
    maskingLayer.frame = frame;
    [maskingLayer setContents:(id)[maskingImage CGImage]];
    [self.userProfilePictureView.layer setMask:maskingLayer];
    [self.view addSubview:self.userProfilePictureView];
}

-(IBAction)sliderDidEndSliding:(id)sender {
     NSLog(@"%f", self.slider.value);
    [UIView animateWithDuration:0.2
    animations:^{
        if (self.slider.value < 1) {
            self.slider.value = 0.0;
        } else {
            self.slider.value = 2.0;
        }
    } completion:^(BOOL finished) {
        if (self.slider.value == 0.0) {
            if ([self.delegate respondsToSelector:@selector(handleChoice:)]) {
                [self.delegate handleChoice:NO];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(handleChoice:)]) {
                [self.delegate handleChoice:YES];
            }
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)handleYesButton:(id)sender{
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.slider.value = 2;
                     } completion:^(BOOL finished) {
                         if ([self.delegate respondsToSelector:@selector(handleChoice:)]) {
                             [self.delegate handleChoice:YES];
                         }
                     }];
}

-(IBAction)handleNoButton:(id)sender{
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.slider.value = 0;
                     } completion:^(BOOL finished) {
                         if ([self.delegate respondsToSelector:@selector(handleChoice:)]) {
                             [self.delegate handleChoice:NO];
                         }
                     }];
}

@end
