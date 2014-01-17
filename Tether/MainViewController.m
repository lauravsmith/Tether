//
//  MainViewController.m
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "AppDelegate.h"
#import "CenterViewController.h"
#import "Constants.h"
#import "DecisionViewController.h"
#import "Friend.h"
#import "FriendInviteViewController.h"
#import "FriendsListViewController.h"
#import "LeftPanelViewController.h"
#import "Datastore.h"
#import "MainViewController.h"
#import "Notification.h"
#import "Place.h"
#import "PlacesViewController.h"
#import "RightPanelViewController.h"
#import "SettingsViewController.h"
#import "TetherAnnotation.h"
#import "TetherCache.h"

#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

#define CENTER_TAG 1
#define LEFT_PANEL_TAG 2
#define RIGHT_PANEL_TAG 3
#define CORNER_RADIUS 4.0
#define SLIDE_TIMING 0.5
#define PANEL_WIDTH 60
#define POLLING_INTERVAL 20

@interface MainViewController () <CenterViewControllerDelegate, DecisionViewControllerDelegate, FriendsListViewControllerDelegate, InviteViewControllerDelegate, LeftPanelViewControllerDelegate, UIGestureRecognizerDelegate, SettingsViewControllerDelegate, PlacesViewControllerDelegate>

@property (nonatomic, strong) CenterViewController *centerViewController;
@property (nonatomic, strong) LeftPanelViewController *leftPanelViewController;
@property (nonatomic, strong) DecisionViewController *decisionViewController;
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) PlacesViewController *placesViewController;
@property (nonatomic, strong) RightPanelViewController *rightPanelViewController;
@property (nonatomic, strong) FriendsListViewController *friendsListViewController;
@property (nonatomic, strong) FriendInviteViewController *inviteViewController;
@property (nonatomic, assign) BOOL showingRightPanel;
@property (nonatomic, assign) BOOL showingLeftPanel;
@property (nonatomic, assign) BOOL showingDecisionView;
@property (nonatomic, assign) BOOL showPanel;
@property (nonatomic, assign) BOOL leftPanelNotShownYet;
@property (nonatomic, assign) BOOL rightPanelNotShownYet;
@property (nonatomic, assign) BOOL canUpdatePlaces;
@property (nonatomic, assign) BOOL shouldSortFriendsList;
@property (nonatomic, assign) BOOL parseError;
@property (nonatomic, strong) NSString *facebookId;
@property (nonatomic, assign) CGPoint preVelocity;
@property (nonatomic, assign) NSTimer *pollingTimer;
@property (nonatomic, assign) int timerMultiplier;
@property (nonatomic, strong) PFUser *currentUser;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.leftPanelNotShownYet = YES;
        self.rightPanelNotShownYet = YES;
        self.canUpdatePlaces = YES;
        self.placesViewController = [[PlacesViewController alloc] init];
        self.placesViewController.delegate = self;
        self.timerMultiplier = 1;
        self.showingDecisionView = NO;
        self.parseError = NO;
        
        Datastore *sharedDataManager= [Datastore sharedDataManager];
        sharedDataManager.tetherFriendsDictionary = [[NSMutableDictionary alloc] init];
        sharedDataManager.tetherFriendsNearbyDictionary = [[NSMutableDictionary alloc] init];
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
    
    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:POLLING_INTERVAL
                                     target:self
                                   selector:@selector(timerFired)
                                   userInfo:nil
                                    repeats:YES];
    [self refreshNotificationsNumber];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (FBSession.activeSession.isOpen) {
        [self populateUserDetails];
    }
}

-(void)pollDatabase {
    if (self.parseError || self.centerViewController.userCoordinates.coordinate.longitude == 0.0) {
        // check if parse timed out?
        [self setupView];
    }
    [self queryFriendsStatus];
    [self.pollingTimer invalidate];
    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:POLLING_INTERVAL
                                                           target:self
                                                         selector:@selector(timerFired)
                                                         userInfo:nil
                                                        repeats:YES];
}

-(void)timerFired{
    if (self.canUpdatePlaces) {
        [self pollDatabase];
        if ([self shouldShowDecisionView] && !self.showingDecisionView) {
            [self setupView];
        }
    }
}

-(void)loadNotifications {
    [self.rightPanelViewController loadNotifications];
}

-(void)refreshNotificationsNumber {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    sharedDataManager.notifications = currentInstallation.badge;
    [self.centerViewController refreshNotificationsNumber];
    NSLog(@"%ld", (long)currentInstallation.badge);
    NSLog(@"%@", currentInstallation.installationId);
}

