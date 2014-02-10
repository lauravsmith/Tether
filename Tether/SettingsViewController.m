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
#import "SettingsViewController.h"
#import "TethrTextField.h"

#define PADDING 15.0
#define PROFILE_IMAGE_VIEW_SIZE 80.0
#define STATUS_BAR_HEIGHT 20.0
#define STATUS_MESSAGE_LENGTH 35.0
#define TABLE_VIEW_HEIGHT 277.0

#define degreesToRadian(x) (M_PI * (x) / 180.0)

static NSString *kGeoNamesAccountName = @"lsmit87";

@interface SettingsViewController () <ILGeoNamesLookupDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (retain, nonatomic) TethrTextField *statusMessageTextField;
@property (retain, nonatomic) UIButton * doneButton;
@property (retain, nonatomic) UIButton * largeDoneButton;
@property (retain, nonatomic) UIView * topBarView;
@property (retain, nonatomic) UITextField *cityTextField;
@property (retain, nonatomic) UIButton * logoutButton;
@property (retain, nonatomic) UISwitch * setLocationSwitch;
@property (retain, nonatomic) UILabel * defaultCityLabel;
@property (retain, nonatomic) UILabel * locationSwitchLabel;
@property (retain, nonatomic) UILabel * goingOutLabel;
@property (retain, nonatomic) UILabel * yesLabel;
@property (retain, nonatomic) UILabel * noLabel;
@property (retain, nonatomic) UITableView * searchResultsTableView;
@property (retain, nonatomic) UITableViewController * searchResultsTableViewController;
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (retain, nonatomic) UIButton * cancelSearchButton;
@property (retain, nonatomic) UIActivityIndicatorView * activityIndicator;
@property (retain, nonatomic) UIButton * inviteFriendsButton;

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
    
    UIImage *backgroundImage = [UIImage imageNamed:@"BlackTexture"];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:backgroundImageView];
    
    UITapGestureRecognizer *closeKeyBoardTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    backgroundImageView.userInteractionEnabled = YES;
    [backgroundImageView addGestureRecognizer:closeKeyBoardTap];
    
    UISwipeGestureRecognizer * swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
    [swipeDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.view addGestureRecognizer:swipeDown];
    
    [self addProfileImageView];
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14];
    self.statusMessageTextField = [[TethrTextField alloc] initWithFrame:CGRectMake(PADDING, self.userProfilePictureView.frame.origin.y + self.userProfilePictureView.frame.size.height + PADDING, self.view.frame.size.width - PADDING * 2, 25.0)];
    self.statusMessageTextField.delegate = self;
    self.statusMessageTextField.layer.cornerRadius = 2.0;
    self.statusMessageTextField.placeholder = @"Enter a status message";
    [self.statusMessageTextField setBackgroundColor:[UIColor whiteColor]];
    [self.statusMessageTextField setTextColor:UIColorFromRGB(0xc8c8c8)];
    [self.statusMessageTextField setFont:montserrat];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.statusMessage) {
        self.statusMessageTextField.text = sharedDataManager.statusMessage;
    }
    [self.view addSubview:self.statusMessageTextField];
    
    UIImageView *blackLineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.statusMessageTextField.frame.origin.y + self.statusMessageTextField.frame.size.height + PADDING, self.view.frame.size.width, 4.0)];
    [blackLineImageView setImage:[UIImage imageNamed:@"DividerSettings"]];
    [self.view addSubview:blackLineImageView];
    
    self.defaultCityLabel = [[UILabel alloc] init];
    self.defaultCityLabel.text = @"Default City";
    self.defaultCityLabel.font = montserrat;
    self.defaultCityLabel.textColor = [UIColor whiteColor];
    CGSize textLabelSize = [self.defaultCityLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.defaultCityLabel.frame = CGRectMake(PADDING, blackLineImageView.frame.origin.y + PADDING, textLabelSize.width, textLabelSize.height);
    [self.view addSubview:self.defaultCityLabel];
    
    self.locationSwitchLabel = [[UILabel alloc] init];
    self.locationSwitchLabel.text = @"Use current location?";
    UIFont *subheadingFont = [UIFont fontWithName:@"Montserrat" size:10];
    self.locationSwitchLabel.font = subheadingFont;
    self.locationSwitchLabel.textColor = [UIColor whiteColor];
    CGSize locationSwitchLabelSize = [self.locationSwitchLabel.text sizeWithAttributes:@{NSFontAttributeName: subheadingFont}];
    self.locationSwitchLabel.frame = 
    CGRectMake(PADDING, self.defaultCityLabel.frame.origin.y + self.defaultCityLabel.frame.size.height, locationSwitchLabelSize.width, locationSwitchLabelSize.height);
    [self.view addSubview:self.locationSwitchLabel];
    
    self.noLabel = [[UILabel alloc] init];
    self.noLabel.text = @"No";
    UIFont *switchLabelFont = [UIFont fontWithName:@"Montserrat" size:16];
    self.noLabel.font = switchLabelFont;
    self.noLabel.textColor = [UIColor whiteColor];
    CGSize noLabelSize = [self.noLabel.text sizeWithAttributes:@{NSFontAttributeName: switchLabelFont}];
    self.noLabel.frame = CGRectMake(PADDING, self.locationSwitchLabel.frame.origin.y + self.locationSwitchLabel.frame.size.height + PADDING, noLabelSize.width, noLabelSize.height);
    [self.view addSubview:self.noLabel];
    
    self.setLocationSwitch = [[UISwitch alloc] init];
    self.setLocationSwitch.transform = CGAffineTransformMakeScale(0.60, 0.60);
    self.setLocationSwitch.frame = CGRectMake(self.noLabel.frame.origin.x + self.noLabel.frame.size.width + 2.0, self.noLabel.frame.origin.y, 0, 0);
    [self.setLocationSwitch setOnTintColor:UIColorFromRGB(0xD6D6D6)];
    [self.setLocationSwitch addTarget:self action:@selector(locationSwitchChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.setLocationSwitch];
    [self.setLocationSwitch setOn:[userDetails boolForKey:@"useCurrentLocation"]];
    NSLog(@"Switch is: %d", [self.setLocationSwitch isOn]);
    
    self.yesLabel = [[UILabel alloc] init];
    self.yesLabel.text = @"Yes";
    self.yesLabel.font = switchLabelFont;
    self.yesLabel.textColor = [UIColor whiteColor];
    CGSize yesLabelSize = [self.yesLabel.text sizeWithAttributes:@{NSFontAttributeName: switchLabelFont}];
    self.yesLabel.frame = CGRectMake(self.setLocationSwitch.frame.origin.x + 35.0, self.locationSwitchLabel.frame.origin.y + self.locationSwitchLabel.frame.size.height + PADDING, yesLabelSize.width, yesLabelSize.height);
    [self.view addSubview:self.yesLabel];
    
    //city search
    self.cityTextField = [[UITextField  alloc] initWithFrame:CGRectMake(PADDING, self.setLocationSwitch.frame.origin.y + self.setLocationSwitch.frame.size.height, self.view.frame.size.width - PADDING*2, 25.0)];
    self.cityTextField.delegate = self;
    NSString *location = [NSString stringWithFormat:@"%@, %@",[userDetails objectForKey:@"city"], [userDetails objectForKey:@"state"]];
    self.cityTextField.text = [location uppercaseString];
    self.cityTextField.placeholder = @"Search by city name";
    UIFont *textViewFont = [UIFont fontWithName:@"Montserrat" size:16];
    self.cityTextField.font = textViewFont;
    self.cityTextField.textColor = UIColorFromRGB(0xc8c8c8);
    self.cityTextField.layer.cornerRadius = 2.0;
    [self.cityTextField setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.cityTextField];
    self.cityTextField.enabled = !self.setLocationSwitch.on;
    self.cityTextField .clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.cityTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.cityTextField setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 20)]];
    [self.cityTextField setLeftViewMode:UITextFieldViewModeAlways];
    self.cityTextField.tag = 1;
    
    //pull city search results from geonames.org
    self.geocoder = [[ILGeoNamesLookup alloc] initWithUserID:kGeoNamesAccountName];
    self.geocoder.delegate = self;
    
    self.cancelSearchButton = [[UIButton alloc] init];
    [self.cancelSearchButton addTarget:self action:@selector(cancelSearchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelSearchButton setBackgroundColor:[UIColor clearColor]];
    [self.cancelSearchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelSearchButton setTitle:@"Cancel" forState:UIControlStateNormal];
    UIFont *cancelButtonFont = [UIFont fontWithName:@"Montserrat" size:12];
    CGSize size = [self.cancelSearchButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: cancelButtonFont}];
    self.cancelSearchButton.frame = CGRectMake(self.view.frame.size.width - size.width - PADDING, STATUS_BAR_HEIGHT + PADDING + 5.0, size.width, size.height);
    self.cancelSearchButton.titleLabel.font = cancelButtonFont;
    self.cancelSearchButton.hidden = YES;
    [self.view addSubview:self.cancelSearchButton];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 50.0) / 2.0, self.defaultCityLabel.frame.origin.y + self.defaultCityLabel.frame.size.height , 50.0, 50.0)];
    [self.view addSubview:self.activityIndicator];
    
    UIImageView *blackLineImageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, self.cityTextField.frame.origin.y + self.cityTextField.frame.size.height + PADDING, self.view.frame.size.width, 4.0)];
    [blackLineImageView2 setImage:[UIImage imageNamed:@"DividerSettings"]];
    [self.view addSubview:blackLineImageView2];
    
    self.goingOutLabel = [[UILabel alloc] init];
    self.goingOutLabel.text = @"Going out?";
    self.goingOutLabel.font = montserrat;
    self.goingOutLabel.textColor = [UIColor whiteColor];
    size = [self.goingOutLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.goingOutLabel.frame =
    CGRectMake(PADDING, blackLineImageView2.frame.origin.y + blackLineImageView2.frame.size.height + PADDING, size.width, size.height);
    [self.view addSubview:self.goingOutLabel];
    
    UILabel *noLabel2 = [[UILabel alloc] init];
    noLabel2.text = @"No";
    noLabel2.font = switchLabelFont;
    noLabel2.textColor = [UIColor whiteColor];
    noLabel2.frame = CGRectMake(PADDING, self.goingOutLabel.frame.origin.y + self.goingOutLabel.frame.size.height + PADDING, noLabelSize.width, noLabelSize.height);
    [self.view addSubview:noLabel2];
    
    self.goingOutSwitch = [[UISwitch alloc] init];
    self.goingOutSwitch.transform = CGAffineTransformMakeScale(0.60, 0.60);
    self.goingOutSwitch.frame = CGRectMake(noLabel2.frame.origin.x + noLabel2.frame.size.width + 2.0, noLabel2.frame.origin.y, 0, 0);
    [self.goingOutSwitch setOnTintColor:UIColorFromRGB(0xD6D6D6)];
    [self.goingOutSwitch addTarget:self action:@selector(locationSwitchChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.goingOutSwitch];
    self.goingOutSwitch.on = [userDetails boolForKey:@"status"];
    
    UILabel *yesLabel2 = [[UILabel alloc] init];
    yesLabel2.text = @"Yes";
    yesLabel2.font = switchLabelFont;
    yesLabel2.textColor = [UIColor whiteColor];
    yesLabel2.frame = CGRectMake(self.goingOutSwitch.frame.origin.x + 35.0, self.goingOutLabel.frame.origin.y + self.goingOutLabel.frame.size.height + PADDING, yesLabelSize.width, yesLabelSize.height);
    [self.view addSubview:yesLabel2];
    
    UIImageView *blackLineImageView3 = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, noLabel2.frame.origin.y + noLabel2.frame.size.height + PADDING, self.view.frame.size.width, 4.0)];
    [blackLineImageView3 setImage:[UIImage imageNamed:@"DividerSettings"]];
    [self.view addSubview:blackLineImageView3];
    
    self.logoutButton = [[UIButton alloc] init];
    [self.logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateHighlighted];
    UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:28];
    self.logoutButton.titleLabel.font = montserratBold;
    size = [self.logoutButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratBold}];
    self.logoutButton.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, blackLineImageView3.frame.origin.y + blackLineImageView3.frame.size.height + size.height - PADDING, size.width, size.height);
    [self.logoutButton addTarget:self action:@selector(logoutButtonWasPressed:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.logoutButton];
    
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:16];
    self.doneButton = [[UIButton alloc] init];
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateHighlighted];
    [self.doneButton addTarget:self action:@selector(handleCloseSettings:) forControlEvents:UIControlEventTouchDown];
    self.doneButton.titleLabel.font = montserratLarge;
    CGSize buttonSize = [self.doneButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLarge}];
    self.doneButton.frame = CGRectMake(PADDING, self.view.frame.size.height - buttonSize.height - PADDING, buttonSize.width, buttonSize.height);
    [self.view addSubview:self.doneButton];
    
    self.largeDoneButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, self.doneButton.frame.origin.y - PADDING, self.view.frame.size.width / 2.0, self.view.frame.size.height - self.doneButton.frame.origin.y)];
    [self.largeDoneButton addTarget:self action:@selector(handleCloseSettings:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.largeDoneButton];
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, STATUS_BAR_HEIGHT + PADDING*2 + self.statusMessageTextField.frame.size.height, self.view.frame.size.width, TABLE_VIEW_HEIGHT)];
    [self.searchResultsTableView setBackgroundColor:[UIColor whiteColor]];
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    self.searchResultsTableView.hidden = YES;
    [self.view bringSubviewToFront:self.searchResultsTableView];
    
    [self.view addSubview:self.searchResultsTableView];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    [self.searchResultsTableView reloadData];
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
    self.userProfilePictureView.frame = CGRectMake((self.view.frame.size.width - PROFILE_IMAGE_VIEW_SIZE) / 2.0 , STATUS_BAR_HEIGHT + PADDING, PROFILE_IMAGE_VIEW_SIZE, PROFILE_IMAGE_VIEW_SIZE);
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
    
    self.locationSwitchLabel.hidden = NO;
    self.setLocationSwitch.hidden = NO;
    self.yesLabel.hidden = NO;
    self.noLabel.hidden = NO;
    self.cancelSearchButton.hidden = YES;
    self.userProfilePictureView.hidden = NO;
    self.defaultCityLabel.hidden = NO;
    self.statusMessageTextField.hidden = NO;
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGRect frame = self.cityTextField.frame;
                         frame.origin.y = self.setLocationSwitch.frame.origin.y + self.setLocationSwitch.frame.size.height;
                         frame.size.width = self.view.frame.size.width - PADDING*2;
                         self.cityTextField.frame = frame;
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
    self.view.userInteractionEnabled = YES;
}

