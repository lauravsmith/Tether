//
//  CenterViewController.m
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "AppDelegate.h"
#import "CenterViewController.h"
#import "Datastore.h"
#import "Place.h"
#import "TetherAnnotation.h"
#import "TetherAnnotationView.h"

#import <FacebookSDK/FacebookSDK.h>
#import <MapKit/MapKit.h> 

#define BOTTOM_BAR_HEIGHT 45.0
#define CORNER_RADIUS 20.0
#define DISTANCE_FACE_TO_PIN 20.0
#define FACE_SIZE 40.0
#define MAX_FRIENDS_ON_PIN 15.0
#define NOTIFICATIONS_SIZE 32.0
#define PADDING 20.0
#define SPINNER_SIZE 30.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

@interface CenterViewController () <MKMapViewDelegate, CLLocationManagerDelegate>
@property (retain, nonatomic) NSString * cityLocation;
@property (retain, nonatomic) UIView * topBar;
@property (assign, nonatomic) bool mapHasAdjusted;
@property (strong, nonatomic) CLLocationManager * locationManager;
@property (strong, nonatomic) NSTimer * finishLoadingTimer;
@property (retain, nonatomic) UITapGestureRecognizer * cityTapGesture;
@property (strong, nonatomic) UIButton *commitmentButton;

@end

