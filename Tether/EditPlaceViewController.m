//
//  EditPlaceViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-04-22.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "EditPlaceViewController.h"

#define STATUS_BAR_HEIGHT 20.0
#define SPINNER_SIZE 30.0
#define TOP_BAR_HEIGHT 70.0

@interface EditPlaceViewController () <UIAlertViewDelegate>
@property (strong, nonatomic) TethrButton *saveButton;
@property (strong, nonatomic) UIButton *deleteButton;
@end

@implementation EditPlaceViewController

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
    
    self.topBarLabel.text = @"Edit Location";
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    [self.topBarLabel setFont:montserrat];
    CGSize size = [self.topBarLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.topBarLabel.frame= CGRectMake((self.view.frame.size.width - size.width) / 2.0, STATUS_BAR_HEIGHT + (self.topBar.frame.size.height - STATUS_BAR_HEIGHT - size.height) / 2.0, size.width, size.height);
    [self.topBarLabel setTextColor:[UIColor whiteColor]];
    [self.topBar addSubview:self.topBarLabel];
    
    self.nameTextField.text = self.place.name;
    
    if (self.place.address) {
        self.addressTextField.text = self.place.address;
    }
    
    if (self.place.memo) {
        self.memoTextField.text = self.place.memo;
    }
    
    if (self.place.isPrivate) {
        self.privateSwitch.on = self.place.isPrivate;
    }
    
    self.annotation = [[MKPointAnnotation alloc] init];
    self.annotation.coordinate = self.place.coord;
    self.annotation.title = self.nameTextField.text;
    [self.mv addAnnotation:self.annotation];
    [self.mv selectAnnotation:self.annotation animated:NO];
    
    [self zoomToPoint];
    
    self.saveButton = [[TethrButton alloc] init];
    self.saveButton.frame = self.createButton.frame;
    [self.saveButton setNormalColor:[UIColor whiteColor]];
    [self.saveButton setHighlightedColor:UIColorFromRGB(0x8e0528)];
    [self.saveButton setTitle:@"Save" forState:UIControlStateNormal];
    [self.saveButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    self.saveButton.titleLabel.font = montserrat;
    [self.saveButton addTarget:self action:@selector(savePlace:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.saveButton];
    
    self.deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40.0, (self.topBar.frame.size.height - 25.0 + STATUS_BAR_HEIGHT) / 2.0, 25.0, 25.0)];
    [self.deleteButton setImage:[UIImage imageNamed:@"Trash"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.deleteButton];
}

-(void)zoomToPoint {
    CLLocationCoordinate2D userCoord = CLLocationCoordinate2DMake(self.place.coord.latitude , self.place.coord.longitude);
    
    MKCoordinateRegion adjustedRegion = [self.mv regionThatFits:MKCoordinateRegionMakeWithDistance(userCoord, 1000, 1000)];
    [self.mv setRegion:adjustedRegion animated:NO];
}

#pragma mark button actions

-(IBAction)savePlace:(id)sender {
    if (self.nameTextField.text) {
        PFObject *placeObject = [PFObject objectWithoutDataWithClassName:@"TethrPlace" objectId:self.place.placeId];
        BOOL changesMade = NO;
        
        if (![self.nameTextField.text isEqualToString:self.place.name]) {
            [placeObject setObject:self.nameTextField.text forKey:@"name"];
            self.place.name = self.nameTextField.text;
            changesMade = YES;
        }
        
        if (![self.addressTextField.text isEqualToString:self.place.address]) {
            [placeObject setObject:self.addressTextField.text forKey:@"address"];
            self.place.address = self.addressTextField.text;
            changesMade = YES;
        }
        
        if (![self.memoTextField.text isEqualToString:self.place.memo]) {
            [placeObject setObject:self.memoTextField.text forKey:@"memo"];
            self.place.memo = self.memoTextField.text;
            changesMade = YES;
        }
        
        if (self.annotation.coordinate.latitude != self.place.coord.latitude || self.annotation.coordinate.longitude != self.place.coord.longitude) {
            [placeObject setObject:[PFGeoPoint geoPointWithLatitude:self.annotation.coordinate.latitude
                                                    longitude:self.annotation.coordinate.longitude]  forKey:@"coordinate"];
            self.place.coord = self.annotation.coordinate;
            changesMade = YES;
        }
        
        if (changesMade) {
            [placeObject saveInBackground];
            
            [self updateActivities];
            
            if ([self.delegate respondsToSelector:@selector(refreshPlaceDetails:)]) {
                [self.delegate refreshPlaceDetails:self.place];
            }
        }
    }
    [self showConfirmationForAction:@"save"];
}

-(void)updateActivities {
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"placeId" equalTo:self.place.placeId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        for (PFObject *activity in objects) {
            [activity setObject:self.nameTextField.text forKey:@"placeName"];
            
            [activity setObject:self.addressTextField.text forKey:@"address"];
            
            [activity setObject:self.memoTextField.text forKey:@"memo"];
            
            [activity setObject:[PFGeoPoint geoPointWithLatitude:self.annotation.coordinate.latitude
                                                      longitude:self.annotation.coordinate.longitude]  forKey:@"coordinate"];
            [activity saveInBackground];
        }
    }];
}

-(IBAction)deleteClicked:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm"
                                                    message:@"Are you sure you want to delete this location?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = 1;
    [alert show];
}

-(void)removeLocationFromPlacesListForId:(NSString*)placeId {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [sharedDataManager.tethrPlacesDictionary removeObjectForKey:placeId];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        
    } else {
        if (alertView.tag) {
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            [sharedDataManager.tethrPlacesDictionary removeObjectForKey:self.place.placeId];
            [self showConfirmationForAction:@"delete"];
            PFObject *placeObject = [PFObject objectWithoutDataWithClassName:@"TethrPlace"
                                                                    objectId:self.place.placeId];
            
            [placeObject deleteEventually];
            
            PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
            [query whereKey:@"placeId" equalTo:placeObject.objectId];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                for (PFObject *activity in objects) {
                    [activity deleteInBackground];
                }
            }];
        } else {
            [self.delegate closeCreatePlaceVC];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
