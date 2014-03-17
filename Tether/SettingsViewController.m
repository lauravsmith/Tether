//
//  SettingsViewController.m
//  Tether
//
//  Created by Laura Smith on 11/28/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"
#import "Datastore.h"
#import "Flurry.h"
#import "ManageFriendsViewController.h"
#import "SettingsViewController.h"
#import "TethrTextField.h"

#import "UIImage+ImageEffects.h"

#define PADDING 15.0
#define PROFILE_IMAGE_VIEW_SIZE 80.0
#define SEGMENT_HEIGHT 45.0
#define SLIDE_TIMING 0.6
#define STATUS_BAR_HEIGHT 20.0
#define STATUS_MESSAGE_LENGTH 35.0
#define TABLE_VIEW_HEIGHT 277.0
#define TOP_BAR_HEIGHT 70.0

#define degreesToRadian(x) (M_PI * (x) / 180.0)

static NSString *kGeoNamesAccountName = @"lsmit87";

@interface SettingsViewController () <ILGeoNamesLookupDelegate, ManageFriendsViewControllerDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, NSURLConnectionDataDelegate>

@property (retain, nonatomic) UITextField *statusMessageTextField;
@property (retain, nonatomic) UIButton * doneButton;
@property (retain, nonatomic) UIButton * largeDoneButton;
@property (retain, nonatomic) UIView * topBarView;
@property (retain, nonatomic) UITextField *cityTextField;
@property (retain, nonatomic) UIButton * logoutButton;
@property (retain, nonatomic) UIButton * largeLogoutButton;
@property (retain, nonatomic) UISwitch * setLocationSwitch;
@property (retain, nonatomic) UILabel * defaultCityLabel;
@property (retain, nonatomic) UILabel * goingOutLabel;
@property (retain, nonatomic) UITableView * searchResultsTableView;
@property (retain, nonatomic) UITableViewController * searchResultsTableViewController;
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (retain, nonatomic) UIButton * cancelSearchButton;
@property (retain, nonatomic) UIActivityIndicatorView * activityIndicator;
@property (retain, nonatomic) UIButton * inviteFriendsButton;
@property (retain, nonatomic) UIButton * arrowButton;
@property (retain, nonatomic) ManageFriendsViewController *manageVC;
@property (retain, nonatomic) UIView *backgroundView;
@property (retain, nonatomic) UILabel *dotLabel;
@property (retain, nonatomic) UILabel * seeFriendsEverywhereLabel;
@property (retain, nonatomic) UISwitch * seeFriendsEverywhereSwitch;

@end

@implementation SettingsViewController