-(void)updateNotificationsNumber {
    [self.centerViewController refreshNotificationsNumber];
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
    NSMutableArray *facebookFriendsIds = [[NSMutableArray alloc] init];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    if ([friends count] > [sharedDataManager.facebookFriends count]) {
        for (NSDictionary *friendData in friends) {
            [facebookFriendsIds addObject:friendData[@"id"]];
        }
    }
    
    sharedDataManager.facebookFriends = facebookFriendsIds;
    
    [self.currentUser setObject:sharedDataManager.facebookFriends forKey:@"facebookFriends"];
    
    [self.currentUser saveEventually];
    
    NSLog(@"PARSE SAVE: saving your facebook friends");

    [self queryFriendsStatus];
}

-(void)facebookRequestDidLoad:(id)result {
    self.currentUser = [PFUser currentUser];
    
    NSArray *data = [result objectForKey:@"data"];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    if (data) {
        sharedDataManager.facebookFriends = [[NSMutableArray alloc] initWithCapacity:[data count]];
        [self populateFacebookFriends:data];

    } else {
        if (self.currentUser) {
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            
            NSString *facebookName = result[@"name"];
            if (facebookName && [facebookName length] != 0) {
                [self.currentUser setObject:facebookName forKey:@"displayName"];
                sharedDataManager.name = facebookName;
            } else {
                [self.currentUser setObject:@"Someone" forKey:@"displayName"];
            }
            
            NSString *firstName = result[@"first_name"];
            if (firstName && [firstName length] != 0) {
                [self.currentUser setObject:firstName forKey:@"firstName"];
            }
            
            NSDate *birthday = result[@"birthday"];
            if (birthday) {
                [self.currentUser setObject:birthday forKey:@"birthday"];
            }
            
            NSString *facebookId = result[@"id"];
            if (facebookId && [facebookId length] != 0) {
                [self.currentUser setObject:facebookId forKey:kUserFacebookIDKey];
                sharedDataManager.facebookId = facebookId;
                [self.decisionViewController addProfileImageView];
                self.facebookId = facebookId;
                self.centerViewController.userProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)sharedDataManager.facebookId pictureCropping:FBProfilePictureCroppingSquare];
                self.centerViewController.userProfilePictureView.layer.cornerRadius = 12.0;
                self.centerViewController.userProfilePictureView.clipsToBounds = YES;
                [self.centerViewController.userProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
               self.centerViewController.userProfilePictureView.frame = CGRectMake(7.0, 7.0, 25.0, 25.0);
                [self.centerViewController.bottomBar addSubview:self.centerViewController.userProfilePictureView];
                [self.centerViewController.bottomBar addSubview:self.centerViewController.settingsButtonLarge];
            }
            
            NSString *gender = result[@"gender"];
            if (gender && [gender length] != 0) {
                [self.currentUser setObject:gender forKey:kUserGenderKey];
            }
            
            NSString *relationshipStatus = result[@"relationship_status"];
            if (relationshipStatus && [relationshipStatus length] != 0) {
                [self.currentUser setObject:relationshipStatus forKey:@"relationshipStatus"];
            }
            
            NSLog(@"PARSE SAVE: setting your user facebook details");
            [self.currentUser saveEventually];
            
            if ([self.currentUser objectForKey:kUserStatusMessageKey]) {
                sharedDataManager.statusMessage = [self.currentUser objectForKey:kUserStatusMessageKey];
            }
        }
        
        [FBRequestConnection startForMyFriendsWithCompletionHandler:^(FBRequestConnection *connection, id friends, NSError *error) {
            if (!error) {
                [self facebookRequestDidLoad:friends];
            } else {
                [self facebookRequestDidFailWithError:error];
            }
        }];
    }
}

- (void)facebookRequestDidFailWithError:(NSError *)error {
    NSLog(@"Facebook error: %@", error);
    
    if ([PFUser currentUser]) {
        if ([[error userInfo][@"error"][@"type"] isEqualToString:@"OAuthException"]) {
            NSLog(@"The Facebook token was invalidated. Logging out.");
            
        }
    }
}

