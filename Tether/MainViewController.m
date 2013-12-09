//
//  MainViewController.m
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "AppDelegate.h"
#import "CenterViewController.h"
#import "DecisionViewController.h"
#import "Friend.h"
#import "LeftPanelViewController.h"
#import "Datastore.h"
#import "MainViewController.h"
#import "Place.h"
#import "PlacesViewController.h"
#import "SettingsViewController.h"
#import "TetherAnnotation.h"
#import "TetherCache.h"

#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

#define CENTER_TAG 1
#define LEFT_PANEL_TAG 2
#define CORNER_RADIUS 4
#define SLIDE_TIMING .25
#define PANEL_WIDTH 60
#define POLLING_INTERVAL 20

@interface MainViewController () <CenterViewControllerDelegate, DecisionViewControllerDelegate, LeftPanelViewControllerDelegate, UIGestureRecognizerDelegate, SettingsViewControllerDelegate, PlacesViewControllerDelegate>

@property (nonatomic, strong) CenterViewController *centerViewController;
@property (nonatomic, strong) LeftPanelViewController *leftPanelViewController;
@property (nonatomic, strong) DecisionViewController *decisionViewController;
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) PlacesViewController *placesViewController;
@property (nonatomic, assign) BOOL showingLeftPanel;
@property (nonatomic, assign) BOOL showPanel;
@property (nonatomic, assign) BOOL leftPanelNotShownYet;
@property (nonatomic, strong) NSString *facebookId;
@property (nonatomic, assign) CGPoint preVelocity;
@property (nonatomic, assign) NSTimer *pollingTimer;
@property (nonatomic, assign) int timerMultiplier;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.leftPanelNotShownYet = YES;
        self.placesViewController = [[PlacesViewController alloc] init];
        self.placesViewController.delegate = self;
        self.timerMultiplier = 1;
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"View did load");
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    [self setupView];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(sessionStateChanged:)
     name:SessionStateChangedNotification
     object:nil];
    
    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:POLLING_INTERVAL*self.timerMultiplier
                                     target:self
                                   selector:@selector(timerFired)
                                   userInfo:nil
                                    repeats:YES];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (FBSession.activeSession.isOpen) {
        [self populateUserDetails];
    }
}

-(void)pollDatabase {
    [self queryFriendsStatus];
    [self.pollingTimer invalidate];
    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:POLLING_INTERVAL*self.timerMultiplier
                                                           target:self
                                                         selector:@selector(timerFired)
                                                         userInfo:nil
                                                          repeats:YES];
}

-(void)timerFired{
    self.timerMultiplier +=1;
    [self pollDatabase];
    if ([self shouldShouldDecisionView]) {
        [self setupView];
    }
}

#pragma mark load user facebook information

- (void)sessionStateChanged:(NSNotification*)notification {
    NSLog(@"SessionStateChanged");
    [self populateUserDetails];
}

- (void)populateUserDetails
{
    if (FBSession.activeSession.isOpen) {
        [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection,
                                                               id result,
                                                               NSError *error) {
            if (!error) {
                [self facebookRequestDidLoad:result];
            }
        }];
    }
}


-(void)populateFacebookFriends:(NSArray *) friends {
//    NSLog(@"Loading your facebook friends: %lu friends", friends.count);
    
    NSMutableArray *facebookFriendsIds = [[NSMutableArray alloc] init];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    if ([friends count] > [sharedDataManager.facebookFriends count]) {
        for (NSDictionary *friendData in friends) {
            [facebookFriendsIds addObject:friendData[@"id"]];
        }
    }
    
    sharedDataManager.facebookFriends = facebookFriendsIds;
    
    PFUser *user = [PFUser currentUser];
    [user setObject:sharedDataManager.facebookFriends forKey:@"facebookFriends"];
    [user saveEventually];
    NSLog(@"PARSE SAVE: saving your facebook friends");
    [self queryFriendsStatus];

}