@implementation CenterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.mapHasAdjusted = NO;
        self.annotationsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.listViewOpen = NO;
    
    // mapview setup
    self.mv = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.mv.delegate = self;
    [self.view addSubview:self.mv];
    
    // top bar setup
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, self.view.frame.size.width,TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:self.topBar];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate  = self;
    self.userCoordinates = [[CLLocation alloc] init];
    
    [self locationSetup];
    
    self.leftPanelButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.topBar.frame.size.width / 4, self.topBar.frame.size.height)];
    [self.leftPanelButtonLarge addTarget:self action:@selector(btnMovePanelRight:) forControlEvents:UIControlEventTouchUpInside];
    self.leftPanelButtonLarge.tag = 1;
    [self.topBar addSubview:self.leftPanelButtonLarge];
    
    self.tethrLabel = [[UILabel alloc] init];
    UIFont *helvetica = [UIFont fontWithName:@"HelveticaNeueLTStd-UltLt" size:25];
    self.tethrLabel.font = helvetica;
    self.tethrLabel.text = @"tethr";
    [self.tethrLabel setTextColor:[UIColor whiteColor]];
    CGSize size = [self.tethrLabel.text sizeWithAttributes:@{NSFontAttributeName:helvetica}];
    self.tethrLabel.frame = CGRectMake((self.topBar.frame.size.width - size.width) / 2, (self.topBar.frame.size.height - size.height + STATUS_BAR_HEIGHT) / 2 + 5.0, size.width, size.height);
    self.tethrLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *refreshTapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(refreshTapped:)];
    [self.tethrLabel addGestureRecognizer:refreshTapGesture];
    [self.tethrLabel setHidden:YES];
    [self.topBar addSubview:self.tethrLabel];
    
    // number of friends going out label setup
    self.numberButton = [[UIButton alloc] init];
    [self.numberButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.numberButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    UIFont *helveticaNeueLarge = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
    size = [self.numberButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeueLarge}];
    self.numberButton.frame = CGRectMake(PADDING, self.tethrLabel.frame.origin.y - STATUS_BAR_HEIGHT / 2.0 - 1.0, size.width, size.height);
    self.numberButton.titleLabel.font = helveticaNeueLarge;
    [self.numberButton addTarget:self action:@selector(btnMovePanelRight:) forControlEvents:UIControlEventTouchUpInside];
    self.numberButton.tag = 1;
    [self.topBar addSubview:self.numberButton];
    
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.triangleButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, self.numberButton.frame.origin.y + STATUS_BAR_HEIGHT / 2.0 + 2.0, 10.0, 10.0)];
    [self.triangleButton setImage:triangleImage forState:UIControlStateNormal];
    [self.view addSubview:self.triangleButton];
    self.triangleButton.tag = 1;
    [self.triangleButton addTarget:self action:@selector(btnMovePanelRight:) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.triangleButton];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.topBar.frame.size.width - SPINNER_SIZE) / 2.0, STATUS_BAR_HEIGHT + (self.topBar.frame.size.height - STATUS_BAR_HEIGHT - SPINNER_SIZE) / 2.0, SPINNER_SIZE, SPINNER_SIZE)];
    self.spinner.hidesWhenStopped = YES;
    [self.spinner startAnimating];
    [self.topBar addSubview:self.spinner];
    
    // list view arrow button setup
    self.listViewButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 35.0, self.tethrLabel.frame.origin.y - 2.0, 25.0, 25.0)];
    [self.listViewButton setImage:[UIImage imageNamed:@"LineNavigator"] forState:UIControlStateNormal];
    [self.listViewButton addTarget:self action:@selector(showListView) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.listViewButton];
    
    self.listViewButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(self.topBar.frame.size.width - self.topBar.frame.size.width / 4.0, 0.0, self.topBar.frame.size.width / 4.0, self.topBar.frame.size.height)];
    [self.listViewButtonLarge addTarget:self action:@selector(showListView) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.listViewButtonLarge];
    
    // bottom nav bar setup
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT)];
    if ([UIApplication sharedApplication].statusBarFrame.size.height == 40.0) {
        self.bottomBar.frame = CGRectMake(0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT - STATUS_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT);
    }
    [self.bottomBar setBackgroundColor:[UIColor whiteColor]];
    [self.bottomBar setAlpha:0.85];
    
    UISwipeGestureRecognizer * swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp:)];
    [swipeUp setDirection:(UISwipeGestureRecognizerDirectionUp)];
    self.bottomBar.userInteractionEnabled = YES;
    [self.view addGestureRecognizer:swipeUp];
    
    // large background button to increase touch surface area
    self.settingsButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomBar.frame.size.width / 4.0, self.bottomBar.frame.size.height)];
    [self.settingsButtonLarge addTarget:self action:@selector(settingsPressed:) forControlEvents:UIControlEventTouchDown];
    
    // notifications button to open right panel setup
    self.notificationsButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(self.bottomBar.frame.size.width - self.bottomBar.frame.size.width / 4.0, 0.0, self.bottomBar.frame.size.width / 4.0, self.bottomBar.frame.size.height)];
    [self.notificationsButtonLarge addTarget:self action:@selector(btnMovePanelLeft:) forControlEvents:UIControlEventTouchUpInside];
    self.notificationsButtonLarge.tag = 1;
    [self.bottomBar addSubview:self.notificationsButtonLarge];
    
    self.notificationsButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - NOTIFICATIONS_SIZE, 5.0, NOTIFICATIONS_SIZE, NOTIFICATIONS_SIZE)];
    self.notificationsButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    [self.notificationsButton setBackgroundImage:[UIImage imageNamed:@"FriendsThing"] forState:UIControlStateNormal];
    [self.notificationsButton setBackgroundColor:[UIColor clearColor]];
    [self.notificationsButton addTarget:self action:@selector(btnMovePanelLeft:) forControlEvents:UIControlEventTouchUpInside];
    self.notificationsButton.tag = 1;
    [self.bottomBar addSubview:self.notificationsButton];
    [self refreshNotificationsNumber];
    
    self.notificationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.notificationsButton.frame.origin.x + 3.0, self.notificationsButton.frame.origin.y + 2.0, 12.0, 12.0)];
    self.notificationsLabel.layer.cornerRadius = 6.0;
    self.notificationsLabel.layer.borderWidth = 1.5;
    self.notificationsLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.notificationsLabel setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.notificationsLabel setTextColor:[UIColor whiteColor]];
    [self.notificationsLabel setTextAlignment:NSTextAlignmentCenter];
    UIFont *montserratVerySmall = [UIFont fontWithName:@"Montserrat" size:8];
    self.notificationsLabel.font = montserratVerySmall;
    [self.notificationsLabel sizeThatFits:CGSizeMake(10.0, 10.0)];
    self.notificationsLabel.adjustsFontSizeToFitWidth = YES;
    [self.bottomBar addSubview:self.notificationsLabel];
    
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:14];
    UIFont *montserratExtraSmall = [UIFont fontWithName:@"Montserrat" size:10];
    self.placeLabel = [[UILabel alloc] init];
    [self.placeLabel setFont:montserratExtraSmall];
    [self.placeLabel setTextColor:UIColorFromRGB(0x8e0528)];
    self.placeLabel.adjustsFontSizeToFitWidth = YES;
    [self.bottomBar addSubview:self.placeLabel];
    
    self.placeNumberLabel = [[UILabel alloc] init];
    [self.placeNumberLabel setFont:montserratSmall];
    [self.placeNumberLabel setTextColor:UIColorFromRGB(0x8e0528)];
    [self.bottomBar addSubview:self.placeNumberLabel];
    [self layoutCurrentCommitment];
    
    [self.view addSubview:self.bottomBar];
    
    self.commitmentButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 4.0, 0.0, self.view.frame.size.width / 2.0, self.bottomBar.frame.size.height)];
    self.commitmentButton.tag = 0;
    [self.commitmentButton addTarget:self action:@selector(commitmentClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self restartTimer];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)setNeedsStatusBarAppearanceUpdate {
    self.topBar.frame = CGRectMake(0, 0.0, self.view.frame.size.width,TOP_BAR_HEIGHT);
    self.bottomBar.frame = CGRectMake(0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT);
    self.mv.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

-(void)layoutNumberButton {
    UIFont *helveticaNeue = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
    CGSize size = [self.numberButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeue}];
    self.numberButton.frame = CGRectMake(PADDING, self.tethrLabel.frame.origin.y - STATUS_BAR_HEIGHT / 2.0 - 1.0, size.width, size.height);
    self.numberButton.tag = 1;
    [self.topBar addSubview:self.numberButton];
    [self refreshComplete];
}