@synthesize searchResults;
@synthesize delegate;
@synthesize geocoder;

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
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.backgroundView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.backgroundView];
    
    self.topBarView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, TOP_BAR_HEIGHT)];
    [self.topBarView setBackgroundColor:[UIColor whiteColor]];
    [self.topBarView setHidden:YES];
    
    self.topBarView.layer.masksToBounds = NO;
    self.topBarView.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.topBarView.layer.shadowRadius = 5;
    self.topBarView.layer.shadowOpacity = 0.8;
    
    [self.view addSubview:self.topBarView];
    
    UITapGestureRecognizer *closeKeyBoardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    self.backgroundView.userInteractionEnabled = YES;
    [self.backgroundView addGestureRecognizer:closeKeyBoardTap];
    
    UISwipeGestureRecognizer * swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
    [swipeDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.view addGestureRecognizer:swipeDown];
    
    [self addProfileImageView];
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14];
    self.statusMessageTextField = [[UITextField alloc] init];
    self.statusMessageTextField.delegate = self;
    self.statusMessageTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter a status message" attributes:@{NSForegroundColorAttributeName:UIColorFromRGB(0x1d1d1d)}];
    [self.statusMessageTextField setBackgroundColor:[UIColor clearColor]];
    [self.statusMessageTextField setTextColor:UIColorFromRGB(0x1d1d1d)];
    [self.statusMessageTextField setFont:montserrat];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    CGSize statusMessageSize;
    if (sharedDataManager.statusMessage && ![sharedDataManager.statusMessage isEqualToString:@""]) {
        self.statusMessageTextField.text = sharedDataManager.statusMessage;
        statusMessageSize = [sharedDataManager.statusMessage sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    } else {
        statusMessageSize = [@"Enter a status message" sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    }
    self.statusMessageTextField.frame = CGRectMake((self.view.frame.size.width - statusMessageSize.width) / 2.0, self.userProfilePictureView.frame.origin.y + self.userProfilePictureView.frame.size.height + PADDING + 2.0, statusMessageSize.width, statusMessageSize.height);
    self.statusMessageTextField.delegate = self;
    [self.view addSubview:self.statusMessageTextField];
    
    UIView *whiteView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 220.0, self.view.frame.size.width, self.view.frame.size.height - 220.0)];
    [whiteView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:whiteView];
    
    UITapGestureRecognizer *closeKeyBoardTap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    whiteView.userInteractionEnabled = YES;
    [whiteView addGestureRecognizer:closeKeyBoardTap2];
    
    UIView *segment2 = [[UIView alloc] initWithFrame:CGRectMake(0.0, SEGMENT_HEIGHT, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [segment2 setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
    [whiteView addSubview:segment2];
    
    self.defaultCityLabel = [[UILabel alloc] init];
    self.defaultCityLabel.text = @"Use current location";
    self.defaultCityLabel.font = montserrat;
    self.defaultCityLabel.textColor = UIColorFromRGB(0x1d1d1d);
    CGSize textLabelSize = [self.defaultCityLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.defaultCityLabel.frame = CGRectMake(PADDING, (SEGMENT_HEIGHT - textLabelSize.height) / 2.0, textLabelSize.width, textLabelSize.height);
    [segment2 addSubview:self.defaultCityLabel];
    
    self.setLocationSwitch = [[UISwitch alloc] init];
    self.setLocationSwitch.frame = CGRectMake(self.view.frame.size.width - 70.0, (SEGMENT_HEIGHT - self.setLocationSwitch.frame.size.height) / 2.0, 0, 0);
    [self.setLocationSwitch setOnTintColor:UIColorFromRGB(0x8e0528)];
    [self.setLocationSwitch setThumbTintColor:UIColorFromRGB(0xc8c8c8)];
    [self.setLocationSwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
    [segment2 addSubview:self.setLocationSwitch];
    [self.setLocationSwitch setOn:[userDetails boolForKey:@"useCurrentLocation"]];
    NSLog(@"Switch is: %d", [self.setLocationSwitch isOn]);
    
    //city search
    self.cityTextField = [[UITextField  alloc] init];
    self.cityTextField.delegate = self;
    NSString *location = [NSString stringWithFormat:@"%@, %@",[userDetails objectForKey:@"city"], [userDetails objectForKey:@"state"]];
    if ([userDetails objectForKey:@"city"] == NULL || [userDetails objectForKey:@"state"] == NULL) {
        location = @"Enter your city";
    }
    self.cityTextField.text = [location uppercaseString];
    self.cityTextField.placeholder = @"Search by city name";
    UIFont *textViewFont = [UIFont fontWithName:@"Montserrat" size:16];
    self.cityTextField.font = textViewFont;
    CGSize cityLabelSize = [self.cityTextField.text sizeWithAttributes:@{NSFontAttributeName: textViewFont}];
    self.cityTextField.frame = CGRectMake((self.view.frame.size.width - cityLabelSize.width) / 2.0, 184.0, cityLabelSize.width, cityLabelSize.height);
    self.cityTextField.textColor = UIColorFromRGB(0x1d1d1d);
    self.cityTextField.layer.cornerRadius = 2.0;
    [self.cityTextField setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.cityTextField];
    self.cityTextField.enabled = !self.setLocationSwitch.on;
    self.cityTextField .clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.cityTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.cityTextField.tag = 1;
    
    self.dotLabel = [[UILabel alloc] init];
    self.dotLabel.text = @".";
    self.dotLabel.font = montserrat;
    textLabelSize = [self.dotLabel.text  sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.dotLabel.frame = CGRectMake((self.view.frame.size.width - textLabelSize.width) / 2.0, (self.statusMessageTextField.frame.origin.y - self.statusMessageTextField.frame.size.height / 2.0 + self.cityTextField.frame.origin.y) / 2.0, textLabelSize.width, textLabelSize.height);
    [self.dotLabel setTextColor:UIColorFromRGB(0x1d1d1d)];
    [self.view addSubview:self.dotLabel];
    
    //pull city search results from geonames.org
    self.geocoder = [[ILGeoNamesLookup alloc] initWithUserID:kGeoNamesAccountName];
    self.geocoder.delegate = self;
    
    self.cancelSearchButton = [[UIButton alloc] init];
    [self.cancelSearchButton addTarget:self action:@selector(cancelSearchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelSearchButton setBackgroundColor:[UIColor clearColor]];
    [self.cancelSearchButton setTitleColor:UIColorFromRGB(0x1d1d1d) forState:UIControlStateNormal];
    [self.cancelSearchButton setTitle:@"Cancel" forState:UIControlStateNormal];
    UIFont *cancelButtonFont = [UIFont fontWithName:@"Montserrat" size:12];
    CGSize size = [self.cancelSearchButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: cancelButtonFont}];
    self.cancelSearchButton.frame = CGRectMake(self.view.frame.size.width - size.width - PADDING, STATUS_BAR_HEIGHT + PADDING + 5.0, size.width, size.height);
    self.cancelSearchButton.titleLabel.font = cancelButtonFont;
    self.cancelSearchButton.hidden = YES;
    [self.view addSubview:self.cancelSearchButton];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 50.0) / 2.0, TOP_BAR_HEIGHT, 50.0, 50.0)];
    [self.activityIndicator setColor:[UIColor blackColor]];
    [self.view addSubview:self.activityIndicator];
    
    self.goingOutLabel = [[UILabel alloc] init];
    self.goingOutLabel.text = @"Going out";
    self.goingOutLabel.font = montserrat;
    self.goingOutLabel.textColor = UIColorFromRGB(0x1d1d1d);
    size = [self.goingOutLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.goingOutLabel.frame =
    CGRectMake(PADDING, (SEGMENT_HEIGHT - size.height) / 2.0, size.width, size.height);
    [whiteView addSubview:self.goingOutLabel];
    
    self.goingOutSwitch = [[UISwitch alloc] init];
    self.goingOutSwitch.frame = CGRectMake(self.view.frame.size.width - 70.0, self.goingOutLabel.frame.origin.y - 6.0, 0, 0);
    [self.goingOutSwitch setOnTintColor:UIColorFromRGB(0x8e0528)];
    [self.goingOutSwitch setThumbTintColor:UIColorFromRGB(0xc8c8c8)];
    [self.goingOutSwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
    [whiteView addSubview:self.goingOutSwitch];
    self.goingOutSwitch.on = [userDetails boolForKey:@"status"];
    
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:16];
    self.logoutButton = [[UIButton alloc] init];
    [self.logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:UIColorFromRGB(0x1d1d1d) forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateHighlighted];
    self.logoutButton.titleLabel.font = montserratLarge;
    size = [self.logoutButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLarge}];
    self.logoutButton.frame = CGRectMake(self.view.frame.size.width - size.width - PADDING, self.view.frame.size.height - size.height - PADDING, size.width, size.height);
    [self.logoutButton addTarget:self action:@selector(logoutButtonWasPressed:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.logoutButton];
    
    self.largeLogoutButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, self.logoutButton.frame.origin.y - PADDING, self.view.frame.size.width / 2.0, self.view.frame.size.height - self.logoutButton.frame.origin.y)];
    [self.largeLogoutButton addTarget:self action:@selector(logoutButtonWasPressed:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.largeLogoutButton];

    self.doneButton = [[UIButton alloc] init];
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.doneButton setTitleColor:UIColorFromRGB(0x1d1d1d) forState:UIControlStateNormal];
    [self.doneButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateHighlighted];
    [self.doneButton addTarget:self action:@selector(handleCloseSettings:) forControlEvents:UIControlEventTouchDown];
    self.doneButton.titleLabel.font = montserratLarge;
    CGSize buttonSize = [self.doneButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLarge}];
    self.doneButton.frame = CGRectMake(PADDING, self.view.frame.size.height - buttonSize.height - PADDING, buttonSize.width, buttonSize.height);
    [self.view addSubview:self.doneButton];
    
    self.largeDoneButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, self.doneButton.frame.origin.y - PADDING, self.view.frame.size.width / 2.0, self.view.frame.size.height - self.doneButton.frame.origin.y)];
    [self.largeDoneButton addTarget:self action:@selector(handleCloseSettings:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.largeDoneButton];
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, TABLE_VIEW_HEIGHT)];
    [self.searchResultsTableView setBackgroundColor:[UIColor whiteColor]];
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    self.searchResultsTableView.hidden = YES;
    [self.view bringSubviewToFront:self.searchResultsTableView];
    
    [self.view addSubview:self.searchResultsTableView];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    [self.searchResultsTableView reloadData];
    
    NSURL *profilePictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", sharedDataManager.facebookId]];
    NSURLRequest *profilePictureURLRequest = [NSURLRequest requestWithURL:profilePictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0f]; // Facebook profile picture cache policy: Expires in 2 weeks
    [NSURLConnection connectionWithRequest:profilePictureURLRequest delegate:self];
    
    self.seeFriendsEverywhereLabel = [[UILabel alloc] init];
    self.seeFriendsEverywhereLabel.text = @"See friends everywhere";
    self.seeFriendsEverywhereLabel.font = montserrat;
    self.seeFriendsEverywhereLabel.textColor = UIColorFromRGB(0x1d1d1d);
    textLabelSize = [self.seeFriendsEverywhereLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.seeFriendsEverywhereLabel.frame = CGRectMake(PADDING, segment2.frame.origin.y + SEGMENT_HEIGHT + (SEGMENT_HEIGHT - textLabelSize.height) / 2.0, textLabelSize.width, textLabelSize.height);
    [whiteView addSubview:self.seeFriendsEverywhereLabel];
    
    self.seeFriendsEverywhereSwitch = [[UISwitch alloc] init];
    self.seeFriendsEverywhereSwitch.frame = CGRectMake(self.view.frame.size.width - 70.0, segment2.frame.origin.y + SEGMENT_HEIGHT + self.goingOutLabel.frame.origin.y - 6.0, 0, 0);
    [self.seeFriendsEverywhereSwitch setOnTintColor:UIColorFromRGB(0x8e0528)];
    [self.seeFriendsEverywhereSwitch setThumbTintColor:UIColorFromRGB(0xc8c8c8)];
    [self.seeFriendsEverywhereSwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
    [whiteView addSubview:self.seeFriendsEverywhereSwitch];
    self.seeFriendsEverywhereSwitch.on = ![userDetails boolForKey:@"cityFriendsOnly"];
    
    UIView *segment4 = [[UIView alloc] initWithFrame:CGRectMake(0.0, SEGMENT_HEIGHT*3, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [segment4 setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
    [whiteView addSubview:segment4];
    
    UIButton *manageButton = [[UIButton alloc] init];
    [manageButton setTitle:@"Manage friends" forState:UIControlStateNormal];
    manageButton.titleLabel.font = montserrat;
    size = [manageButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    manageButton.frame = CGRectMake(PADDING, (SEGMENT_HEIGHT - size.height) / 2.0, size.width, size.height);
    [manageButton setTitleColor:UIColorFromRGB(0x1d1d1d) forState:UIControlStateNormal];
    [manageButton addTarget:self action:@selector(showManage:) forControlEvents:UIControlEventTouchUpInside];
    [segment4 addSubview:manageButton];
    
    UIButton *manageButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [manageButtonLarge addTarget:self action:@selector(showManage:) forControlEvents:UIControlEventTouchUpInside];
    [segment4 addSubview:manageButtonLarge];
    
    self.arrowButton = [[UIButton alloc] init];
    [self.arrowButton setImage:[UIImage imageNamed:@"BlackTriangle"] forState:UIControlStateNormal];
    self.arrowButton.frame = CGRectMake(self.view.frame.size.width - 11.0 - PADDING, (SEGMENT_HEIGHT - 7.0) / 2.0, 7.0, 11.0);
    self.arrowButton.transform = CGAffineTransformMakeRotation(degreesToRadian(180));
    [self.arrowButton addTarget:self
                         action:@selector(showManage:)
               forControlEvents:UIControlEventTouchUpInside];
    [segment4 addSubview:self.arrowButton];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"connection loaded");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    UIImage *profileImage = [UIImage imageWithData:data];
    UIImage *blurredImage = [profileImage applyBlurWithRadius:1.0 tintColor:nil saturationDeltaFactor:0.8 maskImage:nil];
    UIImageView *profileImageView = [[UIImageView alloc] initWithImage:blurredImage];
    profileImageView.frame = CGRectMake(-20.0, -40.0, self.view.frame.size.width + 40.0, 350.0);
    profileImageView.contentMode = UIViewContentModeScaleAspectFill;
    profileImageView.alpha = 0.8;
    
    BOOL isDark = [self isDarkImage:blurredImage];
    
    if (isDark) {
        [self.statusMessageTextField setTextColor:[UIColor whiteColor]];
        self.statusMessageTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter a status message" attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        [self.cityTextField setTextColor:[UIColor whiteColor]];
        [self.dotLabel setTextColor:[UIColor whiteColor]];
    }

    [self.view addSubview:profileImageView];
    [self.view sendSubviewToBack:profileImageView];
    [self.view sendSubviewToBack:self.backgroundView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
    // when the view slides in, its significant enough that a screen change notification should be posted
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

-(void)addProfileImageView {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.userProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)sharedDataManager.facebookId pictureCropping:FBProfilePictureCroppingSquare];
    self.userProfilePictureView.layer.cornerRadius = 12.0;
    self.userProfilePictureView.clipsToBounds = YES;
    [self.userProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    self.userProfilePictureView.frame = CGRectMake((self.view.frame.size.width - PROFILE_IMAGE_VIEW_SIZE - 3) / 2.0 , STATUS_BAR_HEIGHT + PADDING, PROFILE_IMAGE_VIEW_SIZE, PROFILE_IMAGE_VIEW_SIZE);
    // mask test
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

-(BOOL) isDarkImage:(UIImage*)inputImage{
    BOOL isDark = FALSE;
    if (inputImage) {
        
        //    CFDataRef imageData = CGDataProviderCopyData(CGImageGetDataProvider(inputImage.CGImage));
        
        CFMutableDataRef imageData = CFDataCreateMutableCopy(0, 0, CGDataProviderCopyData(CGImageGetDataProvider(inputImage.CGImage)));
        
        const UInt8 *pixels = CFDataGetBytePtr(imageData);
        
        int darkPixels = 0;
        
        int length = CFDataGetLength(imageData);
        int const darkPixelThreshold = (inputImage.size.width*inputImage.size.height)*.45;
        
        for(int i=0; i<length; i+=4)
        {
            int r = pixels[i];
            int g = pixels[i+1];
            int b = pixels[i+2];
            
            //luminance calculation gives more weight to r and b for human eyes
            float luminance = (0.299*r + 0.587*g + 0.114*b);
            if (luminance<150) darkPixels ++;
        }
        
        if (darkPixels >= darkPixelThreshold)
            isDark = YES;
        
        CFRelease(imageData);
    }
    return isDark;
}

- (NSMutableArray *)searchResults
{
	if(!searchResults)
		searchResults = [[NSMutableArray alloc] init];
	
	return searchResults;
}

-(void)closeSearchResultsTableView {
    [self.searchResults removeAllObjects];
    self.searchResultsTableView.hidden = YES;
    [self.searchResultsTableView reloadData];

    [self.topBarView setHidden:YES];
    [self.cancelSearchButton setHidden:YES];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         UIFont *textViewFont = [UIFont fontWithName:@"Montserrat" size:16];
                         CGSize cityLabelSize = [self.cityTextField.text sizeWithAttributes:@{NSFontAttributeName: textViewFont}];
                         self.cityTextField.frame = CGRectMake((self.view.frame.size.width - cityLabelSize.width) / 2.0, 185.0, cityLabelSize.width, cityLabelSize.height);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             self.cityTextField.tag = 1;
                         }
                     }];
    [self.cityTextField resignFirstResponder];
}

-(void)resettingNewLocationHasFinished {
    [self closeSearchResultsTableView];
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSString *location = [NSString stringWithFormat:@"%@, %@",[userDetails objectForKey:@"city"], [userDetails objectForKey:@"state"]];
    self.cityTextField.text = [location uppercaseString];
    
    UIFont *textViewFont = [UIFont fontWithName:@"Montserrat" size:16];
    CGSize cityLabelSize = [self.cityTextField.text sizeWithAttributes:@{NSFontAttributeName: textViewFont}];
    self.cityTextField.frame = CGRectMake((self.view.frame.size.width - cityLabelSize.width) / 2.0, 185.0, cityLabelSize.width, cityLabelSize.height);
    
    self.view.userInteractionEnabled = YES;
}

-(void)dismissKeyboard {
    if ([self.statusMessageTextField isFirstResponder]) {
        [self.statusMessageTextField resignFirstResponder];
        CGSize statusMessageSize;
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14];
        if (![self.statusMessageTextField.text isEqualToString:@""]) {
            statusMessageSize = [self.statusMessageTextField.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
        } else {
            statusMessageSize = [@"Enter a status message" sizeWithAttributes:@{NSFontAttributeName: montserrat}];
        }
        self.statusMessageTextField.frame = CGRectMake((self.view.frame.size.width - statusMessageSize.width) / 2.0, self.userProfilePictureView.frame.origin.y + self.userProfilePictureView.frame.size.height + PADDING + 2.0, statusMessageSize.width, statusMessageSize.height);
    }
}

-(void)swipeDown:(UIGestureRecognizer*)recognizer  {
    if ([self.delegate respondsToSelector:@selector(closeSettings)]) {
        [self.delegate closeSettings];
    }
    [self saveStatusMessage];
}

-(void)saveStatusMessage {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (![self.statusMessageTextField.text isEqualToString:sharedDataManager.statusMessage]) {
        sharedDataManager.statusMessage = self.statusMessageTextField.text;
        PFUser *user = [PFUser currentUser];
        [user setObject:self.statusMessageTextField.text forKey:@"statusMessage"];
        [user saveInBackground];
        NSDictionary *statusParams = [NSDictionary dictionaryWithObjectsAndKeys:
         @"Status", sharedDataManager.statusMessage,
         nil];
        [Flurry logEvent:@"user_updated_status" withParameters:statusParams];
        NSLog(@"PARSE SAVE: saving status message");
        [self notifyBestFriendsOfStatusChange];
    }
    
    CGSize statusMessageSize;
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14];
    if (![self.statusMessageTextField.text isEqualToString:@""]) {
        statusMessageSize = [self.statusMessageTextField.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    } else {
        statusMessageSize = [@"Enter a status message" sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    }
    self.statusMessageTextField.frame = CGRectMake((self.view.frame.size.width - statusMessageSize.width) / 2.0, self.userProfilePictureView.frame.origin.y + self.userProfilePictureView.frame.size.height + PADDING + 2.0, statusMessageSize.width, statusMessageSize.height);
}

-(void)notifyBestFriendsOfStatusChange {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    
    if (![self.statusMessageTextField.text isEqualToString:@""]) {
        for (NSString *friendID in sharedDataManager.bestFriendSet) {
            NSString *messageHeader = [NSString stringWithFormat:@"%@: \"%@\"",sharedDataManager.name, self.statusMessageTextField.text];
            if ([sharedDataManager.tetherFriendsNearbyDictionary objectForKey:friendID]) {
                Friend *friend = [sharedDataManager.tetherFriendsNearbyDictionary objectForKey:friendID];
                PFObject *statusUpdate = [PFObject objectWithClassName:kNotificationClassKey];
                [statusUpdate setObject:sharedDataManager.facebookId forKey:kNotificationSenderKey];
                [statusUpdate setObject:@"" forKey:kNotificationPlaceNameKey];
                [statusUpdate setObject:@"" forKey:kNotificationPlaceIdKey];
                [statusUpdate setObject:messageHeader forKey:kNotificationMessageHeaderKey];
                [statusUpdate setObject:friend.friendID forKey:kNotificationRecipientKey];
                [statusUpdate setObject:[userDetails objectForKey:kUserDefaultsCityKey] forKey:kNotificationCityKey];
                [statusUpdate setObject:@"status" forKey:kNotificationTypeKey];
                [statusUpdate saveInBackground];
            }
        }
    }
    
}

#pragma mark UITextField delegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.cityTextField) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             CGRect frame = self.cityTextField.frame;
                             frame.origin.x = PADDING;
                             frame.origin.y = STATUS_BAR_HEIGHT + PADDING;
                             frame.size.width = self.view.frame.size.width - PADDING*2 - self.cancelSearchButton.frame.size.width;
                             self.cityTextField.frame = frame;
                             [self.view bringSubviewToFront:self.topBarView];
                             [self.view bringSubviewToFront:self.cityTextField];
                             [self.view bringSubviewToFront:self.cancelSearchButton];
                             [self.view bringSubviewToFront:self.searchResultsTableView];
                             [self.view bringSubviewToFront:self.activityIndicator];
                             [self.topBarView setHidden:NO];
                             
                             [self.cityTextField setTextColor:UIColorFromRGB(0x1d1d1d)];
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 self.searchResultsTableView.hidden = NO;
                                 self.cancelSearchButton.hidden = NO;
                                 self.cityTextField.tag = 2;
                             }
                         }];
        self.cityTextField.text = @"";
    }
}