-(void)facebookRequestDidLoad:(id)result {
    PFUser *user = [PFUser currentUser];
    
    NSArray *data = [result objectForKey:@"data"];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    if (data) {
        sharedDataManager.facebookFriends = [[NSMutableArray alloc] initWithCapacity:[data count]];
        [self populateFacebookFriends:data];

    } else {
        if (user) {
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            
            NSString *facebookName = result[@"name"];
            if (facebookName && [facebookName length] != 0) {
                [user setObject:facebookName forKey:@"displayName"];
                sharedDataManager.name = facebookName;
                [self.leftPanelViewController updateNameLabel];
            } else {
                [user setObject:@"Someone" forKey:@"displayName"];
            }
            
            NSString *facebookId = result[@"id"];
            if (facebookId && [facebookId length] != 0) {
                [user setObject:facebookId forKey:@"facebookId"];
                self.leftPanelViewController.profilePictureView.profileID = facebookId;
                sharedDataManager.facebookId = facebookId;
                self.facebookId = facebookId;
            }
            NSLog(@"PARSE SAVE: setting your user details");
            [user saveEventually];
        }
        
        [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id friends, NSError *error) {
            if (!error) {
                [self facebookRequestDidLoad:friends];
            }
        }];
    }
}

-(void)queryFriendsStatus{
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSString *city = [userDetails objectForKey:@"city"];
    NSString *state = [userDetails objectForKey:@"state"];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSLog(@"Your city: %@ state: %@", city, state);
    
    PFQuery *facebookFriendsQuery = [PFUser query];
    [facebookFriendsQuery whereKey:@"facebookId" containedIn:sharedDataManager.facebookFriends];
    [facebookFriendsQuery whereKey:@"cityLocation" equalTo:city];
    [facebookFriendsQuery whereKey:@"stateLocation" equalTo:state];

    [facebookFriendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"QUERY: queried your facebook friends status who are on Tether");
            sharedDataManager.tetherFriendsDictionary = [[NSMutableDictionary alloc] init];
            sharedDataManager.tetherFriendsNearbyDictionary = [[NSMutableDictionary alloc] init];
            
            for (PFUser *user in objects) {
                Friend *friend = [[Friend alloc] init];
                friend.friendID = user[@"facebookId"];
                friend.name = user[@"displayName"];
                friend.timeLastUpdated = user[@"timeLastUpdated"];
                friend.status = [user[@"status"] boolValue];
                friend.placeId = @"";
                if ([sharedDataManager.friendsToPlacesMap objectForKey:friend.friendID]) {
                    friend.placeId = [sharedDataManager.friendsToPlacesMap objectForKey:friend.friendID];
                }
                
                if ([user[@"cityLocation"] isEqualToString:city] && [user[@"stateLocation"] isEqualToString:state]) {
                    [sharedDataManager.tetherFriendsNearbyDictionary setObject:friend forKey:friend.friendID];
                }
                [sharedDataManager.tetherFriendsDictionary setObject:friend forKey:friend.friendID];
            }
            
            [self sortTetherFriends];
            [self.placesViewController getFriendsCommitments];
        } else {
            // The network was inaccessible and we have no cached data for r
            // this query.
            NSLog(@"Query error");
        }
    }];
}

-(void)sortTetherFriends {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSDate *startTime = [self getStartTime];
    NSMutableArray *tempFriendsGoingOut = [[NSMutableArray alloc] init];
    NSMutableArray *tempFriendsNotGoingOut = [[NSMutableArray alloc] init];
    NSMutableArray *tempFriendsUndecided = [[NSMutableArray alloc] init];
    
    for (id key in sharedDataManager.tetherFriendsNearbyDictionary) {
        Friend *friend = [sharedDataManager.tetherFriendsNearbyDictionary objectForKey:key];
        if (friend) {
            if ([startTime compare:friend.timeLastUpdated] == NSOrderedDescending) {
                [tempFriendsUndecided addObject:friend];
            } else {
                if (friend.status) {
                    [tempFriendsGoingOut addObject:friend];
                } else {
                    [tempFriendsNotGoingOut addObject:friend];
                }
            }
        }
    }
    
    if ([tempFriendsUndecided count] != [sharedDataManager.tetherFriendsUndecided count]) {
        sharedDataManager.tetherFriendsUndecided = tempFriendsUndecided;
    }
    
    if ([tempFriendsGoingOut count] != [sharedDataManager.tetherFriendsGoingOut count]) {
        sharedDataManager.tetherFriendsGoingOut = tempFriendsGoingOut;
    }
    
    if ([tempFriendsNotGoingOut count] != [sharedDataManager.tetherFriendsNotGoingOut count]) {
        sharedDataManager.tetherFriendsNotGoingOut = tempFriendsNotGoingOut;
    }
    
    self.centerViewController.numberLabel.text = [NSString stringWithFormat:@"%lu", [sharedDataManager.tetherFriendsGoingOut count]];
    [self.leftPanelViewController updateFriendsList];
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

-(NSDate*)getEndTime{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:now];
    
    [components setHour:6.0];
    [deltaComps setDay:1.0];
    return [calendar dateByAddingComponents:deltaComps toDate:[calendar dateFromComponents:components] options:0];
}