-(void)layoutCurrentCommitment {
    UIFont *helvetica = [UIFont fontWithName:@"HelveticaNeueLTStd-UltLt" size:25];
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:14];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSDate *timeLastUpdated = [userDetails objectForKey:@"timeLastUpdated"];
    NSDate *startTime = [self getStartTime];
    
    if (sharedDataManager.currentCommitmentPlace && [startTime compare:timeLastUpdated] == NSOrderedAscending) {
         self.mv.showsUserLocation = NO;
        UIFont *montserratExtraSmall = [UIFont fontWithName:@"Montserrat" size:10];
        
        self.placeLabel.text = sharedDataManager.currentCommitmentPlace.name;
        self.placeNumberLabel.text = [NSString stringWithFormat:@"%d", [sharedDataManager.currentCommitmentPlace.friendsCommitted count]];
        self.tethrLabel.text = @"tethrd";
        
        self.placeLabel.font = montserratExtraSmall;
        
        CGSize size1 = [self.placeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratExtraSmall}];
        CGSize size2 = [self.placeNumberLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratSmall}];
        
        self.placeLabel.frame = CGRectMake(MAX(self.userProfilePictureView.frame.origin.x + self.userProfilePictureView.frame.size.width, (self.view.frame.size.width - size1.width) / 2), (self.bottomBar.frame.size.height - size1.height + size2.height) / 2.0, MIN(267.0, size1.width), size1.height);

        for (UIGestureRecognizer *gestureRecognizer in self.placeLabel.gestureRecognizers) {
            [self.placeLabel removeGestureRecognizer:gestureRecognizer];
        }

        [self.bottomBar addSubview:self.commitmentButton];
        self.commitmentButton.tag = 1;
        
        self.placeNumberLabel.frame = CGRectMake((self.view.frame.size.width - size2.width) / 2, (self.bottomBar.frame.size.height - size1.height - size2.height) / 2.0, size2.width, size2.height);

    } else {
        
        if (!self.mv.showsUserLocation && self.userCoordinates.coordinate.longitude != 0.0) {
            [self.mv setShowsUserLocation:YES];
        }

        UIFont *montserratExtraSmall = [UIFont fontWithName:@"Montserrat" size:16];
        
        NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
        if ([userDetails objectForKey:@"city"]) {
            self.placeLabel.text = [NSString stringWithFormat:@"%@",[userDetails objectForKey:@"city"]];
            self.placeLabel.font = montserratExtraSmall;
        }
        
        self.placeNumberLabel.text = @"";
        self.tethrLabel.text = @"tethr";
        
        CGSize size = [self.placeNumberLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratSmall}];
        self.placeNumberLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2, 0, size.width, size.height);

        size = [self.placeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratExtraSmall}];
        self.placeLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2, (self.bottomBar.frame.size.height - size.height) / 2.0, MIN(300.0, size.width), size.height);
        
        self.cityTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cityNameTap:)];
        [self.placeLabel addGestureRecognizer:self.cityTapGesture];
        self.placeLabel.userInteractionEnabled = YES;
        
        if (self.commitmentButton.tag == 1) {
            [self.commitmentButton removeFromSuperview];
        }
        self.commitmentButton.tag = 0;
    }
    
    CGSize size = [self.tethrLabel.text sizeWithAttributes:@{NSFontAttributeName:helvetica}];
    self.tethrLabel.frame = CGRectMake((self.topBar.frame.size.width - size.width) / 2, (self.topBar.frame.size.height - size.height  + STATUS_BAR_HEIGHT) / 2+ 5.0, size.width, size.height);
}