#pragma mark override UITextField methods

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (textField == self.cityTextField) {
        [self.searchResults removeAllObjects];
        [self.searchResultsTableView reloadData];
    }
    return YES;
}

-(void)textFieldDidChange:(UITextField*)textField {
    if (textField == self.cityTextField) {
        [self.searchResults removeAllObjects];
        [self.searchResultsTableView reloadData];
        
        [self.activityIndicator startAnimating];
        // Delay the search 1 second to minimize outstanding requests
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(delayedSearch:) withObject:textField.text afterDelay:0.5];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.cityTextField) {
        return YES;
    } else {
        CGSize statusMessageSize;
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14];
        statusMessageSize = [self.statusMessageTextField.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
        
        CGRect frame = self.statusMessageTextField.frame;
        frame.size.width = statusMessageSize.width + 8.0;
        frame.origin.x = (self.view.frame.size.width - statusMessageSize.width) / 2.0;
        self.statusMessageTextField.frame = frame;

        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > STATUS_MESSAGE_LENGTH) ? NO : YES;
    }
}

-(void)resizeTableView {
    CGRect frame = self.searchResultsTableView.frame;
    frame.size.height = MIN([self.searchResults count] * 44.0, TABLE_VIEW_HEIGHT);
    self.searchResultsTableView.frame = frame;
}