#pragma mark -
#pragma mark Setup View

- (void)setupView
{
    // setup center view
    self.centerViewController = [[CenterViewController alloc] init];
    self.centerViewController.view.tag = CENTER_TAG;
    self.centerViewController.delegate = self;
    self.centerViewController.placeToAnnotationDictionary = [[NSMutableDictionary alloc] init];
    
    [self.view addSubview:self.centerViewController.view];
    [self addChildViewController:_centerViewController];
    [_centerViewController didMoveToParentViewController:self];
    
    [self setupGestures];
    
    // define the view for the left panel view controller
    self.leftPanelViewController = [[LeftPanelViewController alloc] init];
    self.leftPanelViewController.view.tag = LEFT_PANEL_TAG;
    self.leftPanelViewController.delegate = self;
    
    // check if user has input status today
    if ([self shouldShouldDecisionView]) {
        self.decisionViewController = [[DecisionViewController alloc] init];
        self.decisionViewController.delegate = self;
        [self.view addSubview:self.decisionViewController.view];
        [self addChildViewController:_decisionViewController];
        [_decisionViewController didMoveToParentViewController:self];
    } else {
        [self.leftPanelViewController updateStatus];
    }
}

-(BOOL)shouldShouldDecisionView {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSDate *timeLastUpdated = [userDetails objectForKey:@"timeLastUpdated"];
    NSDate *beginningTime = [self getStartTime];
    if (timeLastUpdated == nil || [beginningTime compare:timeLastUpdated] == NSOrderedDescending) {
        return YES;
    }
    return NO;
}

- (void)showCenterViewWithShadow:(BOOL)value withOffset:(double)offset
{
    if (value)
    {
        [_centerViewController.view.layer setCornerRadius:CORNER_RADIUS];
        [_centerViewController.view.layer setShadowColor:[UIColor blackColor].CGColor];
        [_centerViewController.view.layer setShadowOpacity:0.8];
        [_centerViewController.view.layer setShadowOffset:CGSizeMake(offset, offset)];
        
    }
    else
    {
        [_centerViewController.view.layer setCornerRadius:0.0f];
        [_centerViewController.view.layer setShadowOffset:CGSizeMake(offset, offset)];
    }
}

- (void)resetMainView
{
    if (_leftPanelViewController != nil)
    {
        _centerViewController.bottomLeftButton.tag = 1;
        self.showingLeftPanel = NO;
    }
    
    // remove view shadows
    [self showCenterViewWithShadow:NO withOffset:0];
}

- (UIView *)getLeftView
{
    // init view if it doesn't already exist
    if (self.leftPanelNotShownYet == YES)
    {
        self.leftPanelNotShownYet = NO;
        [self.view addSubview:self.leftPanelViewController.view];
        
        [self addChildViewController:_leftPanelViewController];
        [_leftPanelViewController didMoveToParentViewController:self];
        
        _leftPanelViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }
    
    self.showingLeftPanel = YES;
    
    // set up view shadows
    [self showCenterViewWithShadow:YES withOffset:-2];
    
    UIView *view = self.leftPanelViewController.view;
    return view;
}

#pragma mark -
#pragma mark Swipe Gesture Setup/Actions

- (void)setupGestures
{
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movePanel:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    
    [_centerViewController.view addGestureRecognizer:panRecognizer];
}

-(void)movePanel:(id)sender
{
    [[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];
    
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    CGPoint velocity = [(UIPanGestureRecognizer*)sender velocityInView:[sender view]];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) {
        UIView *childView = nil;
        
        if(velocity.x > 0) {
            childView = [self getLeftView];
        }
        // Make sure the view you're working with is front and center.
        [self.view sendSubviewToBack:childView];
        [[sender view] bringSubviewToFront:[(UIPanGestureRecognizer*)sender view]];
    }
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        
        if(velocity.x > 0) {
        } else {
        }
        
        if (!_showPanel) {
            [self movePanelToOriginalPosition];
        } else {
            if (_showingLeftPanel) {
                [self movePanelRight];
            }
        }
    }
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateChanged) {
        if(velocity.x > 0) {
        } else {
        }
        
        // Are you more than halfway? If so, show the panel when done dragging by setting this value to YES (1).
        _showPanel = abs([sender view].center.x - _centerViewController.view.frame.size.width/2) > _centerViewController.view.frame.size.width/2;
        
        // Allow dragging only in x-coordinates by only updating the x-coordinate with translation position.
        float xCoord = MAX(160.0,[sender view].center.x + translatedPoint.x);
        [sender view].center = CGPointMake(xCoord, [sender view].center.y);
        [(UIPanGestureRecognizer*)sender setTranslation:CGPointMake(0,0) inView:self.view];
        
        // If you needed to check for a change in direction, you could use this code to do so.
        if(velocity.x*_preVelocity.x + velocity.y*_preVelocity.y > 0) {
            // NSLog(@"same direction");
        } else {
            // NSLog(@"opposite direction");
        }
        
        _preVelocity = velocity;
    }
}