-(NSDate*)getStartTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH"];
    NSDate *now = [NSDate date];
    NSString *hour = [formatter stringFromDate:[NSDate date]];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:now];
    
    // if after 6am, start from today's date
    if ([hour intValue] > 6) {
        [components setHour:6.0];
        return [calendar dateFromComponents:components];
    } else { // if before 6am, start from yesterday's date
        NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
        [deltaComps setDay:-1.0];
        [components setHour:6.0];
        return [calendar dateByAddingComponents:deltaComps toDate:[calendar dateFromComponents:components] options:0];
    }
}

#pragma UIGestureRecognizers

-(void)swipeUp:(UIGestureRecognizer*)recognizer  {
    if ([self.delegate respondsToSelector:@selector(showSettingsView)]) {
        [self.delegate showSettingsView];
    }
}

-(void)cityNameTap:(UIGestureRecognizer*)recognizer {
    if ([self.delegate respondsToSelector:@selector(showSettingsView)]) {
        [self.delegate showSettingsView];
    }
}

-(IBAction)commitmentClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    TetherAnnotationView * annotationView = [self.placeToAnnotationViewDictionary objectForKey:sharedDataManager.currentCommitmentPlace.placeId];
    
    if (annotationView.tag == 1) {
        [self.mv selectAnnotation:((MKAnnotationView*)annotationView).annotation animated:YES];
            annotationView.placeTouchView.userInteractionEnabled = YES;
    } else {
        [self.mv deselectAnnotation:((MKAnnotationView*)annotationView).annotation animated:YES];
        annotationView.placeTouchView.userInteractionEnabled = NO;
    }
}

- (void)refreshTapped:(UIGestureRecognizer*)recognizer {
    if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
        [self.delegate pollDatabase];
        [self.tethrLabel setHidden:YES];
        [self.spinner startAnimating];
        [self performSelector:@selector(refreshComplete) withObject:self.spinner afterDelay:1.0];
        [self updateLocation];
    }
}

-(void)refreshComplete {
    [self.tethrLabel setHidden:NO];
    [self.spinner stopAnimating];
}

-(void)refreshNotificationsNumber {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.notificationsLabel.text = [NSString stringWithFormat:@"%d", sharedDataManager.notifications];
    if (sharedDataManager.notifications == 0 || !sharedDataManager.notifications) {
        [self.notificationsLabel setHidden:YES];
    } else {
        [self.notificationsLabel setHidden:NO];
    }
}

-(void)locationSetup {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if ([userDetails boolForKey:@"useCurrentLocation"] || ![userDetails objectForKey:@"city"] || ![userDetails objectForKey:@"state"]) {
        [self.locationManager startUpdatingLocation];
        if (![userDetails objectForKey:@"city"] || ![userDetails objectForKey:@"state"]) {
            [userDetails setBool:YES forKey:@"useCurrentLocation"];
            [userDetails synchronize];
        }
    } else {
        NSString *city = [userDetails objectForKey:@"city"];
        NSString *state = [userDetails objectForKey:@"state"];
        NSString *locationString = [NSString stringWithFormat:@"%@, %@", city, state];
        NSLog(@"%@", locationString);
        [self setUserLocationToCity:locationString];
    }
}

-(void)restartTimer {
    [self.finishLoadingTimer invalidate];
    self.finishLoadingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                               target:self
                                                             selector:@selector(mapLoadingIsFinished)
                                                             userInfo:nil
                                                              repeats:NO];
}

- (void)mapLoadingIsFinished
{
    NSLog(@"timer stopped");
    self.mapHasAdjusted = YES;
}


-(void)updateLocation {
    CLLocationCoordinate2D userCoord = CLLocationCoordinate2DMake(self.userCoordinates.coordinate.latitude , self.userCoordinates.coordinate.longitude);
    
    NSLog(@"Adjusting Map: %f, %f", self.userCoordinates.coordinate.latitude,
          self.userCoordinates.coordinate.longitude);
    
    MKCoordinateRegion adjustedRegion = [self.mv regionThatFits:MKCoordinateRegionMakeWithDistance(userCoord, 8000, 8000)];
    [self.mv setRegion:adjustedRegion animated:NO];
}

