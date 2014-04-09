//
//  CreatePlaceViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-04-07.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "CreatePlaceViewController.h"
#import "Datastore.h"
#import "TetherAnnotation.h"

#define ROW_HEIGHT 40.0
#define TOP_BAR_HEIGHT 70.0

@interface CreatePlaceViewController () <MKMapViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate>

@property (retain, nonatomic) MKMapView * mv;
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UILabel * topBarLabel;
@property (retain, nonatomic) MKPointAnnotation *pa;
@property (retain, nonatomic) UIView *whiteView;
@property (retain, nonatomic) UILabel * nameLabel;
@property (retain, nonatomic) UITextField * nameTextField;
@property (retain, nonatomic) UILabel * addressLabel;
@property (retain, nonatomic) UITextField * addressTextField;
@property (retain, nonatomic) UIView *greyView;
@property (retain, nonatomic) UILabel * privateLabel;
@property (strong, nonatomic) UIView *dismissKeyboardView;
@property (strong, nonatomic) UIButton *createButton;
@property (strong, nonatomic) UIButton *cancelButton;

@end

@implementation CreatePlaceViewController

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
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // top bar setup
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, self.view.frame.size.width,TOP_BAR_HEIGHT)];
    self.topBar.layer.backgroundColor = UIColorFromRGB(0x8e0528).CGColor;
    [self.view addSubview:self.topBar];
    
    self.topBarLabel = [[UILabel alloc] init];
    self.topBarLabel.text = @"Create New Place";
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    [self.topBarLabel setFont:montserrat];
    CGSize size = [self.topBarLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.topBarLabel.frame= CGRectMake((self.view.frame.size.width - size.width) / 2.0, (self.topBar.frame.size.height - size.height) / 2.0, size.width, size.height);
    [self.topBarLabel setTextColor:[UIColor whiteColor]];
    [self.topBar addSubview:self.topBarLabel];
    
    self.createButton = [[UIButton alloc] init];
    [self.createButton setTitle:@"Create" forState:UIControlStateNormal];
    self.createButton.titleLabel.font = montserrat;
    size = [self.createButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.createButton.frame = CGRectMake(self.view.frame.size.width - size.width - 10.0, self.topBarLabel.frame.origin.y, size.width, size.height);
    [self.createButton addTarget:self action:@selector(createPlace:) forControlEvents:UIControlEventTouchUpInside];
    [self.createButton setEnabled:NO];
    [self.topBar addSubview:self.createButton];
    
    self.cancelButton = [[UIButton alloc] init];
    [self.cancelButton setTitle:@"X" forState:UIControlStateNormal];
    self.cancelButton.frame = CGRectMake(10.0, 20.0, 20.0, 20.0);
    [self.cancelButton addTarget:self action:@selector(closeView:) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.cancelButton];
    
    // mapview setup
    self.mv = [[MKMapView alloc] initWithFrame:CGRectMake(0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
    self.mv.delegate = self;
    [self.mv setShowsUserLocation:YES];
    
    [self.view addSubview:self.mv];
    
    self.whiteView = [[UIView alloc] initWithFrame:CGRectMake(0, self.topBar.frame.size.height, self.view.frame.size.width, ROW_HEIGHT *2)];
    self.whiteView.alpha = 0.85;
    [self.whiteView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.whiteView];
    
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.text = @"Name";
    self.nameLabel.font = montserrat;
    size = [self.nameLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.nameLabel.frame = CGRectMake(10.0, (ROW_HEIGHT - size.height) / 2.0, size.width, size.height);
    [self.whiteView addSubview:self.nameLabel];
    
    self.nameTextField = [[UITextField alloc] init];
    self.nameTextField.delegate = self;
    self.nameTextField.font = montserrat;
    self.nameTextField.placeholder = @"Required";
    self.nameTextField.frame = CGRectMake(100.0, 0.0, self.view.frame.size.width - 100.0, ROW_HEIGHT);
    [self.whiteView addSubview:self.nameTextField];
    
    self.addressLabel = [[UILabel alloc] init];
    self.addressLabel.text = @"Address";
    self.addressLabel.font = montserrat;
    size = [self.addressLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.addressLabel.frame = CGRectMake(10.0, ROW_HEIGHT + (ROW_HEIGHT - size.height) / 2.0, size.width, size.height);
    [self.whiteView addSubview:self.addressLabel];
    
    self.addressTextField = [[UITextField alloc] init];
    self.addressTextField.delegate = self;
    self.addressTextField.font = montserrat;
    self.addressTextField.placeholder = @"Optional";
    self.addressTextField.frame = CGRectMake(100.0, ROW_HEIGHT, self.view.frame.size.width - 100.0, ROW_HEIGHT);
    [self.whiteView addSubview:self.addressTextField];
    
    self.privateLabel = [[UILabel alloc] init];
    self.privateLabel.text = @"Only visible to my friends";
    self.privateLabel.font = montserrat;
    size = [self.privateLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.privateLabel.frame = CGRectMake(10.0, ROW_HEIGHT * 2 + (ROW_HEIGHT - size.height) / 2.0, size.width, size.height);
//    [self.whiteView addSubview:self.privateLabel];
    
    self.greyView = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - ROW_HEIGHT, self.view.frame.size.width, ROW_HEIGHT)];
    [self.greyView setBackgroundColor:[UIColor blackColor]];
    self.greyView.alpha = 0.8;
    UILabel * tapLabel = [[UILabel alloc] init];
    tapLabel.text = @"Tap the map to set the location";
    tapLabel.font = montserrat;
    size = [tapLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    tapLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, (self.greyView.frame.size.height -  size.height) / 2.0, size.width, size.height);
    [tapLabel setTextColor:[UIColor whiteColor]];
    [self.greyView addSubview:tapLabel];
    [self.view addSubview:self.greyView];
    
    self.dismissKeyboardView = [[UIView alloc] initWithFrame:CGRectMake(0, self.whiteView.frame.origin.y + self.whiteView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.whiteView.frame.origin.y - self.whiteView.frame.size.height)];
    [self.dismissKeyboardView setHidden:YES];
    [self.dismissKeyboardView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *dismissKeyboardTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleDismissKeyboardTap:)];
    [self.dismissKeyboardView addGestureRecognizer:dismissKeyboardTap];
    [self.view addSubview:self.dismissKeyboardView];
    
    [self updateLocation];
}

-(void)updateLocation {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    CLLocationCoordinate2D userCoord = CLLocationCoordinate2DMake(sharedDataManager.userCoordinates.coordinate.latitude , sharedDataManager.userCoordinates.coordinate.longitude);
    
    NSLog(@"Adjusting Map: %f, %f", sharedDataManager.userCoordinates.coordinate.latitude,
          sharedDataManager.userCoordinates.coordinate.longitude);
    
    MKCoordinateRegion adjustedRegion = [self.mv regionThatFits:MKCoordinateRegionMakeWithDistance(userCoord, 8000, 8000)];
    [self.mv setRegion:adjustedRegion animated:NO];
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self action:@selector(handleGesture:)];
    tgr.numberOfTapsRequired = 1;
    tgr.numberOfTouchesRequired = 1;
    tgr.delegate = self;
    [self.mv addGestureRecognizer:tgr];
    
    if (![self.nameTextField.text isEqualToString:@""]) {
        [self.createButton setEnabled:YES];
    }
}

#pragma mark IBAction

-(IBAction)createPlace:(id)sender {
    id<MKAnnotation> annotation = [self.mv.annotations objectAtIndex:0.0];
    
    PFObject *placeObject = [PFObject objectWithClassName:@"Place"];
    [placeObject setObject:self.nameTextField.text forKey:@"name"];

    [placeObject setObject:[PFGeoPoint geoPointWithLatitude:annotation.coordinate.latitude
                                                     longitude:annotation.coordinate.longitude] forKey:@"coordinate"];
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [placeObject setObject:[userDetails objectForKey:@"city"] forKey:@"city"];
    [placeObject setObject:[userDetails objectForKey:@"state"] forKey:@"state"];
    
    [placeObject setObject:@"tethr" forKey:@"placeSearchObjectId"];
    
    if (![self.addressTextField.text isEqualToString:@""]) {
        [placeObject setObject:self.addressTextField.text forKey:@"address"];
    }
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [placeObject setObject:sharedDataManager.facebookId forKey:@"owner"];
    
    [placeObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [placeObject setObject:placeObject.objectId forKey:@"placeId"];
            [placeObject saveInBackground];
        }
    }];
}