-(void)queryFriendsStatus{
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSString *city = [userDetails objectForKey:kUserDefaultsCityKey];
    NSString *state = [userDetails objectForKey:kUserDefaultsStateKey];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSLog(@"Your city: %@ state: %@", city, state);
    
    if (city && state && sharedDataManager.facebookFriends) {
        PFQuery *facebookFriendsQuery = [PFUser query];
        [facebookFriendsQuery whereKey:kUserFacebookIDKey containedIn:sharedDataManager.facebookFriends];

        [facebookFriendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                self.parseError = NO;
                NSLog(@"QUERY: queried your facebook friends status who are on Tether");
                sharedDataManager.tetherFriendsNearbyDictionary = [[NSMutableDictionary alloc] init];
                
                for (PFUser *user in objects) {
                    Friend *friend;
                    if ([sharedDataManager.tetherFriendsDictionary objectForKey:user[kUserFacebookIDKey]]) {
                        friend = [sharedDataManager.tetherFriendsDictionary objectForKey:user[kUserFacebookIDKey]];
                    } else {
                        friend = [[Friend alloc] init];
                        friend.friendID = user[kUserFacebookIDKey];
                        friend.name = user[kUserDisplayNameKey];
                        friend.friendsArray = user[kUserFacebookFriendsKey];
                    }
                    friend.timeLastUpdated = user[kUserTimeLastUpdatedKey];
                    friend.status = [user[kUserStatusKey] boolValue];
                    friend.statusMessage = user[kUserStatusMessageKey];
                    friend.placeId = @"";
                    
                    if ([sharedDataManager.friendsToPlacesMap objectForKey:friend.friendID]) {
                        friend.placeId = [sharedDataManager.friendsToPlacesMap objectForKey:friend.friendID];
                    }
                    
                    if ([user[kUserCityKey] isEqualToString:city] && [user[kUserStateKey] isEqualToString:state]) {
                        [sharedDataManager.tetherFriendsNearbyDictionary setObject:friend forKey:friend.friendID];
                    }
                    [sharedDataManager.tetherFriendsDictionary setObject:friend forKey:friend.friendID];
                }
                
                [self sortTetherFriends];
                
                if (self.canUpdatePlaces) {
                    [self.placesViewController getFriendsCommitments];
                    if (sharedDataManager.currentCommitmentPlace) {
                        [self.placesViewController scrollToPlaceWithId:sharedDataManager.currentCommitmentPlace.placeId];
                    }
                }
                
                if ([self.rightPanelViewController.notificationsArray count] == 0) {
                    [self loadNotifications];
                }
            } else {
                // The network was inaccessible and we have no cached data for r
                // this query.
                NSLog(@"Query error");
                self.parseError = YES;
            }
        }];
    }
}

-(void)sortTetherFriends {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSDate *startTime = [self getStartTime];
    NSMutableSet *tempFriendsGoingOutSet = [[NSMutableSet alloc] init];
    NSMutableSet *tempFriendsNotGoingOutSet = [[NSMutableSet alloc] init];
    NSMutableSet *tempFriendsUndecidedSet = [[NSMutableSet alloc] init];
    
    for (id key in sharedDataManager.tetherFriendsNearbyDictionary) {
        Friend *friend = [sharedDataManager.tetherFriendsNearbyDictionary objectForKey:key];
        if (friend) {
            if ([startTime compare:friend.timeLastUpdated] == NSOrderedDescending || !friend.status) {
                [tempFriendsUndecidedSet addObject:friend];
            } else {
                if (friend) {
                    if (friend.placeId && ![friend.placeId isEqualToString:@""]) {
                        [tempFriendsGoingOutSet addObject:friend];
                    } else {
                        [tempFriendsNotGoingOutSet addObject:friend];
                    }
                }
            }
        }
    }
    
    // only update lists if they have changed
    BOOL listsHaveChanged = NO;
    
    if (![tempFriendsUndecidedSet isEqualToSet:[NSSet setWithArray:sharedDataManager.tetherFriendsUndecided]]) {
        sharedDataManager.tetherFriendsUndecided = [[tempFriendsUndecidedSet allObjects] mutableCopy];
        listsHaveChanged = YES;
    }

    if (![tempFriendsGoingOutSet isEqualToSet:[NSSet setWithArray:sharedDataManager.tetherFriendsGoingOut]]) {
        sharedDataManager.tetherFriendsGoingOut = [[tempFriendsGoingOutSet allObjects] mutableCopy];
        listsHaveChanged = YES;
    } else {
        NSSet *friendsCommittments = [[NSSet setWithArray:sharedDataManager.tetherFriendsGoingOut] valueForKey:@"placeId"];
        NSSet *tempFriendsCommittments = [tempFriendsGoingOutSet valueForKey:@"placeId"];
        if (![friendsCommittments isEqualToSet:tempFriendsCommittments]) {
            sharedDataManager.tetherFriendsGoingOut = [[tempFriendsGoingOutSet allObjects] mutableCopy];
            listsHaveChanged = YES;
        }
    }
    
    if (![tempFriendsNotGoingOutSet isEqualToSet:[NSSet setWithArray:sharedDataManager.tetherFriendsNotGoingOut]]) {
        sharedDataManager.tetherFriendsNotGoingOut = [[tempFriendsNotGoingOutSet allObjects] mutableCopy];
        listsHaveChanged = YES;
    }
    
    [self.centerViewController.numberButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)([sharedDataManager.tetherFriendsGoingOut count] + [sharedDataManager.tetherFriendsNotGoingOut count])] forState:UIControlStateNormal];
    [self.centerViewController layoutNumberButton];
    // if lists have changed or all are empty, update view
    if (listsHaveChanged ||
        ([sharedDataManager.tetherFriendsUndecided count] == 0 &&
         [sharedDataManager.tetherFriendsNotGoingOut count] == 0 &&
         [sharedDataManager.tetherFriendsGoingOut count] == 0)) {
        [self.leftPanelViewController updateFriendsList];
    }
    [self refreshCommitmentName];
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