-(void)setCityFromCLLocation:(CLLocation *)location
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (error)
         {
             NSLog(@"failed with error: %@", error);
             return;
         }
         if(placemarks.count > 0)
         {
             NSString *MyAddress = @"";
             NSString *city = @"";
             NSString *state = @"";
             
             CLPlacemark *myPlacemark = [placemarks objectAtIndex:0];
             
             if([myPlacemark.addressDictionary objectForKey:@"FormattedAddressLines"] != NULL)
                 MyAddress = [[myPlacemark.addressDictionary objectForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
             else
                 MyAddress = @"Address Not founded";
             
             if([myPlacemark.addressDictionary objectForKey:@"City"] != NULL)
                 city = [myPlacemark.addressDictionary objectForKey:@"City"];
             if (myPlacemark.administrativeArea != NULL) {
                 state = myPlacemark.administrativeArea;
             }
             
              NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
             if (![city isEqualToString:[userDetails objectForKey:@"city"]] || ![state isEqualToString:[userDetails objectForKey:@"state"]]) {
                 [userDetails setObject:city forKey:@"city"];
                 [userDetails setObject:state forKey:@"state"];
                 [userDetails synchronize];
                 NSLog(@"Current City, State: %@,%@", city, state);
                 
                 if ([self.delegate respondsToSelector:@selector(saveCity:state:)]) {
                     [self.delegate saveCity:city state:state];
                 }
             }
             
             NSString *locationString = [NSString stringWithFormat:@"%@, %@", city, state];
             NSLog(@"SETTING USER LOCATION TO %@", locationString);
             [self setUserLocationToCity:locationString];
             
             if (self.resettingLocation) {
                 if ([self.delegate respondsToSelector:@selector(finishedResettingNewLocation)]) {
                     [self.delegate finishedResettingNewLocation];
                 }
             }
             self.resettingLocation = NO;
         }
     }];
}

-(void)setUserLocationToCity:(NSString*)city {
    CLGeocoder *geo = [[CLGeocoder alloc] init];
    [geo geocodeAddressString:city completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            if ([placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks objectAtIndex:0];
                CLLocation *location = placemark.location;
                NSLog(@"setting user coordinates from city name to %f %f", location.coordinate.latitude, location.coordinate.longitude);
                self.userCoordinates = location;
                [self updateLocation];
                 self.mv.showsUserLocation = YES;
            }
        } else {
            NSLog(@"Error: %@", error);
        }
    }];
}

-(void)showListView {
    if ([self.delegate respondsToSelector:@selector(showListView)]) {
        [self.delegate showListView];
    }
}

#pragma mark CLLocationManager

-(void)locationManager:(CLLocationManager *)manager
   didUpdateToLocation:(CLLocation *)newLoc
          fromLocation:(CLLocation *)oldLoc {
    NSLog(@"LOCATION MANAGER: Did update location manager: %f, %f", newLoc.coordinate.latitude,
          newLoc.coordinate.longitude);
    self.userCoordinates = newLoc;
    [self setCityFromCLLocation:newLoc];
    
    [self.locationManager stopUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
}

#pragma mark -
#pragma mark Button Actions

- (IBAction)settingsPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(showSettingsView)]) {
        [self.delegate showSettingsView];
    }
}

- (IBAction)btnMovePanelRight:(id)sender
{
    UIButton *button = sender;
    switch (button.tag) {
        case 0: {
            [_delegate movePanelToOriginalPosition];
            break;
        }
            
        case 1: {
            [_delegate movePanelRight];
            break;
        }
            
        default:
            break;
    }
}

- (IBAction)btnMovePanelLeft:(id)sender
{
    UIButton *button = sender;
    switch (button.tag) {
        case 0: {
            [_delegate movePanelToOriginalPosition];
            break;
        }
            
        case 1: {
            [_delegate movePanelLeft];
            break;
        }
            
        default:
            break;
    }
}