- (void)delayedSearch:(NSString*)searchString
{
	[self.geocoder cancel];
	[self.geocoder search:searchString
						maxRows:20
					   startRow:0
					   language:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark switch methods

- (void)switchChange:(UISwitch *)theSwitch {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if (theSwitch == self.setLocationSwitch) {
        [userDetails setBool:theSwitch.on forKey:@"useCurrentLocation"];

        self.cityTextField.enabled = !self.setLocationSwitch.on;
        [userDetails synchronize];
        if (self.setLocationSwitch.on) {
            if ([self.delegate respondsToSelector:@selector(userChangedSettingsToUseCurrentLocation)]) {
                [self.delegate userChangedSettingsToUseCurrentLocation];
            }
        }
    } else if (theSwitch == self.goingOutSwitch) {
        [userDetails setBool:theSwitch.on forKey:@"status"];
        [userDetails synchronize];
        
        PFUser *user = [PFUser currentUser];
        [user setObject:[NSNumber numberWithBool:theSwitch.on] forKey:kUserStatusKey];
        [user setObject:[NSDate date] forKey:kUserTimeLastUpdatedKey];
        [user saveInBackground];
        
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if (!theSwitch.on && sharedDataManager.currentCommitmentPlace != nil) {
            if ([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
                [self.delegate removePreviousCommitment];
            }
            if ([self.delegate respondsToSelector:@selector(removeCommitmentFromDatabase)]) {
                [self.delegate removeCommitmentFromDatabase];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
                [self.delegate pollDatabase];
            }
        }
        
        NSLog(@"PARSE SAVE: updating status");
    } else {
        [userDetails setBool:!theSwitch.on forKey:@"cityFriendsOnly"];
        [userDetails synchronize];
        
        if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
            [self.delegate pollDatabase];
        }
    }
}

#pragma mark button action methods

- (IBAction)showManage:(id)sender {
    self.manageVC = [[ManageFriendsViewController alloc] init];
    self.manageVC.delegate = self;
    
    [self addChildViewController:self.manageVC];
    [self.manageVC didMoveToParentViewController:self];
    [self.manageVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.manageVC.view];
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.manageVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (IBAction)handleCloseSettings:(id)sender {
    if ([self.delegate respondsToSelector:@selector(closeSettings)]) {
        [self.delegate closeSettings];
    }
    
    if (self.cityTextField.tag == 1) {
        
    } else {
        [self closeSearchResultsTableView];
    }
    
    [self saveStatusMessage];
}

-(IBAction)logoutButtonWasPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(closeSettings)]) {
        [self.delegate closeSettings];
    }
    
    if ([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
        [self.delegate removePreviousCommitment];
    }
    
    if ([self.delegate respondsToSelector:@selector(removeCommitmentFromDatabase)]) {
        [self.delegate removeCommitmentFromDatabase];
    }
    
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate logoutPressed];
}

