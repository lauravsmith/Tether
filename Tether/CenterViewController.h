//
//  CenterViewController.h
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "LeftPanelViewController.h"
#import "Place.h"
#import "TethrButton.h"
#import "ViewController.h"

#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
//RGB color macro
#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@protocol CenterViewControllerDelegate <NSObject>

@required
- (void)movePanelRight;
- (void)movePanelLeft;
- (void)movePanelToOriginalPosition;
-(void)showListView;
-(void)finishedResettingNewLocation;
-(void)saveCity:(NSString*)city state:(NSString*)state;
-(void)goToPlaceInListView:(id)placeId;
-(void)commitToPlace:(Place *)place;
-(void)pollDatabase;
-(void)openPageForPlaceWithId:(id)placeId;
-(void)removePreviousCommitment;
-(void)removeCommitmentFromDatabase;
-(void)newPlaceAdded;
-(void)photoCapture;
-(void)showYourProfileScrollToPost:(NSString*)postId;
-(void)openNewPlaceWithId:(NSString*)placeId;
-(void)showProfileOfFriend:(Friend*)user;
-(void)confirmPosting:(NSString*)postType;
-(void)reloadActivity;
@end

@interface CenterViewController : ViewController <MKMapViewDelegate>

@property (nonatomic, assign) id<CenterViewControllerDelegate> delegate;

@property (strong, nonatomic) CLLocationManager * locationManager;
@property (strong, nonatomic) UILabel *tethrLabel;
@property (strong, nonatomic) UIActivityIndicatorView * spinner;
@property (retain, nonatomic) UIButton * numberButton;
@property (strong, nonatomic) UIImageView *switchPicker;
@property (strong, nonatomic) UIButton *leftPanelButtonLarge;
@property (retain, nonatomic) UIButton * triangleButton;
@property (strong, nonatomic) TethrButton *listViewButton;
@property (strong, nonatomic) UIButton *listViewButtonLarge;
@property (retain, nonatomic) UIButton *settingsButtonLarge;
@property (retain, nonatomic) MKMapView * mv;
@property (retain, nonatomic) NSMutableDictionary * placeToAnnotationDictionary;
@property (retain, nonatomic) NSMutableDictionary * placeToAnnotationViewDictionary;
@property (assign, nonatomic) bool resettingLocation;
@property (nonatomic, strong) FBProfilePictureView *userProfilePictureView;
@property (strong, nonatomic) UILabel *notificationsLabel;
@property (retain, nonatomic) TethrButton *notificationsButton;
@property (strong, nonatomic) UIButton *notificationsButtonLarge;
@property (retain, nonatomic) UIButton * cityButton;
@property (retain, nonatomic) UIButton * placeButton;
@property (retain, nonatomic) UIButton * placeNumberButton;
@property (retain, nonatomic) UIView * bottomBar;
@property (strong, nonatomic) NSMutableArray * annotationsArray;
@property (strong, nonatomic) CLLocation *userCoordinates;
@property (assign, nonatomic) bool listViewOpen;
@property (assign, nonatomic) bool dragging;
@property (retain, nonatomic) UIView * switchBar;
@property (strong, nonatomic) UIView *searchBarBackground;
@property (retain, nonatomic) UIView * coverView;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UITableView *followingActivitytsTableView;
- (IBAction)mapClicked:(id)sender;
- (IBAction)feedClicked:(id)sender;
-(void)updateLocation;
-(void)setCityFromCLLocation:(CLLocation*)location;
-(void)layoutNumberButton;
-(void)layoutCurrentCommitment;
-(void)locationSetup;
-(void)refreshNotificationsNumber;
- (void)movePanelLeft:(UIGestureRecognizer*)recognizer;
-(void)setUserLocationToCity:(NSString*)city;
-(void)refreshComplete;
-(void)loadFollowingActivity;
-(void)showHeader;
-(void)hideHeader;
@end