- (IBAction)showListViewForPlace:(UIButton*)sender
{
    Place *p = [self.annotationsArray objectAtIndex:sender.tag];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if ([sharedDataManager.currentCommitmentPlace.placeId isEqualToString:p.placeId]) {
        if([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
            [self.delegate removePreviousCommitment];
        }
        if ([self.delegate respondsToSelector:@selector(removeCommitmentFromDatabase)]) {
            [self.delegate removeCommitmentFromDatabase];
        }
        
        UIButton *button = (UIButton*)sender;
        [button setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    } else {
        if ([self.delegate respondsToSelector:@selector(commitToPlace:)]) {
            [self.delegate commitToPlace:p];
            UIButton *button = (UIButton*)sender;
            [button setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
        }
    }
}

#pragma mark MapView delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, set no callout and return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        ((MKUserLocation *)annotation).title = @"";
        FBProfilePictureView *profileView = [[FBProfilePictureView alloc] initWithFrame:CGRectMake(-15.0, 0, 40.0, 40.0)];
        profileView.profileID = sharedDataManager.facebookId;
        profileView.layer.cornerRadius = CORNER_RADIUS;
        profileView.clipsToBounds = YES;
        profileView.tag = 2;
        MKAnnotationView * annotationView = [[MKAnnotationView alloc] initWithFrame:CGRectMake(0, 0, 40.0, 40.0)];
        [annotationView addSubview:profileView];
        annotationView.annotation = annotation;
        return annotationView;
    }
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[TetherAnnotation class]])
    {
        // Try to dequeue an existing pin view first.
        TetherAnnotationView *pinView = [[TetherAnnotationView alloc] init];
        pinView.userInteractionEnabled = YES;
        
        TetherAnnotation *annotationPoint = (TetherAnnotation*)annotation;
        Place *p = annotationPoint.place;
        
        pinView = [[TetherAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotationView"];
        pinView.canShowCallout = YES;
        UIImage *pinImage = [UIImage imageNamed:@"LocationIcon"];
        pinView.tag = 1;
        pinView.image = NULL;
        pinView.frame = CGRectMake(0, 0, 40.0, 40.0);
        UIImageView *imageView = [[UIImageView alloc] initWithImage:pinImage];
        imageView.frame = CGRectMake(0, 0, 40.0, 40.0);
        
        // If an existing pin view was not available, create one.
        UILabel *numberLabel = [[UILabel alloc] init];
        UIFont *helveticaNeueSmall = [UIFont fontWithName:@"HelveticaNeue-Bold" size:10];
        numberLabel.font = helveticaNeueSmall;
        numberLabel.text = [NSString stringWithFormat:@"%d", [((TetherAnnotation*)annotation).place.friendsCommitted count]];
        CGSize size = [numberLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeueSmall}];
        numberLabel.frame = CGRectMake((pinView.frame.size.width - size.width) / 2.0, (pinView.frame.size.height - size.height) / 4.0, MIN(size.width, 20), MIN(size.height, 15.0));
        numberLabel.adjustsFontSizeToFitWidth = YES;
        numberLabel.textColor = [UIColor whiteColor];
        
        [pinView addSubview:imageView];
        [pinView addSubview:numberLabel];
    
        UIButton* rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25.0, 25.0)];
        [rightButton setTitle:@"t" forState:UIControlStateNormal];
        UIFont *helvetica = [UIFont fontWithName:@"HelveticaNeueLTStd-UltLt" size:25];
        rightButton.titleLabel.font = helvetica;
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if ([p.placeId isEqualToString:sharedDataManager.currentCommitmentPlace.placeId]) {
            [rightButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
        } else {
             [rightButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
        }
        [rightButton addTarget:self action:@selector(showListViewForPlace:) forControlEvents:UIControlEventTouchUpInside];
        pinView.rightCalloutAccessoryView = rightButton;
    
        UILabel* leftLabel = [[UILabel alloc] init];
        leftLabel.userInteractionEnabled = YES;
        [leftLabel setTextColor:[UIColor whiteColor]];
        UIFont *helveticaNeue = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
        [leftLabel setFont:helveticaNeue];
        [leftLabel setText:[NSString stringWithFormat:@"  %d",[((TetherAnnotation*)annotation).place.friendsCommitted count]]];
        size = [leftLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeue}];
        leftLabel.frame = CGRectMake(0, -2.0, size.width + 10.0, 45.0);
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width + 10.0, 45.0)];
        [backgroundView setBackgroundColor:UIColorFromRGB(0x8e0528)];
        [backgroundView addSubview:leftLabel];
        pinView.leftCalloutAccessoryView = backgroundView;
    
        [self.annotationsArray addObject:p];
        
        rightButton.tag = [self.annotationsArray indexOfObject:p];
        
        int i = 0;

        for (id friendId in p.friendsCommitted) {
            if (i < MAX_FRIENDS_ON_PIN) {
                FBProfilePictureView *profileView = [[FBProfilePictureView alloc] initWithFrame:CGRectMake(-15.0, 0, 40.0, 40.0)];
                profileView.profileID = friendId;
                profileView.layer.cornerRadius = CORNER_RADIUS;
                profileView.clipsToBounds = YES;
                profileView.tag = 2;
                [pinView addSubview:profileView];
                profileView.alpha = 0.0;
                CGRect frame;
                switch (i) {
                    case 0:
                        frame = CGRectMake(-DISTANCE_FACE_TO_PIN, 0, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 1:
                        frame = CGRectMake(DISTANCE_FACE_TO_PIN + 5.0, 0, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 2:
                        if ([p.friendsCommitted count] == 3) {
                            frame = CGRectMake(0, DISTANCE_FACE_TO_PIN +5.0, FACE_SIZE, FACE_SIZE);
                            profileView.frame = frame;
                        } else {
                            frame = CGRectMake(DISTANCE_FACE_TO_PIN - 5.0, DISTANCE_FACE_TO_PIN +5.0, FACE_SIZE, FACE_SIZE);
                            profileView.frame = frame;
                        }
                        break;
                    case 3:
                         frame = CGRectMake(-DISTANCE_FACE_TO_PIN + 5.0, DISTANCE_FACE_TO_PIN + 5.0, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                        break;
                    case 4:
                        frame = CGRectMake(0.0, -DISTANCE_FACE_TO_PIN -5.0, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 5:
                        frame = CGRectMake(-DISTANCE_FACE_TO_PIN - FACE_SIZE / 2.0, FACE_SIZE / 2.0, FACE_SIZE*0.75, FACE_SIZE*0.75);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 6:
                        frame = CGRectMake(+DISTANCE_FACE_TO_PIN + FACE_SIZE / 2.0, FACE_SIZE / 2.0, FACE_SIZE*0.75, FACE_SIZE*0.75);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 7:
                        frame = CGRectMake(0.0, DISTANCE_FACE_TO_PIN + 5.0 + FACE_SIZE / 2.0, FACE_SIZE*0.75, FACE_SIZE*0.75);
                        profileView.frame = frame;
                        break;
                    case 8:
                        frame = CGRectMake(-DISTANCE_FACE_TO_PIN - FACE_SIZE / 4.0, -DISTANCE_FACE_TO_PIN - FACE_SIZE / 4.0, FACE_SIZE*0.75, FACE_SIZE*0.75);
                        profileView.frame = frame;
                        break;
                    case 9:
                        frame = CGRectMake(DISTANCE_FACE_TO_PIN + FACE_SIZE / 4.0, -DISTANCE_FACE_TO_PIN - FACE_SIZE / 4.0, FACE_SIZE*0.75, FACE_SIZE*0.75);
                        profileView.frame = frame;
                        break;
                    case 10:
                        frame = CGRectMake(-DISTANCE_FACE_TO_PIN - FACE_SIZE / 2.0, 0.0, 30.0, 30.0);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 11:
                        frame = CGRectMake(DISTANCE_FACE_TO_PIN + FACE_SIZE / 2.0 + 5.0, 0.0, 30.0, 30.0);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 12:
                        frame = CGRectMake(-DISTANCE_FACE_TO_PIN - FACE_SIZE / 4.0, DISTANCE_FACE_TO_PIN + FACE_SIZE / 2.0 + 5.0, 30.0, 30.0);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 13:
                        frame = CGRectMake(DISTANCE_FACE_TO_PIN + FACE_SIZE / 4.0, DISTANCE_FACE_TO_PIN + FACE_SIZE / 2.0 + 5.0, 30.0, 30.0);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 14:
                        frame = CGRectMake(0.0, DISTANCE_FACE_TO_PIN + FACE_SIZE, 30.0, 30.0);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    default:
                         break;
                }
            }
            i++;
        }
        [self addPlaceTouchViewForAnnotationView:pinView];
        pinView.placeTouchView.tag = [self.annotationsArray indexOfObject:p];
        
        [self.placeToAnnotationViewDictionary setObject:pinView forKey:p.placeId];
        return pinView;
    }
    return nil;
}

-(void)addPlaceTouchViewForAnnotationView:(TetherAnnotationView*)pinView {
    UIFont *systemFont = [UIFont systemFontOfSize:18.0];
    UIFont *subtitleSystemFont = [UIFont systemFontOfSize:14.0];
    CGSize titleSize = [((TetherAnnotation*)pinView.annotation).place.name sizeWithAttributes:@{NSFontAttributeName:systemFont}];
    CGSize subtitleSize = [((TetherAnnotation*)pinView.annotation).place.address sizeWithAttributes:@{NSFontAttributeName:subtitleSystemFont}];
    CGFloat width = MAX(titleSize.width,subtitleSize.width);
    
    pinView.placeTouchView = [[UIView alloc] initWithFrame:CGRectMake(- width / 2.0, -58.0, MIN(MAX(titleSize.width,subtitleSize.width), self.view.frame.size.width - 100.0), 45.0)];
    pinView.placeTouchView.userInteractionEnabled = NO;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPlacePage:)];
    [pinView.placeTouchView addGestureRecognizer:tap];
    
    [pinView addSubview:pinView.placeTouchView];
}