-(IBAction)cancelSearchButtonPressed:(id)sender {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSString *location = [NSString stringWithFormat:@"%@, %@",[userDetails objectForKey:@"city"], [userDetails objectForKey:@"state"]];
    if ([userDetails objectForKey:@"city"] != NULL && [userDetails objectForKey:@"state"] != NULL) {
        self.cityTextField.text = [location uppercaseString];
    } else {
        self.cityTextField.text = @"Enter your city";
    }
    [self closeSearchResultsTableView];
}

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

#pragma mark ManageFriendsViewControllerDelegate

-(void)blockFriend:(Friend*)friend block:(BOOL)block {
    if ([self.delegate respondsToSelector:@selector(blockFriend:block:)]) {
        [self.delegate blockFriend:friend block:block];
    }
}

-(void)closeManageFriendsView {
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.manageVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.manageVC.view removeFromSuperview];
                         [self.manageVC removeFromParentViewController];
                     }];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    return [self.searchResults count] + 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row == [self.searchResults count]) {
        cell.isAccessibilityElement = YES;
        cell.textLabel.text = @"";
        cell.detailTextLabel.text =@"Powered by GeoNames";
        return cell;
    }

	NSDictionary	*geoname = [self.searchResults objectAtIndex:indexPath.row];
	if(geoname) {
		NSString	*name = [geoname objectForKey:kILGeoNamesNameKey];
		cell.textLabel.text = name;
		NSString	*subString = [geoname objectForKey:kILGeoNamesCountryNameKey];
		if(subString && ![subString isEqualToString:@""]) {
			NSString	*admin1 = [geoname objectForKey:kILGeoNamesAdminName1Key];
			if(admin1 && ![admin1 isEqualToString:@""]) {
				subString = [admin1 stringByAppendingFormat:@", %@", subString];
				NSString *admin2 = [geoname objectForKey:kILGeoNamesAdminName2Key];
				if(admin2 && ![admin2 isEqualToString:@""]) {
					subString = [admin2 stringByAppendingFormat:@", %@", subString];
				}
			}
		}
		else {
			subString = [geoname objectForKey:kILGeoNamesFeatureClassNameKey];
		}
		cell.detailTextLabel.text = subString;
		cell.isAccessibilityElement = YES;
		cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", name, subString];
	}
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.searchResults count]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self.geocoder cancel];
	
	[self geoNamesSearchControllerdidFinishWithResult:[self.searchResults objectAtIndex:indexPath.row]];
}

