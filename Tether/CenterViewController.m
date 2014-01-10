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

#define BOTTOM_BAR_HEIGHT 40.0
#define CORNER_RADIUS 20.0
#define DISTANCE_FACE_TO_PIN 20.0
#define FACE_SIZE 40.0
#define MAX_FRIENDS_ON_PIN 4.0
#define PADDING 20.0
#define TOP_BAR_HEIGHT 70.0

@interface CenterViewController () <MKMapViewDelegate, CLLocationManagerDelegate>
@property (retain, nonatomic) NSString * cityLocation;
@property (retain, nonatomic) UIView * topBar;
@property (assign, nonatomic) bool mapHasAdjusted;
@property (strong, nonatomic) UIButton *listViewButton;
@property (strong, nonatomic) CLLocationManager * locationManager;
@property (strong, nonatomic) CLLocation *userCoordinates;
@property (strong, nonatomic) NSTimer * finishLoadingTimer;

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
    
    // mapview setup
    self.mv = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.mv.delegate = self;
    [self.view addSubview:self.mv];
    
    // top bar setup
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:self.topBar];
    [self.topBar setAlpha:0.85];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate  = self;
    self.userCoordinates = [[CLLocation alloc] init];
    
    [self locationSetup];

    // number of friends going out label setup
    self.numberButton = [[UIButton alloc] initWithFrame:CGRectMake(PADDING, PADDING, 40.0, 40.0)];
    [self.numberButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.numberButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    UIFont *champagneBold = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:30];
    self.numberButton.titleLabel.font = champagneBold;
    [self.numberButton addTarget:self action:@selector(btnMovePanelRight:) forControlEvents:UIControlEventTouchUpInside];
    self.numberButton.tag = 1;
    [self layoutNumberButton];
    [self.topBar addSubview:self.numberButton];
    
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.triangleButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 25.0, 15.0, 15.0)];
    [self.triangleButton setImage:triangleImage forState:UIControlStateNormal];
    [self.view addSubview:self.triangleButton];
    self.triangleButton.tag = 1;
    [self.triangleButton addTarget:self action:@selector(btnMovePanelRight:) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.triangleButton];

    // city location label setup
    self.cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, self.topBar.frame.size.height - 20.0, 110.0, 20.0)];
    [self.cityLabel setBackgroundColor:[UIColor clearColor]];
    [self.cityLabel setTextColor:[UIColor whiteColor]];
    UIFont *champagneItalic = [UIFont fontWithName:@"Champagne&Limousines-Italic" size:18.0f];
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    self.cityLabel.text = [userDetails objectForKey:@"city"];
    [self.cityLabel setFont:champagneItalic];
    [self.topBar addSubview:self.cityLabel];
    
    // list view arrow button setup
    self.listViewButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40.0, (self.topBar.frame.size.height - 25.0) / 2.0 +  5.0, 25.0, 25.0)];
    [self.listViewButton setImage:[UIImage imageNamed:@"LineNavigator"] forState:UIControlStateNormal];
    [self.listViewButton addTarget:self action:@selector(showListView) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.listViewButton];
    
    // bottom nav bar setup
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT)];
    [self.bottomBar setBackgroundColor:[UIColor whiteColor]];
    [self.bottomBar setAlpha:0.85];
    
    // left panel view button setup
    UIImage *leftPanelButtonImage = [UIImage imageNamed:@"Gear"];
    self.bottomLeftButton = [[UIButton alloc] initWithFrame:CGRectMake(10.0, (self.bottomBar.frame.size.height - 22.0) / 2, 22.0, 22.0)];
    [self.bottomLeftButton setImage:leftPanelButtonImage forState:UIControlStateNormal];
    [self.bottomBar addSubview:self.bottomLeftButton];
    self.bottomLeftButton.tag = 1;
    [self.bottomLeftButton addTarget:self action:@selector(settingsPressed:) forControlEvents:UIControlEventTouchDown];
    
    // notifications button to open right panel setup
    self.notificationsButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 30.0, 10, 30, 30)];
    [self.notificationsButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.notificationsButton setBackgroundColor:[UIColor whiteColor]];
    [self.notificationsButton addTarget:self action:@selector(btnMovePanelLeft:) forControlEvents:UIControlEventTouchUpInside];
    self.notificationsButton.tag = 1;
    [self.bottomBar addSubview:self.notificationsButton];
    [self refreshNotificationsNumber];
    
    UIFont *champagneSmall = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:18];
    UIFont *champagneExtraSmall = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:14];
    self.placeLabel = [[UILabel alloc] init];
    [self.placeLabel setFont:champagneExtraSmall];
    [self.placeLabel setTextColor:UIColorFromRGB(0x8e0528)];
    [self.bottomBar addSubview:self.placeLabel];
    
    self.placeNumberLabel = [[UILabel alloc] init];
    [self.placeNumberLabel setFont:champagneSmall];
    [self.placeNumberLabel setTextColor:UIColorFromRGB(0x8e0528)];
    [self.bottomBar addSubview:self.placeNumberLabel];
    [self layoutCurrentCommitment];
    
    [self.view addSubview:self.bottomBar];
    
    [self restartTimer];
}


-(void)layoutNumberButton {
    UIFont *champagne = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:30];
    CGSize size = [self.numberButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:champagne}];
    self.numberButton.frame = CGRectMake(PADDING, PADDING, size.width, size.height);
    self.numberButton.tag = 1;
    [self.topBar addSubview:self.numberButton];
}