#pragma mark -
#pragma mark Setup View

- (void)setupView
{
    if (self.centerViewController) {
        [self.centerViewController.view removeFromSuperview];
        [self.centerViewController removeFromParentViewController];
    }
    
    // setup center view
    self.centerViewController = [[CenterViewController alloc] init];
    self.centerViewController.view.tag = CENTER_TAG;
    self.centerViewController.delegate = self;
    self.centerViewController.placeToAnnotationDictionary = [[NSMutableDictionary alloc] init];
    self.centerViewController.placeToAnnotationViewDictionary = [[NSMutableDictionary alloc] init];
    
    [self.view addSubview:self.centerViewController.view];
    [self addChildViewController:_centerViewController];
    [_centerViewController didMoveToParentViewController:self];
    
    [self setupGestures];
    
    // define the view for the left panel view controller
    self.leftPanelViewController = [[LeftPanelViewController alloc] init];
    self.leftPanelViewController.view.tag = LEFT_PANEL_TAG;
    self.leftPanelViewController.delegate = self;
    
    // define the view for the left panel view controller
    self.rightPanelViewController = [[RightPanelViewController alloc] init];
    self.rightPanelViewController.view.tag = RIGHT_PANEL_TAG;
    
    // check if user has input status today
    [self showDecisionView];
}

-(BOOL)shouldShowDecisionView {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSDate *timeLastUpdated = [userDetails objectForKey:@"timeLastUpdated"];
    NSDate *beginningTime = [self getStartTime];
    if (timeLastUpdated == nil || [beginningTime compare:timeLastUpdated] == NSOrderedDescending) {
        return YES;
    }
    return NO;
}

-(void)showDecisionView {
    // check if user has input status today
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if (!self.showingDecisionView && ([self shouldShowDecisionView] || ![userDetails boolForKey:kUserDefaultsStatusKey])) {
        self.decisionViewController = [[DecisionViewController alloc] init];
        self.decisionViewController.delegate = self;
        [self.decisionViewController addProfileImageView];
        [self.view addSubview:self.decisionViewController.view];
        [self addChildViewController:_decisionViewController];
        [_decisionViewController didMoveToParentViewController:self];
        self.showingDecisionView = YES;
    }
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
    if (_leftPanelViewController != nil) {
        _centerViewController.triangleButton.tag = 1;
        _centerViewController.numberButton.tag = 1;
        _centerViewController.leftPanelButtonLarge.tag = 1;
        self.showingLeftPanel = NO;
    }
    
    if (_rightPanelViewController != nil) {
        _centerViewController.notificationsButton.tag = 1;
        _centerViewController.notificationsButtonLarge.tag = 1;
        _centerViewController.listViewButton.userInteractionEnabled = YES;
        _centerViewController.listViewButtonLarge.userInteractionEnabled = YES;
        self.showingRightPanel = NO;
    }
    
     _centerViewController.mv.userInteractionEnabled = YES;
    [self.leftPanelViewController.view removeFromSuperview];
    [self.rightPanelViewController.view removeFromSuperview];
    
    // remove view shadows
    [self showCenterViewWithShadow:NO withOffset:0];
}

- (UIView *)getLeftView
{
    // init view if it doesn't already exist
    if (self.leftPanelNotShownYet == YES)
    {
        self.leftPanelNotShownYet = NO;
        
        [self addChildViewController:_leftPanelViewController];
        [_leftPanelViewController didMoveToParentViewController:self];
        
        _leftPanelViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }
    
    [self.view addSubview:self.leftPanelViewController.view];
    
    self.showingLeftPanel = YES;
    
    // set up view shadows
    [self showCenterViewWithShadow:YES withOffset:-2];
    
    UIView *view = self.leftPanelViewController.view;
    return view;
}