#pragma mark -
#pragma mark CenterViewControllerDelegate Actions

-(void)showSettingsView
{
    if (!self.settingsViewController) {
        self.settingsViewController = [[SettingsViewController alloc] init];
        self.settingsViewController.delegate = self;
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        self.settingsViewController.userProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)sharedDataManager.facebookId pictureCropping:FBProfilePictureCroppingSquare];
    }
    
    [self addChildViewController:self.settingsViewController];
    [self.settingsViewController didMoveToParentViewController:self];
    [self.settingsViewController.view setFrame:CGRectMake( 0.0f, 480.0f, 320.0f, 768.0f)]; //notice this is OFF screen!
    [self.view addSubview:self.settingsViewController.view];
    [UIView beginAnimations:@"animateTableView" context:nil];
    [UIView setAnimationDuration:0.2];
    [self.settingsViewController.view setFrame:CGRectMake( 0.0f, 0.0f, 320.0f, 768.0f)]; //notice this is ON screen!
    [UIView commitAnimations];
}

-(void)showListView
{
    if (!self.placesViewController) {
        self.placesViewController = [[PlacesViewController alloc] init];
        self.placesViewController.delegate = self;
    }
    
    [self addChildViewController:self.placesViewController];
    [self.placesViewController didMoveToParentViewController:self];
    [self.placesViewController.view setFrame:CGRectMake(320.0f, 0.0f, 320.0f, 768.0f)];
    [self.view addSubview:self.placesViewController.view];
    [UIView beginAnimations:@"animateTableView" context:nil];
    [UIView setAnimationDuration:0.2];
    [self.placesViewController.view setFrame:CGRectMake( 0.0f, 0.0f, 320.0f, 768.0f)]; //notice this is ON screen!
    [UIView commitAnimations];
}

- (void)movePanelRight // to show left panel
{
    UIView *childView = [self getLeftView];
    [self.view sendSubviewToBack:childView];
    
    [UIView animateWithDuration:SLIDE_TIMING delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _centerViewController.view.frame = CGRectMake(self.view.frame.size.width - PANEL_WIDTH, 0, self.view.frame.size.width, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             
                             _centerViewController.bottomLeftButton.tag = 0;
                         }
                     }];
}

- (void)movePanelToOriginalPosition
{
    [UIView animateWithDuration:SLIDE_TIMING delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _centerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             
                             [self resetMainView];
                         }
                     }];
}

#pragma mark QuestionViewControllerDelegate

-(void)handleChoice:(BOOL)choice {
    [self.decisionViewController.view removeFromSuperview];
    [self.decisionViewController removeFromParentViewController];

    Datastore *sharedDataManager = [Datastore sharedDataManager];
    sharedDataManager.status = choice;
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [userDetails setBool:choice forKey:@"status"];
    [userDetails setObject:[NSDate date] forKey:@"timeLastUpdated"];
    [self.leftPanelViewController updateStatus];
    
    NSLog(@"PARSE SAVE: Saving your going out choice");
    PFUser *user = [PFUser currentUser];
    [user setObject:[NSNumber numberWithBool:choice] forKey:@"status"];
    [user setObject:[NSDate date] forKey:@"timeLastUpdated"];
    [user saveInBackground];
    
    [self.centerViewController updateLocation];
    
    if (!choice) {
        // TODO: change button text if not going out?
    }
}

#pragma mark SettingsViewControllerDelegate

-(void)closeSettings {
    [UIView animateWithDuration:0.2 animations:^{
        [self.settingsViewController.view setFrame:CGRectMake( 0.0f, 480.0f, 320.0f, 768.0f)];
    } completion:^(BOOL finished) {
        [self.settingsViewController.view removeFromSuperview];
        [self.settingsViewController removeFromParentViewController];
    }];
}