-(void)dismissKeyboard {
    if ([self.statusMessageTextField isFirstResponder]) {
        [self.statusMessageTextField resignFirstResponder];
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
        NSLog(@"PARSE SAVE: saving status message");
        [self notifyBestFriendsOfStatusChange];
    }
}

-(void)notifyBestFriendsOfStatusChange {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    
    if (![self.statusMessageTextField.text isEqualToString:@""]) {
        for (NSString *friendID in sharedDataManager.bestFriendSet) {
            NSString *messageHeader = [NSString stringWithFormat:@"%@ changed their status: \"%@\"",sharedDataManager.name, self.statusMessageTextField.text];
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
                             frame.origin.y = STATUS_BAR_HEIGHT + PADDING;
                             frame.size.width = frame.size.width - self.cancelSearchButton.frame.size.width - PADDING;
                             self.cityTextField.frame = frame;
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 self.searchResultsTableView.hidden = NO;
                                 self.cancelSearchButton.hidden = NO;
                                 self.cityTextField.tag = 2;
                             }
                         }];
        
        self.cityTextField.text = @"";
        self.locationSwitchLabel.hidden = YES;
        self.setLocationSwitch.hidden = YES;
        self.yesLabel.hidden = YES;
        self.noLabel.hidden = YES;
        self.userProfilePictureView.hidden = YES;
        self.defaultCityLabel.hidden = YES;
        self.statusMessageTextField.hidden = YES;
    } else if (textField == self.statusMessageTextField) {
        
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

#pragma switch methods

- (void)locationSwitchChange:(UISwitch *)theSwitch {
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
    } else {
        [userDetails setBool:theSwitch.on forKey:@"status"];
        [userDetails synchronize];
        
        PFUser *user = [PFUser currentUser];
        [user setObject:[NSNumber numberWithBool:theSwitch.on] forKey:kUserStatusKey];
        [user saveInBackground];
        
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if (!theSwitch.on && sharedDataManager.currentCommitmentPlace != nil) {
            if ([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
                [self.delegate removePreviousCommitment];
            }
            if ([self.delegate respondsToSelector:@selector(removeCommitmentFromDatabase)]) {
                [self.delegate removeCommitmentFromDatabase];
            }
        }
        
        NSLog(@"PARSE SAVE: updating status");
    }
}

#pragma mark button action methods
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
    self.cityTextField.text = [location uppercaseString];
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

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    return [self.searchResults count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
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