- (UIView *)getRightView
{
    // init view if it doesn't already exist
    if (self.rightPanelNotShownYet == YES)
    {
        self.rightPanelNotShownYet = NO;
        
        [self addChildViewController:_rightPanelViewController];
        [_rightPanelViewController didMoveToParentViewController:self];
        
        _rightPanelViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }
    
    [self.view addSubview:self.rightPanelViewController.view];
    
    self.showingRightPanel = YES;
    
    // set up view shadows
    [self showCenterViewWithShadow:YES withOffset:2];
    
    UIView *view = self.rightPanelViewController.view;
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
            if (!_showingRightPanel) {
                childView = [self getLeftView];
            }
        } else{
            if (!_showingLeftPanel) {
                childView = [self getRightView];
            }
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
            } else if(_showingRightPanel) {
                [self movePanelLeft];
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
        float xCoord = 0.0;
        if (_showingLeftPanel) {
            xCoord = MAX(160.0,[sender view].center.x + translatedPoint.x);
        } else if (_showingRightPanel) {
            xCoord = MIN(160.0,[sender view].center.x + translatedPoint.x);
        }

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
    [self.settingsViewController.view setFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)]; //notice this is OFF screen!
    [self.view addSubview:self.settingsViewController.view];
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:5.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                            [self.settingsViewController.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showListView
{
    if (!self.placesViewController) {
        self.placesViewController = [[PlacesViewController alloc] init];
        self.placesViewController.delegate = self;
    } 

    [self.placesViewController didMoveToParentViewController:self];
    [self.placesViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.placesViewController.view];
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:5.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                        [self.placesViewController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self resetMainView];
                         [self canUpdatePlaces:NO];
                     }];
}

- (void)movePanelRight // to show left panel
{
    UIView *childView = [self getLeftView];
    [self.view sendSubviewToBack:childView];
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:5.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _centerViewController.view.frame = CGRectMake(self.view.frame.size.width - PANEL_WIDTH, 0, self.view.frame.size.width, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         _centerViewController.numberButton.tag = 0;
                          _centerViewController.triangleButton.tag = 0;
                          _centerViewController.leftPanelButtonLarge.tag = 0;
                         _centerViewController.mv.userInteractionEnabled = NO;
                         UITapGestureRecognizer *mapTapGesture =
                         [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePanel:)];
                         [self.centerViewController.view addGestureRecognizer:mapTapGesture];
                     }];
}

- (void)movePanelLeft // to show left panel
{
    UIView *childView = [self getRightView];
    [self.view sendSubviewToBack:childView];
    self.centerViewController.listViewButton.userInteractionEnabled = NO;
    self.centerViewController.listViewButtonLarge.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:0.7
          initialSpringVelocity:5.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _centerViewController.view.frame = CGRectMake(-self.view.frame.size.width + PANEL_WIDTH, 0, self.view.frame.size.width, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         _centerViewController.notificationsButton.tag = 0;
                         _centerViewController.notificationsButtonLarge.tag = 0;
                         _centerViewController.mv.userInteractionEnabled = NO;
                         UITapGestureRecognizer *mapTapGesture =
                         [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePanel:)];
                         [self.centerViewController.view addGestureRecognizer:mapTapGesture];
                     }];
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (currentInstallation.badge != 0 || sharedDataManager.notifications != 0) {
        [self loadNotifications];
    }
    currentInstallation.badge = 0;
    [currentInstallation saveEventually];
    sharedDataManager.notifications = 0;
    [self updateNotificationsNumber];
}

- (void)movePanelToOriginalPosition
{
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:5.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _centerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         [self resetMainView];
                     }];
}

- (void)closePanel:(UIGestureRecognizer*)recognizer {
    [recognizer.view removeGestureRecognizer:recognizer];
    [self movePanelToOriginalPosition];
}

-(void)finishedResettingNewLocation {
    if (self.canUpdatePlaces) {
        self.placesViewController = [[PlacesViewController alloc] init];
        self.placesViewController.delegate = self;
        [self pollDatabase];
    }
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [self.settingsViewController resettingNewLocationHasFinished];
    [self saveCity:[userDetails objectForKey:@"city"] state:[userDetails objectForKey:@"state"]];
    [self refreshCommitmentName];
    NSLog(@"FINISHED RESETTING, NOW POLLING DATABASE");
}