-(void)updateStatus {
    [self.leftPanelViewController updateStatus];
}

#pragma mark LeftPanelViewControllerDelegate
-(void)goToPlaceInListView:(id)placeId {
    [self movePanelToOriginalPosition];
    [self showListView];
    [self.placesViewController.placesTableView reloadData];
    [self.placesViewController scrollToPlaceWithId:placeId];
}

#pragma mark PlacesViewControllerDelegate

-(void)placeMarkOnMapView:(Place*)place {
    TetherAnnotation *annotation = [[TetherAnnotation alloc] init];
    [annotation setCoordinate:place.coord];
    [annotation setTitle:[NSString stringWithFormat:@"%@", place.name]];
    [annotation setSubtitle:[NSString stringWithFormat:@"%lu", (unsigned long)[place.friendsCommitted count]]];
    annotation.place = place;
    
    if ([self.centerViewController.placeToAnnotationDictionary objectForKey:place.placeId]) {
            [self removePlaceMarkFromMapView:place];
    }
    [self.centerViewController.placeToAnnotationDictionary  setObject:annotation forKey:place.placeId];
        if (place.numberCommitments > 0) {
            NSLog(@"MAIN VIEW: Adding annotation with %d commitments", place.numberCommitments);
            [self.centerViewController.mv addAnnotation:annotation];
        }
}

-(void)removePlaceMarkFromMapView:(Place*)place {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (place) {
        TetherAnnotation *annotation = [self.centerViewController.placeToAnnotationDictionary objectForKey:place.placeId];
        [self.centerViewController.mv removeAnnotation:annotation];

        if ([sharedDataManager.placesDictionary objectForKey:place.placeId]) {
            [sharedDataManager.placesDictionary setObject:place forKey:place.placeId];
        }
        NSLog(@"MAIN VIEW: Removed annotation for %@", place.name);
    }
}

-(void)closeListView {
    [UIView animateWithDuration:0.2 animations:^{
        [self.placesViewController.view setFrame:CGRectMake(320.0f, 0.0f, 320.0f, 768.0f)];
    } completion:^(BOOL finished) {
        [self.placesViewController.view removeFromSuperview];
        [self.placesViewController removeFromParentViewController];
    }];
}

-(void)setPlace:(id)placeId forFriend:(id)friendId {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    Friend *currentFriend = [sharedDataManager.tetherFriendsNearbyDictionary objectForKey:friendId];
    currentFriend.placeId = placeId;
    if (currentFriend) {
        [sharedDataManager.friendsToPlacesMap setObject:placeId forKey:friendId];
        [sharedDataManager.tetherFriendsNearbyDictionary setObject:currentFriend forKey:placeId];
    }
}

-(void)commitToPlace:(Place *)place {
    PFQuery *query = [PFQuery queryWithClassName:@"Commitment"];
    [query whereKey:@"facebookId" equalTo:self.facebookId];
    
    [query whereKey:@"dateCommitted" greaterThan:[self getStartTime]];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFObject *commitment;
            if ([objects count] > 0) {
                commitment = [objects objectAtIndex:0];
            } else {
                commitment = [PFObject objectWithClassName:@"Commitment"];
                [commitment setObject:self.facebookId forKey:@"facebookId"];
            }
            
            if (place.placeId) {
                [commitment setObject:place.placeId forKey:@"placeId"];
            }

            [commitment setObject:[NSDate date] forKey:@"dateCommitted"];
            
            if (place.coord.latitude && place.coord.longitude) {
                [commitment setObject:[PFGeoPoint geoPointWithLatitude:place.coord.latitude
                                                             longitude:place.coord.longitude] forKey:@"placePoint"];
            }

            if (place.name) {
                [commitment setObject:place.name forKey:@"placeName"];
            }

            if (place.city) {
                [commitment setObject:place.city forKey:@"placeCityName"];
            }

            if (place.address) {
                [commitment setObject:place.address forKey:@"address"];
            }

            [commitment saveInBackground];
            NSLog(@"PARSE SAVE: saving your commitment");
            
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            if (!sharedDataManager.status) {
                sharedDataManager.status = YES;
                [self.leftPanelViewController updateStatus];
                
                PFUser *user = [PFUser currentUser];
                [user setObject:[NSNumber numberWithBool:YES] forKey:@"status"];
                [user setObject:[NSDate date] forKey:@"timeLastUpdated"];
                [user saveInBackground];
            }
            sharedDataManager.currentCommitmentParseObject = commitment;
            
            [self placeMarkOnMapView:place];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