-(void)layoutCurrentCommitment {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentPlace) {
        self.placeLabel.text = sharedDataManager.currentCommitmentPlace.name;
        self.placeNumberLabel.text = [NSString stringWithFormat:@"%d", sharedDataManager.currentCommitmentPlace.numberCommitments];
    } else {
        self.placeLabel.text = @"";
        self.placeNumberLabel.text = @"";
    }
    UIFont *champagneSmall = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:18];
    UIFont *champagneExtraSmall = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:14];
    CGSize size = [self.placeLabel.text sizeWithAttributes:@{NSFontAttributeName:champagneExtraSmall}];
    self.placeLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2, self.bottomBar.frame.size.height - size.height, size.width, size.height);
    size = [self.placeNumberLabel.text sizeWithAttributes:@{NSFontAttributeName:champagneSmall}];
    self.placeNumberLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2, 0, size.width, size.height);
}


-(void)refreshNotificationsNumber {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [self.notificationsButton setTitle:[NSString stringWithFormat:@"%d",sharedDataManager.notifications] forState:UIControlStateNormal];
}

-(void)locationSetup {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if ([userDetails boolForKey:@"useCurrentLocation"] || ![userDetails objectForKey:@"city"] || ![userDetails objectForKey:@"state"]) {
        [self.locationManager startUpdatingLocation];
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
    
    MKCoordinateRegion adjustedRegion = [self.mv regionThatFits:MKCoordinateRegionMakeWithDistance(userCoord, 10000, 10000)];
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
                 self.cityLabel.text = city;
                 NSLog(@"Current City, State: %@,%@", city, state);
                 Datastore *sharedDataManager = [Datastore sharedDataManager];
                 sharedDataManager.city = city;
                 sharedDataManager.state = state;
                 
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
            }
        } else {
            
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
    if ([self.delegate respondsToSelector:@selector(showListView)]) {
        [self.delegate showListView];
    }
    
    if ([self.delegate respondsToSelector:@selector(goToPlaceInListView:)]) {
        Place *p = [self.annotationsArray objectAtIndex:sender.tag];
        [self.delegate goToPlaceInListView:p.placeId];
    }
}

- (void) handlePinButtonTap:(UITapGestureRecognizer *)gestureRecognizer {
    if ([self.delegate respondsToSelector:@selector(commitToPlace:)]) {
        NSInteger index = ((UILabel*)gestureRecognizer.view).tag;
        if (index) {
            Place *p = [self.annotationsArray objectAtIndex:index];
            [self.delegate commitToPlace:p];
            if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
                [self.delegate pollDatabase];
            }
        }
    }
}

#pragma mark MapView delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[TetherAnnotation class]])
    {
        // Try to dequeue an existing pin view first.
        TetherAnnotationView *pinView = [[TetherAnnotationView alloc] init];
        
        // If an existing pin view was not available, create one.
        UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 5.0, 10.0, 20.0)];
        numberLabel.adjustsFontSizeToFitWidth = YES;
        numberLabel.text = [NSString stringWithFormat:@"%d", ((TetherAnnotation*)annotation).place.numberCommitments];
        numberLabel.textColor = [UIColor whiteColor];
        
        pinView = [[TetherAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotationView"];
        pinView.canShowCallout = YES;
        UIImage *pinImage = [UIImage imageNamed:@"LocationIcon"];
    
        pinView.tag = 1;
        pinView.image = NULL;
        pinView.frame = CGRectMake(0, 0, 40.0, 40.0);
        UIImageView *imageView = [[UIImageView alloc] initWithImage:pinImage];
        imageView.frame = CGRectMake(0, 0, 40.0, 40.0);
        [pinView addSubview:imageView];
        [pinView addSubview:numberLabel];
    
        UIButton* rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25.0, 25.0)];
        [rightButton setImage:[UIImage imageNamed:@"Arrow"] forState:UIControlStateNormal];
        [rightButton addTarget:self action:@selector(showListViewForPlace:) forControlEvents:UIControlEventTouchUpInside];
        pinView.rightCalloutAccessoryView = rightButton;
    
        UILabel* leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30.0, 50.0)];
        leftLabel.userInteractionEnabled = YES;
        [leftLabel setTextColor:[UIColor whiteColor]];
        UIFont *champagne = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:20];
        [leftLabel setFont:champagne];
        [leftLabel setText:[NSString stringWithFormat:@"  %d",((TetherAnnotation*)annotation).place.numberCommitments]];
        [leftLabel setBackgroundColor:UIColorFromRGB(0x8e0528)];
        CGSize size = [leftLabel.text sizeWithAttributes:@{NSFontAttributeName:champagne}];
        pinView.leftCalloutAccessoryView = leftLabel;
        [pinView.leftCalloutAccessoryView setFrame:CGRectMake(0, 0, size.width + 10.0, 45.0)];
    
        TetherAnnotation *annotationPoint = (TetherAnnotation*)annotation;
        Place *p = annotationPoint.place;
    
        [self.annotationsArray addObject:p];
        rightButton.tag = [self.annotationsArray indexOfObject:p];
        leftLabel.tag = rightButton.tag;
        NSLog(@"INDEX: %d", leftLabel.tag);
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                       initWithTarget:self action:@selector(handlePinButtonTap:)];
        [leftLabel addGestureRecognizer:tap];
    
        int i = 0;
        for (id friendId in p.friendsCommitted) {
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
                    frame = CGRectMake(0, DISTANCE_FACE_TO_PIN + 5.0, FACE_SIZE, FACE_SIZE);
                    profileView.frame = frame;
                    break;
                case 3:
                    frame = CGRectMake(0, -DISTANCE_FACE_TO_PIN, FACE_SIZE, FACE_SIZE);
                    profileView.frame = frame;
                    [pinView sendSubviewToBack:profileView];
                    break;
                default:
                    break;
            }
            i++;
        }
        return pinView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
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
                      }];
        view.tag = 0;
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    
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
                         
                     }];
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