-(void)saveCity:(NSString*)city state:(NSString*)state {
    [self.currentUser setObject:city forKey:kUserCityKey];
    [self.currentUser setObject:state forKey:kUserStateKey];
    [self.currentUser saveInBackground];
    NSLog(@"PARSE SAVE: saving your location %@ %@",city, state);
}

-(void)openPageForPlaceWithId:(id)placeId {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if ([sharedDataManager.placesDictionary objectForKey:placeId]) {
        Place *place;
        place = [sharedDataManager.placesDictionary objectForKey:placeId];
        if ([place.friendsCommitted count] > 0) {
            if (place.numberCommitments == 1 && [place.friendsCommitted containsObject:sharedDataManager.facebookId]) {
                [self goToPlaceInListView:placeId];
            } else {
                self.friendsListViewController = [[FriendsListViewController alloc] init];
                self.friendsListViewController.delegate = self;
                NSMutableSet *friends = [[NSMutableSet alloc] init];
                for (id friendId in place.friendsCommitted) {
                    if ([sharedDataManager.tetherFriendsDictionary objectForKey:friendId]) {
                        Friend *friend = [sharedDataManager.tetherFriendsDictionary objectForKey:friendId];
                        [friends addObject:friend];
                    }
                }
                self.friendsListViewController.friendsArray = [[friends allObjects] mutableCopy];
                self.friendsListViewController.place = place;
                [self.friendsListViewController loadFriendsOfFriends];
                [self.friendsListViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                [self.view addSubview:self.friendsListViewController.view];
                [self addChildViewController:self.friendsListViewController];
                [self.friendsListViewController didMoveToParentViewController:self.centerViewController];
                
                [UIView animateWithDuration:0.5
                                      delay:0.0
                     usingSpringWithDamping:1.0
                      initialSpringVelocity:5.0
                                    options:UIViewAnimationOptionBeginFromCurrentState
                                 animations:^{
                                     [self.friendsListViewController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                                 }
                                 completion:^(BOOL finished) {
                                 }];
            }
        }
    }
}

#pragma mark QuestionViewControllerDelegate

-(void)handleChoice:(BOOL)choice {
    
    [UIView animateWithDuration:1.0
        animations:^{
            self.decisionViewController.view.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.decisionViewController.view removeFromSuperview];
            [self.decisionViewController removeFromParentViewController];
            self.decisionViewController = nil;
            self.showingDecisionView = NO;
            self.decisionViewController.view.alpha = 1.0;
        }];

    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [userDetails setBool:choice forKey:kUserDefaultsStatusKey];
    [userDetails setObject:[NSDate date] forKey:kUserDefaultsTimeLastUpdatedKey];
    
    NSLog(@"PARSE SAVE: Saving your going out choice");
    PFUser *user = [PFUser currentUser];
    [user setObject:[NSNumber numberWithBool:choice] forKey:kUserStatusKey];
    [user setObject:[NSDate date] forKey:kUserTimeLastUpdatedKey];
    [user saveInBackground];
    
    [self.centerViewController updateLocation];
}

#pragma mark SettingsViewControllerDelegate

-(void)closeSettings {
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:5.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                            [self.settingsViewController.view setFrame:CGRectMake( 0.0f, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.settingsViewController.view removeFromSuperview];
                         [self.settingsViewController removeFromParentViewController];
                     }];
}

-(void)userChangedLocationInSettings:(CLLocation*)newLocation{
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentPlace) {
        [self.placesViewController removeCommitmentFromDatabase];
        [self removePlaceMarkFromMapView:sharedDataManager.currentCommitmentPlace];
        sharedDataManager.currentCommitmentPlace = nil;
    }
    self.centerViewController.resettingLocation = YES;
    [self.centerViewController setCityFromCLLocation:newLocation];
}

-(void)userChangedSettingsToUseCurrentLocation {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentPlace) {
        [self.placesViewController removeCommitmentFromDatabase];
        [self removePlaceMarkFromMapView:sharedDataManager.currentCommitmentPlace];
        sharedDataManager.currentCommitmentPlace = nil;
    }
    self.centerViewController.resettingLocation = YES;
    [self.centerViewController locationSetup];
}

#pragma mark LeftPanelViewControllerDelegate
-(void)goToPlaceInListView:(id)placeId {
    [self movePanelToOriginalPosition];
    [self showListView];
    [self.placesViewController.placesTableView reloadData];
    [self.placesViewController scrollToPlaceWithId:placeId];
}

