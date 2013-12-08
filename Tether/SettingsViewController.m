//
//  SettingsViewController.m
//  Tether
//
//  Created by Laura Smith on 11/28/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "AppDelegate.h"
#import "SettingsViewController.h"

#define BORDER_WIDTH 4.0
#define PADDING 15.0

@interface SettingsViewController ()

@property (retain, nonatomic) UIButton * settingsButton;
@property (retain, nonatomic) UIView * topBarView;
@property (retain, nonatomic) UILabel * settingsLabel;
@property (retain, nonatomic) UITextView *cityTextView;
@property (retain, nonatomic) UIButton * logoutButton;
@property (retain, nonatomic) UISwitch * setLocationSwitch;
@property (retain, nonatomic) UIView * whiteLineView;
@property (retain, nonatomic) UIView * whiteLineView2;
@property (retain, nonatomic) UILabel * defaultCityLabel;
@property (retain, nonatomic) UILabel * locationSwitchLabel;
@property (retain, nonatomic) NSUserDefaults * userDetails;
@property (retain, nonatomic) UISwitch * goingOutSwitch;
@property (retain, nonatomic) UILabel * goingOutLabel;

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userDetails = [NSUserDefaults standardUserDefaults];
    [self.view setBackgroundColor:UIColorFromRGB(0xD6D6D6)];
    
    self.topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70.0)];
    self.topBarView.backgroundColor = UIColorFromRGB(0xF3F3F3);
    [self.view addSubview:self.topBarView];
    
    self.topBarView.layer.masksToBounds = NO;
    self.topBarView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.topBarView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.topBarView.layer.shadowOpacity = 0.5f;
    
    UIImage *gearImage = [UIImage imageNamed:@"Gear"];
    self.settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40.0, 20.0, 30, 30)];
    [self.settingsButton setImage:gearImage forState:UIControlStateNormal];
    [self.view addSubview:self.settingsButton];
    [self.settingsButton addTarget:self action:@selector(handleCloseSettings:) forControlEvents:UIControlEventTouchDown];
    
    self.settingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, (self.topBarView.frame.size.height + 10.0 - 40.0) / 2, 200.0, 40.0)];
    self.settingsLabel.text = @"Me";
    [self.settingsLabel setTextColor:[UIColor whiteColor]];
    UIFont *champagne = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:30];
    self.settingsLabel.font = champagne;
    [self.topBarView addSubview:self.settingsLabel];
    
    self.userProfilePictureView.layer.cornerRadius = 24.0;
    self.userProfilePictureView.clipsToBounds = YES;
    [self.userProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.userProfilePictureView.layer setBorderWidth:BORDER_WIDTH];
    self.userProfilePictureView.frame = CGRectMake(10.0, 100.0, 50.0, 50.0);
    [self.view addSubview:self.userProfilePictureView];
    
    self.logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(100.0, 100.0, 100.0, 50.0)];
    [self.logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:UIColorFromRGB(0x770051) forState:UIControlStateNormal];
    UIFont *smallChampagneFont = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:28];
    self.logoutButton.titleLabel.font = smallChampagneFont;
    [self.logoutButton addTarget:self action:@selector(logoutButtonWasPressed:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.logoutButton];
    
    // white line separator
    self.whiteLineView = [[UIView alloc] initWithFrame:CGRectMake(0, self.topBarView.frame.size.height + 100.0, self.view.frame.size.width, 2.0)];
    [self.whiteLineView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.whiteLineView];
    
    self.defaultCityLabel = [[UILabel alloc] init];
    self.defaultCityLabel.text = @"Default City";
    self.defaultCityLabel.font = smallChampagneFont;
    self.defaultCityLabel.textColor = [UIColor whiteColor];
    CGSize textLabelSize = [self.defaultCityLabel.text sizeWithAttributes:@{NSFontAttributeName: smallChampagneFont}];
    self.defaultCityLabel.frame = CGRectMake(PADDING, self.whiteLineView.frame.origin.y + PADDING, textLabelSize.width, textLabelSize.height);
    [self.view addSubview:self.defaultCityLabel];
    
    self.locationSwitchLabel = [[UILabel alloc] init];
    self.locationSwitchLabel.text = @"Use current location?";
    UIFont *subheadingFont = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:16];
    self.locationSwitchLabel.font = subheadingFont;
    self.locationSwitchLabel.textColor = [UIColor whiteColor];
    CGSize locationSwitchLabelSize = [self.locationSwitchLabel.text sizeWithAttributes:@{NSFontAttributeName: subheadingFont}];
    self.locationSwitchLabel.frame = 
    
    CGRectMake(PADDING, self.defaultCityLabel.frame.origin.y + self.defaultCityLabel.frame.size.height + PADDING, locationSwitchLabelSize.width, locationSwitchLabelSize.height);
    [self.view addSubview:self.locationSwitchLabel];
    
    UILabel *noLabel = [[UILabel alloc] init];
    noLabel.text = @"No";
    UIFont *switchLabelFont = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:25];
    noLabel.font = switchLabelFont;
    noLabel.textColor = [UIColor whiteColor];
    CGSize noLabelSize = [noLabel.text sizeWithAttributes:@{NSFontAttributeName: switchLabelFont}];
    noLabel.frame = CGRectMake(PADDING, self.locationSwitchLabel.frame.origin.y + self.locationSwitchLabel.frame.size.height + PADDING, noLabelSize.width, noLabelSize.height);
    [self.view addSubview:noLabel];
    
    self.setLocationSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(noLabel.frame.origin.x + noLabel.frame.size.width + 2.0, self.locationSwitchLabel.frame.origin.y + self.locationSwitchLabel.frame.size.height + PADDING, 50.0, 20.0)];
    [self.setLocationSwitch setOnTintColor:UIColorFromRGB(0xF3F3F3)];
    [self.setLocationSwitch addTarget:self action:@selector(locationSwitchChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.setLocationSwitch];
    self.setLocationSwitch.on = [self.userDetails boolForKey:@"useCurrentLocation"];
    
    UILabel *yesLabel = [[UILabel alloc] init];
    yesLabel.text = @"Yes";
    yesLabel.font = switchLabelFont;
    yesLabel.textColor = [UIColor whiteColor];
    CGSize yesLabelSize = [yesLabel.text sizeWithAttributes:@{NSFontAttributeName: switchLabelFont}];
    yesLabel.frame = CGRectMake(self.setLocationSwitch.frame.origin.x + self.setLocationSwitch.frame.size.width + 2.0, self.locationSwitchLabel.frame.origin.y + self.locationSwitchLabel.frame.size.height + PADDING, yesLabelSize.width, yesLabelSize.height);
    [self.view addSubview:yesLabel];
    
    self.cityTextView = [[UITextView alloc] initWithFrame:CGRectMake(PADDING, self.setLocationSwitch.frame.origin.y + self.setLocationSwitch.frame.size.height + PADDING, self.view.frame.size.width - PADDING * 2, 30.0)];
    NSString *location = [NSString stringWithFormat:@"%@,%@",[self.userDetails objectForKey:@"city"], [self.userDetails objectForKey:@"state"]];
    self.cityTextView.text = [location uppercaseString];
    UIFont *textViewFont = [UIFont fontWithName:@"Champagne&Limousines-Italic" size:18];
    self.cityTextView.font = textViewFont;
    self.cityTextView.textColor = UIColorFromRGB(0x770051);
    self.cityTextView.layer.cornerRadius = 5.0;
    [self.cityTextView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.cityTextView];
    [self.cityTextView setEditable:!self.setLocationSwitch.on];
    
    self.whiteLineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, self.cityTextView.frame.origin.y + self.cityTextView.frame.size.height + PADDING, self.view.frame.size.width, 2.0)];
    [self.whiteLineView2 setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.whiteLineView2];
    
    self.goingOutLabel = [[UILabel alloc] init];
    self.goingOutLabel.text = @"Going out?";
    self.goingOutLabel.font = subheadingFont;
    self.goingOutLabel.textColor = [UIColor whiteColor];
    locationSwitchLabelSize = [self.goingOutLabel.text sizeWithAttributes:@{NSFontAttributeName: subheadingFont}];
    self.goingOutLabel.frame =
    CGRectMake(PADDING, self.whiteLineView2.frame.origin.y + self.whiteLineView2.frame.size.height + PADDING, locationSwitchLabelSize.width, locationSwitchLabelSize.height);
    [self.view addSubview:self.goingOutLabel];
    
    UILabel *noLabel2 = [[UILabel alloc] init];
    noLabel2.text = @"No";
    noLabel2.font = switchLabelFont;
    noLabel2.textColor = [UIColor whiteColor];
    noLabel2.frame = CGRectMake(PADDING, self.goingOutLabel.frame.origin.y + self.goingOutLabel.frame.size.height + PADDING, noLabelSize.width, noLabelSize.height);
    [self.view addSubview:noLabel2];
    
    self.goingOutSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(noLabel.frame.origin.x + noLabel.frame.size.width + 2.0, self.goingOutLabel.frame.origin.y + self.goingOutLabel.frame.size.height + PADDING, 50.0, 20.0)];
    [self.goingOutSwitch setOnTintColor:UIColorFromRGB(0xF3F3F3)];
    [self.goingOutSwitch addTarget:self action:@selector(locationSwitchChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.goingOutSwitch];
    self.goingOutSwitch.on = [self.userDetails boolForKey:@"status"];
    
    UILabel *yesLabel2 = [[UILabel alloc] init];
    yesLabel2.text = @"Yes";
    yesLabel2.font = switchLabelFont;
    yesLabel2.textColor = [UIColor whiteColor];
    yesLabel2.frame = CGRectMake(self.goingOutSwitch.frame.origin.x + self.goingOutSwitch.frame.size.width + 2.0, self.goingOutLabel.frame.origin.y + self.goingOutLabel.frame.size.height + PADDING, yesLabelSize.width, yesLabelSize.height);
    [self.view addSubview:yesLabel2];
}

- (void)locationSwitchChange:(UISwitch *)theSwitch {
    if (theSwitch == self.setLocationSwitch) {
        [self.userDetails setBool:theSwitch.on forKey:@"useCurrentLocation"];
        [self.cityTextView setEditable:!self.setLocationSwitch.on];
    } else {
        [self.userDetails setBool:theSwitch.on forKey:@"status"];
        if ([self.delegate respondsToSelector:@selector(updateStatus)]) {
            [self.delegate updateStatus];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handleCloseSettings:(id)sender {
    if ([self.delegate respondsToSelector:@selector(closeSettings)]) {
        [self.delegate closeSettings];
    }
}

-(IBAction)logoutButtonWasPressed:(id)sender {
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate logoutPressed];
}

@end