- (void)geoNamesSearchControllerdidFinishWithResult:(NSDictionary*)result
{
	if(result) {
		double latitude = [[result objectForKey:kILGeoNamesLatitudeKey] doubleValue];
		double longitude = [[result objectForKey:kILGeoNamesLongitudeKey] doubleValue];
        self.cityTextField.text =[[result objectForKey:kILGeoNamesAlternateNameKey] uppercaseString];
        [self closeSearchResultsTableView];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        if ([self.delegate respondsToSelector:@selector(userChangedLocationInSettings:)]) {
            [self.delegate userChangedLocationInSettings:location];
            self.view.userInteractionEnabled = NO;
        }
	}
}


#pragma mark -
#pragma mark ILGeoNamesLookupDelegate

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler networkIsActive:(BOOL)isActive
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = isActive;
}

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFindGeoNames:(NSArray *)geoNames totalFound:(NSUInteger)total
{
	if ([geoNames count]) {
		[self.searchResults setArray:geoNames];
	}
	else {

		[self.searchResults removeAllObjects];
	}
    
	[self.searchResultsTableView reloadData];
    // when the table view is repopulated, its significant enough that a screen change notification should be posted
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    [self.activityIndicator stopAnimating];
}

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFailWithError:(NSError *)error
{
	// TODO error handling
    NSLog(@"ILGeoNamesLookup has failed: %@", [error localizedDescription]);
	self.searchDisplayController.searchBar.prompt = NSLocalizedStringFromTable(@"ILGEONAMES_SEARCH_ERR", @"ILGeoNames", @"");
}

@end