-(void)inviteFriend:(Friend *)friend {
    self.inviteViewController = [[FriendInviteViewController alloc] init];
    self.inviteViewController.delegate = self;
    [self.inviteViewController.view setBackgroundColor:[UIColor blackColor]];
    [self.inviteViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.inviteViewController addFriend:friend];
    [self.view addSubview:self.inviteViewController.view];
    [self addChildViewController:self.inviteViewController];
    [self.inviteViewController didMoveToParentViewController:self];
    
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:5.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.inviteViewController.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

#pragma mark FriendInviteViewControllerDelegate methods

-(void)closeInviteView {
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:5.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.inviteViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [self.inviteViewController.view removeFromSuperview];
                             [self.inviteViewController removeFromParentViewController];
                         }];
}

#pragma mark PlacesViewControllerDelegate

-(void)placeMarkOnMapView:(Place*)place {
    TetherAnnotation *annotation = [[TetherAnnotation alloc] init];
    [annotation setCoordinate:place.coord];
    [annotation setTitle:[NSString stringWithFormat:@"%@", place.name]];
    if (place.address && ![place.address isEqualToString:@""]) {
        [annotation setSubtitle:[NSString stringWithFormat:@"%@", place.address]];
    }
    annotation.place = place;
    
    if ([self.centerViewController.placeToAnnotationDictionary objectForKey:place.placeId]) {
        TetherAnnotation *previousAnnotation = [self.centerViewController.placeToAnnotationDictionary objectForKey:place.placeId];
        if ([place.friendsCommitted isEqualToSet:previousAnnotation.place.friendsCommitted]) {
            return;
        }
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
        if ([self.centerViewController.placeToAnnotationDictionary objectForKey:place.placeId]) {
            [self.centerViewController.placeToAnnotationDictionary removeObjectForKey:place.placeId];
            [self.centerViewController.placeToAnnotationViewDictionary removeObjectForKey:place.placeId];
        }
        
        if ([self.centerViewController.annotationsArray containsObject:annotation]) {
            [self.centerViewController.annotationsArray removeObject:annotation];
        }
        NSLog(@"MAIN VIEW: Removed annotation for %@", place.name);
    }
}

-(void)closeListView {
    [UIView animateWithDuration:0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:5.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                        [self.placesViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.placesViewController.view removeFromSuperview];
                         [self.placesViewController removeFromParentViewController];
                         [self canUpdatePlaces:YES];
                         [self.placesViewController sortPlacesByPopularity];
                     }];
}

-(void)setPlace:(id)placeId forFriend:(id)friendId {
    if (placeId) {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        Friend *currentFriend = [sharedDataManager.tetherFriendsNearbyDictionary objectForKey:friendId];
        currentFriend.placeId = placeId;
        if (currentFriend && ![[sharedDataManager.friendsToPlacesMap objectForKey:friendId] isEqualToString:placeId]) {
            [sharedDataManager.friendsToPlacesMap setObject:placeId forKey:friendId];
            [sharedDataManager.tetherFriendsNearbyDictionary setObject:currentFriend forKey:friendId];
            self.shouldSortFriendsList = YES;
        }
    }
}