- (void)openPlacePage:(UIGestureRecognizer *) sender
{
    if (self.listViewOpen == NO) {
        UIView *view = sender.view;
        Place *p = [self.annotationsArray objectAtIndex:view.tag];
        if ([self.delegate respondsToSelector:@selector(openPageForPlaceWithId:)]) {
            self.listViewOpen = YES;
            [self.delegate goToPlaceInListView:p.placeId];
        }
    }
}

-(void) annotationClick:(UIGestureRecognizer *) sender {
    MKAnnotationView *view = (MKAnnotationView*)sender.view;
    [self.mv deselectAnnotation:view.annotation animated:YES];
    view.tag = 0;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(annotationClick:)];
    [view addGestureRecognizer:singleTap];
    
    if (view.tag == 1) {
        for (UIView *subView in view.subviews) {
            if (subView.tag == 2) {
                CGRect frame = subView.frame;
                frame.size.width = 0;
                frame.size.height = 0;
                subView.frame = frame;
                subView.alpha = 1.0;
            }
        }
        
        //show faces
        [UIView animateWithDuration:0.3f
                              delay:0.0
             usingSpringWithDamping:0.8
              initialSpringVelocity:5.0
                            options:0
                         animations:^{
                             for (UIView *subView in view.subviews) {
                                 if (subView.tag == 2) {
                                     CGRect frame = subView.frame;
                                     frame.size.width = FACE_SIZE;
                                     frame.size.height = FACE_SIZE;
                                     subView.frame = frame;
                                 }
                             }
                         }
                         completion:^(BOOL finished) {
                             [self layoutTouchEventForAnnotationView:((TetherAnnotationView*)view)];
                         }];
        view.tag = 0;
    } else {
        [self.mv deselectAnnotation:view.annotation animated:YES];
        view.tag = 1;
    }
}

