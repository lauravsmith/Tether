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

#import <FacebookSDK/FacebookSDK.h>
#import <MapKit/MapKit.h> 

#define TOP_BAR_HEIGHT 120.0
#define MAX_FRIENDS_ON_PIN 4.0
#define DISTANCE_FACE_TO_PIN 20.0
#define FACE_SIZE 40.0
#define CORNER_RADIUS 20.0
#define PADDING 10.0

@interface CenterViewController () <MKMapViewDelegate, CLLocationManagerDelegate>
@property (retain, nonatomic) NSString * cityLocation;
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UIImageView * whiteLineImageView;
@property (assign, nonatomic) bool mapHasAdjusted;
@property (strong, nonatomic) UIButton *listViewButton;
@property (strong, nonatomic) UIButton *arrowButton;
@property (retain, nonatomic) UIView * bottomBar;
@property (retain, nonatomic) UILabel * bottomBarLabel;
@property (retain, nonatomic) UIButton * bottomRightButton;
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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // top bar setup
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x770051)];
    [self.view addSubview:self.topBar];
    self.topBar.layer.masksToBounds = NO;
    self.topBar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.topBar.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    self.topBar.layer.shadowOpacity = 0.5f;
    
    // mapview setup
    self.mv = [[MKMapView alloc] initWithFrame:CGRectMake(0, self.topBar.frame.origin.y + self.topBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    self.mv.delegate = self;
    [self.view addSubview:self.mv];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate  = self;
    self.userCoordinates = [[CLLocation alloc] init];
    
    [self locationSetup];

    // number of friends going out label setup
    self.numberButton = [[UIButton alloc] initWithFrame:CGRectMake(PADDING, PADDING, 110, 80)];
    [self.numberButton setBackgroundColor:[UIColor clearColor]];
    [self.numberButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.numberButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    UIFont *champagne = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:81];
    self.numberButton.titleLabel.font = champagne;
    [self.numberButton addTarget:self action:@selector(btnMovePanelRight:) forControlEvents:UIControlEventTouchUpInside];
    self.numberButton.tag = 1;
    [self.topBar addSubview:self.numberButton];

    // city location label setup
    self.cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.numberButton.frame.origin.y + self.numberButton.frame.size.height, 110, 20)];
    [self.cityLabel setBackgroundColor:[UIColor clearColor]];
    [self.cityLabel setTextColor:[UIColor whiteColor]];
    UIFont *champagneItalic = [UIFont fontWithName:@"Champagne&Limousines-Italic" size:18.0f];
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    self.cityLabel.text = [userDetails objectForKey:@"city"];
    [self.cityLabel setFont:champagneItalic];
    [self.topBar addSubview:self.cityLabel];
    
    // white top bar line setup
    self.whiteLineImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Whiteline.png"]];
    CGRect frame = self.whiteLineImageView.frame;
    frame.size.height = self.topBar.frame.size.height - 20.0;
    frame.size.width = 80.0;
    frame.origin.x = 75.0;
    frame.origin.y = 10.0;
    self.whiteLineImageView.frame = frame;
    [self.topBar addSubview:self.whiteLineImageView];
    
    // list view button setup
    self.listViewButton = [[UIButton alloc] initWithFrame:CGRectMake(130, 30, 180, 30)];
    [self.listViewButton setTitle:@"where will you go?" forState:UIControlStateNormal];
    [self.listViewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.listViewButton.titleLabel.font = [UIFont fontWithName:@"Champagne&Limousines" size:22.0f];
    [self.listViewButton addTarget:self action:@selector(showListView) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.listViewButton];
    
    // list view arrow button setup
    self.arrowButton = [[UIButton alloc] initWithFrame:CGRectMake(self.listViewButton.frame.origin.x + (self.listViewButton.frame.size.width - 18)/ 2, self.listViewButton.frame.origin.y + self.listViewButton.frame.size.height, 18, 18)];
    [self.arrowButton setImage:[UIImage imageNamed:@"Arrow"] forState:UIControlStateNormal];
//    [self.arrowButton addTarget:self action:@selector(searchPlaces:) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.arrowButton];
    
    // bottom nav bar setup
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 50.0, self.view.frame.size.width, 60.0)];
    
    self.bottomBar.layer.masksToBounds = NO;
    self.bottomBar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bottomBar.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    self.bottomBar.layer.shadowOpacity = 0.5f;

    UIImage *shadowImage = [[UIImage imageNamed:@"ListIcon.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0) resizingMode:UIImageResizingModeStretch];
    UIImageView *shadowImageView = [[UIImageView alloc] initWithImage:shadowImage];
    shadowImageView.frame = CGRectMake(-62.0, self.view.frame.size.height - 80.0, 442, 120.0);
    [self.view addSubview:shadowImageView];
    
    // left panel view button setup
    UIImage *leftPanelButtonImage = [UIImage imageNamed:@"Gear"];
    self.bottomLeftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 10, 30, 30)];
    [self.bottomLeftButton setImage:leftPanelButtonImage forState:UIControlStateNormal];
    
    // bottom right button setup
    UIImage *bottomRightButtonImage = [UIImage imageNamed:@"Gear"];
    self.bottomRightButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 30.0, 10, 30, 30)];
    [self.bottomRightButton setImage:bottomRightButtonImage forState:UIControlStateNormal];
    [self.bottomBar addSubview:self.bottomRightButton];
    self.bottomRightButton.tag = 1;
    [self.bottomRightButton addTarget:self action:@selector(settingsPressed:) forControlEvents:UIControlEventTouchDown];
    
    // Tether label setup
    self.bottomBarLabel = [[UILabel alloc] init];
    self.bottomBarLabel.text = @"T  E  T  H  E  R";
    frame = self.bottomBarLabel.frame;
    frame.size.width = [self.bottomBarLabel.text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:22]}].width;
    frame.size.height =  [self.bottomBarLabel.text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:22]}].height;
    frame.origin.x = (self.view.frame.size.width - frame.size.width) / 2;
    frame.origin.y = (self.bottomBar.frame.size.height - frame.size.height) / 2;
    self.bottomBarLabel.frame = frame;
    self.bottomBarLabel.font = [UIFont systemFontOfSize:22.0];
    self.bottomBarLabel.textColor = [UIColor whiteColor];
    self.bottomBarLabel.layer.shadowOpacity = 0.5;
    self.bottomBarLabel.layer.shadowRadius = 0;
    self.bottomBarLabel.layer.shadowColor = [UIColor grayColor].CGColor;
    self.bottomBarLabel.layer.shadowOffset = CGSizeMake(1.0, 1.0);
    [self.bottomBar addSubview:self.bottomBarLabel];

    [self.view addSubview:self.bottomBar];
    [self restartTimer];
}