-(void)commitToPlace:(Place *)place {
    PFQuery *query = [PFQuery queryWithClassName:kCommitmentClassKey];
    [query whereKey:kUserFacebookIDKey equalTo:self.facebookId];
    
    [query whereKey:kCommitmentDateKey greaterThan:[self getStartTime]];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFObject *commitment;
            if ([objects count] > 0) {
                commitment = [objects objectAtIndex:0];
            } else {
                commitment = [PFObject objectWithClassName:kCommitmentClassKey];
                [commitment setObject:self.facebookId forKey:kUserFacebookIDKey];
            }
            
            if (place.placeId) {
                [commitment setObject:place.placeId forKey:kCommitmentPlaceIDKey];
            }

            [commitment setObject:[NSDate date] forKey:kCommitmentDateKey];
            
            if (place.coord.latitude && place.coord.longitude) {
                [commitment setObject:[PFGeoPoint geoPointWithLatitude:place.coord.latitude
                                                             longitude:place.coord.longitude] forKey:kCommitmentGeoPointKey];
            }

            if (place.name) {
                [commitment setObject:place.name forKey:kCommitmentPlaceKey];
            }

            if (place.city) {
                [commitment setObject:place.city forKey:kCommitmentCityKey];
            }
            
            if (place.state) {
                [commitment setObject:place.state forKey:kCommitmentStateKey];
            }

            if (place.address) {
                [commitment setObject:place.address forKey:kCommitmentAddressKey];
            }

            [commitment saveInBackground];
            NSLog(@"PARSE SAVE: saving your commitment");
            
            NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
            BOOL status = [userDetails boolForKey:kUserDefaultsStatusKey];
            if (!status) {
                [userDetails setBool:YES forKey:kUserDefaultsStatusKey];
                [userDetails synchronize];
                
                PFUser *user = [PFUser currentUser];
                [user setObject:[NSNumber numberWithBool:YES] forKey:kUserStatusKey];
                [user setObject:[NSDate date] forKey:kUserTimeLastUpdatedKey];
                [user saveInBackground];
                
                self.settingsViewController.goingOutSwitch.on = YES;
            }
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            sharedDataManager.currentCommitmentParseObject = commitment;
            
            [self placeMarkOnMapView:place];
            [self pollDatabase];
            
            [self notifyFriendsForCommitmentToPlace:place];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

-(void)notifyFriendsForCommitmentToPlace:(Place *)place {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSMutableArray *recipents = [[NSMutableArray alloc] init];
    for (Notification *notification in sharedDataManager.todaysNotificationsArray) {
        if ([notification.placeId isEqualToString:place.placeId] || [notification.placeName isEqualToString:place.name]) {
            [recipents addObject:notification.sender];
        }
    }
    
    for (Friend *friend in recipents) {
        PFQuery *friendQuery = [PFUser query];
        [friendQuery whereKey:@"facebookId" equalTo:friend.friendID];

       [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                // Create our Installation query
                PFUser * user = [objects objectAtIndex:0];
                PFQuery *pushQuery = [PFInstallation query];
                [pushQuery whereKey:@"owner" equalTo:user]; //change this to use friends installation
                NSString *messageHeader = [NSString stringWithFormat:@"%@ tethrd to %@", sharedDataManager.name, place.name];
                NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                      messageHeader, @"alert",
                                      @"Increment", @"badge",
                                      nil];
                
                // Send push notification to query
                PFPush *push = [[PFPush alloc] init];
                [push setQuery:pushQuery]; // Set our Installation query
                [push setData:data];
                [push sendPushInBackground];
                
                PFObject *invitation = [PFObject objectWithClassName:kNotificationClassKey];
                [invitation setObject:friend.friendID forKey:kNotificationSenderKey];
                [invitation setObject:place.name forKey:kNotificationPlaceNameKey];
                [invitation setObject:place.placeId forKey:kNotificationPlaceIdKey];
                [invitation setObject:messageHeader forKey:kNotificationMessageHeaderKey];
                [invitation setObject:sharedDataManager.facebookId forKey:kNotificationRecipientKey];
                [invitation setObject:@"acceptance" forKey:kNotificationTypeKey];
                [invitation saveInBackground];
           }
        }];
    }
}

-(void)removePreviousCommitment {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentPlace) {
        NSLog(@"Removing previous commitment to %@", sharedDataManager.currentCommitmentPlace.name);
        if ([sharedDataManager.currentCommitmentPlace.friendsCommitted containsObject:sharedDataManager.facebookId]) {
            [sharedDataManager.currentCommitmentPlace.friendsCommitted removeObject:sharedDataManager.facebookId];
            sharedDataManager.currentCommitmentPlace.numberCommitments =  [sharedDataManager.currentCommitmentPlace.friendsCommitted count];
            [sharedDataManager.placesDictionary setObject:sharedDataManager.currentCommitmentPlace
                                                   forKey:sharedDataManager.currentCommitmentPlace.placeId];
            [sharedDataManager.popularPlacesDictionary setObject:sharedDataManager.currentCommitmentPlace
                                                          forKey:sharedDataManager.currentCommitmentPlace.placeId];
            [self removePlaceMarkFromMapView:sharedDataManager.currentCommitmentPlace];
        }
        sharedDataManager.currentCommitmentPlace = nil;
    }
    [self pollDatabase];
}

-(void)removeCommitmentFromDatabase {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentParseObject) {
        [sharedDataManager.currentCommitmentParseObject deleteInBackground];
        NSLog(@"PARSE DELETE: Removed previous commitment from database");
        sharedDataManager.currentCommitmentParseObject = nil;
    }
}

-(void)sortFriendsList {
    if (self.shouldSortFriendsList) {
        [self sortTetherFriends];
        self.shouldSortFriendsList = NO;
    }
}

-(void)canUpdatePlaces:(BOOL)canUpdate {
    self.canUpdatePlaces = canUpdate;
}

-(void)refreshCommitmentName {
    [self.centerViewController layoutCurrentCommitment];
}

#pragma mark FriendsListViewControllerDelegate

-(void)closeFriendsView {
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:5.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.friendsListViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [self.friendsListViewController.view removeFromSuperview];
                             [self.friendsListViewController removeFromParentViewController];
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