-(IBAction)closeView:(id)sender {
    [self.delegate closeCreatePlaceVC];
}

#pragma mark UIGestureRecognizers

- (void)handleDismissKeyboardTap:(UITapGestureRecognizer *)recognizer {
    [self.view endEditing:YES];
    [self.dismissKeyboardView setHidden:YES];
}

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mv];
    CLLocationCoordinate2D touchMapCoordinate =
    [self.mv convertPoint:touchPoint toCoordinateFromView:self.mv];
    [self.mv removeAnnotation:self.pa];
    self.pa = [[MKPointAnnotation alloc] init];
    self.pa.coordinate = touchMapCoordinate;
    if ([self.nameTextField.text isEqualToString:@""]) {
        self.pa.title = @"";
    } else {
        self.pa.title = self.nameTextField.text;
    }
    [self.mv addAnnotation:self.pa];
    
    [self.mv selectAnnotation:self.pa animated:NO];
    
    [self.greyView setHidden:YES];
}

#pragma mark UIGestureRecognizerDelegate

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark MapView delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, set no callout and return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        ((MKUserLocation *)annotation).title = @"";
        return nil;
    }
    
    // Try to dequeue an existing pin view first.
    MKAnnotationView *pinView = [[MKAnnotationView alloc] init];
    pinView.userInteractionEnabled = YES;
    pinView.annotation = annotation;

    pinView.canShowCallout = YES;
    UIImage *pinImage = [UIImage imageNamed:@"PinIcon"];
    pinView.tag = 1;
    pinView.image = NULL;
    pinView.frame = CGRectMake(0, 0, 40.0, 40.0);
    UIImageView *imageView = [[UIImageView alloc] initWithImage:pinImage];
    imageView.frame = CGRectMake(9.5, 1.0, 21.0, 38.0);
    [pinView addSubview:imageView];

    return pinView;
}

#pragma mark UITextField delegate

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.dismissKeyboardView setHidden:NO];
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    if (![textField.text isEqualToString:@""] && [self.mv.annotations count]  > 0) {
        [self.createButton setEnabled:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