-(void)layoutTouchEventForAnnotationView:(TetherAnnotationView*)view {
     ((TetherAnnotationView*)view).placeTouchView.userInteractionEnabled = YES;

    [view bringSubviewToFront:view.placeTouchView];
    if (view.frame.origin.x > self.view.frame.size.width / 2.0 ) {
        CGFloat originRight = view.frame.origin.x +((TetherAnnotationView*)view).placeTouchView.frame.size.width / 2.0 + ((TetherAnnotationView*)view).rightCalloutAccessoryView.frame.size.width + 40.0;
        if (originRight > self.view.frame.size.width) {
            CGFloat offset = originRight - self.view.frame.size.width;
            CGRect frame = view.placeTouchView.frame;
            frame.origin.x = - frame.size.width / 2.0 - abs(offset);
            view.placeTouchView.frame = frame;
            return;
        }
    } else {
        CGFloat originX = view.frame.origin.x - view.placeTouchView.frame.size.width / 2.0 - ((TetherAnnotationView*)view).leftCalloutAccessoryView.frame.size.width;
        if (originX < 0) {
            CGRect frame = view.placeTouchView.frame;
            frame.origin.x = - frame.size.width / 2.0 + abs(originX);
            view.placeTouchView.frame = frame;
            return;
        }
    }
    CGRect frame = view.placeTouchView.frame;
    frame.origin.x = - frame.size.width / 2.0;
    view.placeTouchView.frame = frame;
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
        [view removeGestureRecognizer:recognizer];
    }
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         for (UIView *subView in view.subviews) {
                             if (subView.tag == 2) {
                                 subView.alpha = 0.0;
                             }
                         }                     }
                     completion:^(BOOL finished){
                          ((TetherAnnotationView*)view).placeTouchView.userInteractionEnabled = NO;
                         [((TetherAnnotationView*)view).placeTouchView setBackgroundColor:[UIColor clearColor]];
                     }];
    view.tag = 1;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    TetherAnnotationView *aV;
    for (aV in views) {
        CGRect endFrame = aV.frame;
        
        aV.frame = CGRectMake(aV.frame.origin.x, aV.frame.origin.y - 230.0, aV.frame.size.width, aV.frame.size.height);
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.45];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [aV setFrame:endFrame];
        [UIView commitAnimations];
        
    }
}


-(void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    if (!self.mapHasAdjusted) {
        NSLog(@"Did finish loading map");
        [self updateLocation];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