-(void)locationSetup {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if ([userDetails boolForKey:@"useCurrentLocation"]) {
        [self.locationManager startUpdatingLocation];
    } else {
        NSString *city = [userDetails objectForKey:@"city"];
        NSString *state = [userDetails objectForKey:@"state"];
        NSString *locationString = [NSString stringWithFormat:@"%@, %@", city, state];
        NSLog(@"%@", locationString);
        [self setUserLocationToCity:locationString];
    }
}

-(void)layoutNumberLabel {
    UIFont *champagne = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:81];
    CGSize size = [self.numberButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:champagne}];
    CGRect frame = self.numberButton.frame;
    frame.size.width = size.width;
    self.numberButton.frame = frame;
}

-(void)restartTimer {
    [self.finishLoadingTimer invalidate];
    self.finishLoadingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                               target:self
                                                             selector:@selector(mapLoadingIsFinished)
                                                             userInfo:nil
                                                              repeats:NO];
//    NSLog(@"timer started");
}

- (void)mapLoadingIsFinished
{
    NSLog(@"timer stopped");
    self.mapHasAdjusted = YES;
}


-(void)updateLocation {
//    self.mv.showsUserLocation = YES;
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
                 
                 PFUser *user = [PFUser currentUser];
                 [user setObject:city forKey:@"cityLocation"];
                 [user setObject:state forKey:@"stateLocation"];
                 [user saveEventually];
                 NSLog(@"PARSE SAVE: saving your location from the map");
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
        MKAnnotationView *pinView = [[MKAnnotationView alloc] init];
        //[mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
            // If an existing pin view was not available, create one.
            UILabel *numberButton = [[UILabel alloc] initWithFrame:CGRectMake(18.0, 10.0, 10.0, 20.0)];
            numberButton.text = [annotation subtitle];
            numberButton.textColor = [UIColor whiteColor];
            
            pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotationView"];
            pinView.canShowCallout = YES;
            UIImage *pinImage = [UIImage imageNamed:@"PinIcon"];
        
            pinView.tag = 1;
            pinView.image = NULL;
            pinView.frame = CGRectMake(0, 0, 50.0, 50.0);
            UIImageView *imageView = [[UIImageView alloc] initWithImage:pinImage];
            imageView.frame = CGRectMake(0, 0, 50.0, 50.0);
            [pinView addSubview:imageView];
            [pinView addSubview:numberButton];
            
            TetherAnnotation *annotationPoint = (TetherAnnotation*)annotation;
            Place *p = annotationPoint.place;
        
            for (int i = 0; i < MIN([p.friendsCommitted count], MAX_FRIENDS_ON_PIN); i++) {
                FBProfilePictureView *profileView = [[FBProfilePictureView alloc] initWithFrame:CGRectMake(-15.0, 0, 40.0, 40.0)];
                profileView.profileID = [p.friendsCommitted objectAtIndex:i];
                profileView.layer.cornerRadius = CORNER_RADIUS;
                profileView.clipsToBounds = YES;
                [profileView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
                [profileView.layer setBorderWidth:2.0];
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
                        frame = CGRectMake(DISTANCE_FACE_TO_PIN, 0, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                    case 2:
                        frame = CGRectMake(0, DISTANCE_FACE_TO_PIN, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                    case 3:
                        frame = CGRectMake(0, -DISTANCE_FACE_TO_PIN, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                    default:
                        break;

            }
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
