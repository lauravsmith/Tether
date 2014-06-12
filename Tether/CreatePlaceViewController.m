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
#define STATUS_BAR_HEIGHT 20.0
#define SPINNER_SIZE 30.0
#define TOP_BAR_HEIGHT 70.0

@interface CreatePlaceViewController () <MKMapViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UIAlertViewDelegate>
@property (retain, nonatomic) UIView *whiteView;
@property (retain, nonatomic) UIView *greyView;
@property (strong, nonatomic) UIView *dismissKeyboardView;
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
    self.topBarLabel.text = @"Create a Location";
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    [self.topBarLabel setFont:montserrat];
    CGSize size = [self.topBarLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.topBarLabel.frame= CGRectMake((self.view.frame.size.width - size.width) / 2.0, STATUS_BAR_HEIGHT + (self.topBar.frame.size.height - STATUS_BAR_HEIGHT - size.height) / 2.0, size.width, size.height);
    [self.topBarLabel setTextColor:[UIColor whiteColor]];
    [self.topBar addSubview:self.topBarLabel];
    
    self.cancelButton = [[UIButton alloc] init];
    [self.cancelButton setImage:[UIImage imageNamed:@"Cancel"] forState:UIControlStateNormal];
    [self.cancelButton setImageEdgeInsets:UIEdgeInsetsMake(33.0, 10.0, 25.0, 20.0)];
    self.cancelButton.frame = CGRectMake(0.0, 0.0, 55.0, 83.0);
    [self.cancelButton addTarget:self action:@selector(closeView:) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.cancelButton];
    
    // mapview setup
    self.mv = [[MKMapView alloc] initWithFrame:CGRectMake(0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
    self.mv.delegate = self;
    [self.mv setShowsUserLocation:YES];
    
    [self.view addSubview:self.mv];
    
    self.whiteView = [[UIView alloc] initWithFrame:CGRectMake(0, self.topBar.frame.size.height, self.view.frame.size.width, ROW_HEIGHT *4)];
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
    
    self.memoLabel = [[UILabel alloc] init];
    self.memoLabel.text = @"Memo";
    self.memoLabel.font = montserrat;
    size = [self.memoLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.memoLabel.frame = CGRectMake(10.0, ROW_HEIGHT*2 + (ROW_HEIGHT - size.height) / 2.0, size.width, size.height);
    [self.whiteView addSubview:self.memoLabel];
    
    self.memoTextField = [[UITextField alloc] init];
    self.memoTextField.delegate = self;
    self.memoTextField.font = montserrat;
    self.memoTextField.placeholder = @"Optional";
    self.memoTextField.frame = CGRectMake(100.0, ROW_HEIGHT*2, self.view.frame.size.width - 100.0, ROW_HEIGHT);
    [self.whiteView addSubview:self.memoTextField];
    
    self.privateLabel = [[UILabel alloc] init];
    self.privateLabel.text = @"Only visible to my friends";
    self.privateLabel.font = montserrat;
    size = [self.privateLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.privateLabel.frame = CGRectMake(10.0, ROW_HEIGHT * 3 + (ROW_HEIGHT - size.height) / 2.0, size.width, size.height);
    [self.whiteView addSubview:self.privateLabel];
    
    self.privateSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70.0, self.privateLabel.frame.origin.y - 6.0, 0.0, 0.0)];
    [self.privateSwitch setOnTintColor:UIColorFromRGB(0x8e0528)];
    [self.whiteView addSubview:self.privateSwitch];
    
    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(10.0, ROW_HEIGHT, self.view.frame.size.width - 10.0, 1.0)];
    [divider setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [divider setAlpha:0.5];
    [self.whiteView addSubview:divider];
    
    UIView *divider2 = [[UIView alloc] initWithFrame:CGRectMake(10.0, ROW_HEIGHT * 2, self.view.frame.size.width - 10.0, 1.0)];
    [divider2 setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [divider2 setAlpha:0.5];
    [self.whiteView addSubview:divider2];
    
    UIView *divider3 = [[UIView alloc] initWithFrame:CGRectMake(10.0, ROW_HEIGHT * 3, self.view.frame.size.width - 10.0, 1.0)];
    [divider3 setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [divider3 setAlpha:0.5];
    [self.whiteView addSubview:divider3];
    
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
    
    self.createButton = [[TethrButton alloc] init];
    self.createButton.frame = self.greyView.frame;
    [self.createButton setNormalColor:[UIColor whiteColor]];
    [self.createButton setHighlightedColor:UIColorFromRGB(0x8e0528)];
    [self.createButton setTitle:@"Create!" forState:UIControlStateNormal];
    [self.createButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    [self.createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    self.createButton.titleLabel.font = montserrat;
    [self.createButton addTarget:self action:@selector(createPlace:) forControlEvents:UIControlEventTouchUpInside];
    [self.createButton setHidden:YES];
    [self.view addSubview:self.createButton];
    
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
    
    MKCoordinateRegion adjustedRegion = [self.mv regionThatFits:MKCoordinateRegionMakeWithDistance(userCoord, 2000, 2000)];
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

-(void)showConfirmationForAction:(NSString*)action {
    
    self.confirmationView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 200.0) / 2.0, (self.view.frame.size.height - 100.0) / 2.0, 200.0, 100.0)];
    [self.confirmationView setBackgroundColor:[UIColor whiteColor]];
    self.confirmationView.alpha = 0.8;
    self.confirmationView.layer.cornerRadius = 10.0;
    
    self.confirmationLabel = [[UILabel alloc] init];
    if ([action isEqualToString:@"save"]) {
        self.confirmationLabel.text = @"Saving Changes...";
        [self performSelector:@selector(dismissConfirmationForAction:) withObject:@"save" afterDelay:2.0];
    } else if ([action isEqualToString:@"create"]) {
        self.confirmationLabel.text = @"Creating Location...";
        [self performSelector:@selector(dismissConfirmationForAction:) withObject:@"create" afterDelay:2.0];
    } else {
        self.confirmationLabel.text = @"Deleting Location...";
        [self performSelector:@selector(dismissConfirmationForAction:) withObject:@"delete" afterDelay:2.0];
    }
    self.confirmationLabel.textColor = UIColorFromRGB(0x8e0528);
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.confirmationLabel.font = montserrat;
    CGSize size = [self.confirmationLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.confirmationLabel.frame = CGRectMake((self.confirmationView.frame.size.width - size.width) / 2.0, (self.confirmationView.frame.size.height - size.height) / 2.0, size.width, size.height);
    [self.confirmationView addSubview:self.confirmationLabel];
    
    [self.view addSubview:self.confirmationView];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.confirmationView.frame.size.width - SPINNER_SIZE) / 2.0, self.confirmationLabel.frame.origin.y + self.confirmationLabel.frame.size.height + 2.0, SPINNER_SIZE, SPINNER_SIZE)];
    self.activityIndicatorView.color = UIColorFromRGB(0x8e0528);
    [self.confirmationView addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
}

-(void)dismissConfirmationForAction:(NSString*)action {
    [self.activityIndicatorView stopAnimating];
    if ([action isEqualToString:@"save"]) {
        self.confirmationLabel.text = @"Saved!";
    } else if ([action isEqualToString:@"create"]) {
        self.confirmationLabel.text = @"Created!";
    } else {
        self.confirmationLabel.text = @"Deleted!";
    }
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    self.confirmationLabel.font = montserrat;
    CGSize size = [self.confirmationLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.confirmationLabel.frame = CGRectMake((self.confirmationView.frame.size.width - size.width) / 2.0, (self.confirmationView.frame.size.height - size.height) / 2.0, size.width, size.height);
    
    [UIView animateWithDuration:0.2
                          delay:0.5
                        options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                            self.confirmationView.alpha = 0.2;
                        } completion:^(BOOL finished) {
                            [self.confirmationView removeFromSuperview];
                            if ([action isEqualToString:@"save"]) {
                                [self closeView];
                            } else {
                                [self closeView];
                                [self closeViewAfterDelete];
                            }
                        }];
}

-(void)closeView {
    if ([self.delegate respondsToSelector:@selector(closeCreatePlaceVC)]) {
        [self.delegate closeCreatePlaceVC];
    }
}

-(void)closeViewAfterDelete {
    if ([self.delegate respondsToSelector:@selector(refreshListAfterDelete)]) {
        [self.delegate refreshListAfterDelete];
    }
}

#pragma mark IBAction

-(IBAction)createPlace:(id)sender {
    id<MKAnnotation> annotation = [self.mv.annotations objectAtIndex:0.0];
    
    PFObject *placeObject = [PFObject objectWithClassName:@"TethrPlace"];
    [placeObject setObject:self.nameTextField.text forKey:@"name"];

    [placeObject setObject:[PFGeoPoint geoPointWithLatitude:annotation.coordinate.latitude
                                                     longitude:annotation.coordinate.longitude] forKey:@"coordinate"];
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [placeObject setObject:[userDetails objectForKey:@"city"] forKey:@"city"];
    [placeObject setObject:[userDetails objectForKey:@"state"] forKey:@"state"];
    
    if (![self.addressTextField.text isEqualToString:@""]) {
        [placeObject setObject:self.addressTextField.text forKey:@"address"];
    }
    
    if (![self.memoTextField.text isEqualToString:@""]) {
        [placeObject setObject:self.memoTextField.text forKey:@"memo"];
    }
    
    [placeObject setObject:[NSNumber numberWithBool:self.privateSwitch.on] forKey:@"private"];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [placeObject setObject:sharedDataManager.facebookId forKey:@"owner"];
    
    [placeObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [placeObject setObject:placeObject.objectId forKey:@"placeId"];
            [placeObject saveInBackground];
            [self addNewLocationToPlacesListForId:placeObject.objectId];
            [self createActivityObjectForPlace:placeObject];
        }
    }];
    [self showConfirmationForAction:@"create"];
}

-(void)createActivityObjectForPlace:(PFObject*)placeObject {
    PFObject *activity = [PFObject objectWithClassName:@"Activity"];
    PFUser *user = [PFUser currentUser];
    NSString *content = [NSString stringWithFormat:@"%@ created a location %@", [user objectForKey:@"firstName"], self.nameTextField.text];
    [activity setObject:content forKey:@"content"];
    [activity setObject:@"createLocation" forKey:@"type"];
    [activity setObject:[NSDate date] forKey:@"date"];
    [activity setObject:user forKey:@"user"];
    [activity setObject:[user objectForKey:@"facebookId"] forKey:@"facebookId"];
    [activity setObject:[user objectForKey:@"cityLocation"] forKey:@"city"];
    [activity setObject:[user objectForKey:@"stateLocation"] forKey:@"state"];
    [activity setObject:placeObject.objectId forKey:@"placeId"];
    [activity setObject:[placeObject objectForKey:@"name"] forKey:@"placeName"];
    if ([placeObject objectForKey:@"address"]) {
        [activity setObject:[placeObject objectForKey:@"address"] forKey:@"address"];
    }
    [activity setObject:[placeObject objectForKey:@"coordinate"] forKey:@"coordinate"];
    if ([placeObject objectForKey:@"memo"]) {
        [activity setObject:[placeObject objectForKey:@"memo"] forKey:@"memo"];
    }
    [activity setObject:[placeObject objectForKey:@"owner"] forKey:@"owner"];
    if (self.privateSwitch.on) {
        [activity setObject:[NSNumber numberWithBool:YES] forKey:@"private"];
    }
    [activity saveInBackground];
}

-(void)addNewLocationToPlacesListForId:(NSString*)placeId {
    Place *place = [[Place alloc] init];
    place.placeId = placeId;
    place.name = self.nameTextField.text;
    if (![self.addressTextField.text isEqualToString:@""]) {
        place.address = self.addressTextField.text;
    }
    
    if (![self.memoTextField.text isEqualToString:@""]) {
        place.memo = self.memoTextField.text;
    }
    
    place.isPrivate = self.privateSwitch.on;
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    place.city = [userDetails objectForKey:@"city"];
    place.state = [userDetails objectForKey:@"state"];
    
    id<MKAnnotation> annotation = [self.mv.annotations objectAtIndex:0.0];
    place.coord = annotation.coordinate;
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    place.owner = sharedDataManager.facebookId;
    
    place.friendsCommitted = [[NSMutableSet alloc] init];
    
    [sharedDataManager.tethrPlacesDictionary setObject:place forKey:place.placeId];
    [self.delegate openNewPlaceWithId:place.placeId];
}

-(IBAction)closeView:(id)sender {
    if (self.annotation || ![self.nameTextField.text isEqualToString:@""]) {
        NSString *message;
        if (self.place.placeId) {
            message = @"Are you sure you want to discard your changes?";
        } else {
            message = @"Are you sure you want to stop creating this location?";
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm"
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Yes", nil];
        [alert show];
    } else {
        [self.delegate closeCreatePlaceVC];
    }
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
    [self.mv removeAnnotation:self.annotation];
    self.annotation = [[MKPointAnnotation alloc] init];
    self.annotation.coordinate = touchMapCoordinate;
    if ([self.nameTextField.text isEqualToString:@""]) {
        self.annotation.title = @"";
    } else {
        self.annotation.title = self.nameTextField.text;
    }
    [self.mv addAnnotation:self.annotation];
    
    [self.mv selectAnnotation:self.annotation animated:NO];
    
    if (!self.greyView.hidden) {
        [self.greyView setHidden:YES];
        [self.createButton setHidden:NO];
    }
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
    if (textField == self.nameTextField) {
        if (![textField.text isEqualToString:@""] && [self.mv.annotations count]  > 0) {
            [self.createButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
            [self.createButton setEnabled:YES];
        } else {
            [self.createButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
            [self.createButton setEnabled:NO];
        }
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
    } else {
        [self.delegate closeCreatePlaceVC];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
