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
#import "FriendsListViewController.h"
#import "InviteViewController.h"
#import "LeftPanelViewController.h"
#import "Datastore.h"
#import "MainViewController.h"
#import "Notification.h"
#import "Place.h"
#import "PlacesViewController.h"
#import "RightPanelViewController.h"
#import "SettingsViewController.h"
#import "TetherAnnotation.h"
#import "TetherAnnotationView.h"
#import "TetherCache.h"

#import <FacebookSDK/FacebookSDK.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

#define CENTER_TAG 1
#define LEFT_PANEL_TAG 2
#define RIGHT_PANEL_TAG 3
#define CORNER_RADIUS 4.0
#define SLIDE_TIMING 0.6
#define SPINNER_SIZE 30.0
#define PANEL_WIDTH 45.0
#define POLLING_INTERVAL 20

@interface MainViewController () <CenterViewControllerDelegate, DecisionViewControllerDelegate, FriendsListViewControllerDelegate, InviteViewControllerDelegate, LeftPanelViewControllerDelegate, PlacesViewControllerDelegate, RightPanelViewControllerDelegate, SettingsViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) CenterViewController *centerViewController;
@property (nonatomic, strong) LeftPanelViewController *leftPanelViewController;
@property (nonatomic, strong) DecisionViewController *decisionViewController;
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) PlacesViewController *placesViewController;
@property (nonatomic, strong) RightPanelViewController *rightPanelViewController;
@property (nonatomic, strong) FriendsListViewController *friendsListViewController;
@property (nonatomic, strong) InviteViewController *inviteViewController;
@property (nonatomic, assign) BOOL showingRightPanel;
@property (nonatomic, assign) BOOL showingLeftPanel;
@property (nonatomic, assign) BOOL showingDecisionView;
@property (nonatomic, assign) BOOL showPanel;
@property (nonatomic, assign) BOOL leftPanelNotShownYet;
@property (nonatomic, assign) BOOL rightPanelNotShownYet;
@property (nonatomic, assign) BOOL canUpdatePlaces;
@property (nonatomic, assign) BOOL shouldSortFriendsList;
@property (nonatomic, assign) BOOL parseError;
@property (nonatomic, assign) BOOL committingToPlace;
@property (nonatomic, assign) BOOL savingCommitment;
@property (nonatomic, strong) NSString *facebookId;
@property (nonatomic, assign) CGPoint preVelocity;
@property (nonatomic, assign) NSTimer *pollingTimer;
@property (nonatomic, assign) int timerMultiplier;
@property (nonatomic, strong) PFUser *currentUser;
@property (nonatomic, strong) NSMutableDictionary *previousTetherFriendsDictionary;
@property (nonatomic, assign) BOOL listsHaveChanged;
@property (retain, nonatomic) UIView *confirmationView;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, assign) BOOL openingPlacePage;

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
    [self setNeedsStatusBarAppearanceUpdate];
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

// handle in phone call layout
-(void)setNeedsStatusBarAppearanceUpdate {
    [super setNeedsStatusBarAppearanceUpdate];
    
    if (self.settingsViewController) {
        if ([UIApplication sharedApplication].statusBarFrame.size.height == 40.0) {
            self.settingsViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 20.0);
        } else {
            self.settingsViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 20.0);
        }

        [self.settingsViewController.view setNeedsDisplay];
    }
    
    if (self.centerViewController) {
        if ([UIApplication sharedApplication].statusBarFrame.size.height == 40.0) {
            self.centerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 20.0);
        } else {
            self.centerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 20.0);
        }
        [self.centerViewController setNeedsStatusBarAppearanceUpdate];
        [self.centerViewController.view setNeedsDisplay];
        [self.centerViewController.view setNeedsLayout];
    }
    
    if (self.leftPanelViewController) {
        if ([UIApplication sharedApplication].statusBarFrame.size.height == 40.0) {
            self.leftPanelViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 20.0);
        } else {
            self.leftPanelViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 20.0);
        }
        [self.leftPanelViewController.view setNeedsDisplay];
        [self.leftPanelViewController.view setNeedsLayout];
    }
    
    if (self.rightPanelViewController) {
        if ([UIApplication sharedApplication].statusBarFrame.size.height == 40.0) {
            self.rightPanelViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 20.0);
        } else {
            self.rightPanelViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + 20.0);
        }
        [self.rightPanelViewController.view setNeedsDisplay];
        [self.rightPanelViewController.view setNeedsLayout];
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
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
    NSLog(@"POLLING DATABASE");
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.facebookFriends) {
        [self queryFriendsStatus];
    } else {
        [self populateUserDetails];
    }
    [self.pollingTimer invalidate];
    self.pollingTimer = [NSTimer scheduledTimerWithTimeInterval:POLLING_INTERVAL
                                                           target:self
                                                         selector:@selector(timerFired)
                                                         userInfo:nil
                                                        repeats:YES];
}

-(void)timerFired{
    if (self.canUpdatePlaces && !self.savingCommitment) {
        if ([self shouldShowDecisionView] && !self.showingDecisionView) {
            [self setupView];
        }
        [self pollDatabase];
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

-(void)confirmTetheringToPlace:(Place*)place {
    self.confirmationView = [[UIView alloc] init];
    [self.confirmationView setBackgroundColor:[UIColor whiteColor]];
    self.confirmationView.alpha = 0.8;
    self.confirmationView.layer.cornerRadius = 10.0;
    
    UILabel *confirmationLabel = [[UILabel alloc] init];
    confirmationLabel.text = [NSString stringWithFormat:@"Tethring to %@", place.name];
    confirmationLabel.textColor = UIColorFromRGB(0x8e0528);
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    confirmationLabel.font = montserrat;
    CGSize size = [confirmationLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.confirmationView.frame = CGRectMake((self.view.frame.size.width - MAX(200.0,size.width)) / 2.0, (self.view.frame.size.height - 100.0) / 2.0, MIN(self.view.frame.size.width,MAX(200.0,size.width)), 100.0);
    confirmationLabel.frame = CGRectMake((self.confirmationView.frame.size.width - size.width) / 2.0, (self.confirmationView.frame.size.height - size.height) / 2.0, MIN(size.width, self.view.frame.size.width), size.height);
    confirmationLabel.adjustsFontSizeToFitWidth = YES;
    [self.confirmationView addSubview:confirmationLabel];
    
    [self.view addSubview:self.confirmationView];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.confirmationView.frame.size.width - SPINNER_SIZE) / 2.0, confirmationLabel.frame.origin.y + confirmationLabel.frame.size.height + 2.0, SPINNER_SIZE, SPINNER_SIZE)];
    self.activityIndicatorView.color = UIColorFromRGB(0x8e0528);
    [self.confirmationView addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
    
    self.view.userInteractionEnabled = NO;
}

-(void)dismissConfirmation {
    [UIView animateWithDuration:0.2
                          delay:0.5
                        options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                            self.confirmationView.alpha = 0.2;
                        } completion:^(BOOL finished) {
                            [self.activityIndicatorView stopAnimating];
                            [self.confirmationView removeFromSuperview];
                            self.view.userInteractionEnabled = YES;
                        }];
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
                [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!error) {
                        [self facebookRequestDidLoad:result];
                    }
                }];
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
    
    [facebookFriendsIds addObject:sharedDataManager.facebookId];
    sharedDataManager.facebookFriends = facebookFriendsIds;

    [self.currentUser setObject:sharedDataManager.facebookFriends forKey:kUserFacebookFriendsKey];
    [self.currentUser saveInBackground];
    
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
                self.centerViewController.userProfilePictureView.layer.cornerRadius = 14.0;
                self.centerViewController.userProfilePictureView.clipsToBounds = YES;
                [self.centerViewController.userProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
               self.centerViewController.userProfilePictureView.frame = CGRectMake(self.view.frame.size.width - 28.0 - (self.centerViewController.bottomBar.frame.size.height - 28.0) / 2.0, (self.centerViewController.bottomBar.frame.size.height - 28.0) / 2.0, 28.0, 28.0);
                self.centerViewController.userProfilePictureView.tag = 1;
                UITapGestureRecognizer *userProfileTapGesture =
                [[UITapGestureRecognizer alloc] initWithTarget:self.centerViewController action:@selector(movePanelLeft:)];
                [self.centerViewController.userProfilePictureView addGestureRecognizer:userProfileTapGesture];
                [self.centerViewController.bottomBar addSubview:self.centerViewController.userProfilePictureView];
                [self.centerViewController.bottomBar addSubview:self.centerViewController.settingsButtonLarge];
                [self.centerViewController.bottomBar bringSubviewToFront:self.centerViewController.notificationsLabel];
            }
            
            NSString *gender = result[@"gender"];
            if (gender && [gender length] != 0) {
                [self.currentUser setObject:gender forKey:kUserGenderKey];
            }
            
            NSString *relationshipStatus = result[@"relationship_status"];
            if (relationshipStatus && [relationshipStatus length] != 0) {
                [self.currentUser setObject:relationshipStatus forKey:@"relationshipStatus"];
            }
            
//            NSLog(@"PARSE SAVE: setting your user facebook details");
            [self.currentUser saveEventually];
            
            if ([self.currentUser objectForKey:kUserStatusMessageKey]) {
                sharedDataManager.statusMessage = [self.currentUser objectForKey:kUserStatusMessageKey];
            }
            
            if ([self.currentUser objectForKey:kUserBlockedListKey]) {
                sharedDataManager.blockedList = [[NSMutableArray alloc] init];
                [sharedDataManager.blockedList addObjectsFromArray:[self.currentUser objectForKey:kUserBlockedListKey]];
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

-(void)blockFriend:(Friend*)friend block:(BOOL)block {
    NSLog(@"Blocking Friend");
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (!sharedDataManager.blockedList) {
        sharedDataManager.blockedList = [[NSMutableArray alloc] init];
    }
    if (block) {
        if (![sharedDataManager.blockedList containsObject:friend.friendID]) {
            [sharedDataManager.blockedList addObject:friend.friendID];
        }
        [sharedDataManager.tetherFriendsDictionary removeObjectForKey:friend.friendID];
    } else {
        [sharedDataManager.blockedList removeObject:friend.friendID];
        friend.blocked = NO;
        [sharedDataManager.tetherFriendsDictionary setObject:friend forKey:friend.friendID];
    }
    
    [self.currentUser setObject:sharedDataManager.blockedList forKey:kUserBlockedListKey];
    [self.currentUser saveEventually];
    [self pollDatabase];
}

-(void)queryFriendsStatus{
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSString *city = [userDetails objectForKey:kUserDefaultsCityKey];
    NSString *state = [userDetails objectForKey:kUserDefaultsStateKey];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSLog(@"Your city: %@ state: %@", city, state);
    
    if (![self.currentUser objectForKey:kUserCityKey]) {
        [self saveCity:city state:state];
    }
    
    if (city && state && sharedDataManager.facebookFriends) {
        PFQuery *facebookFriendsQuery = [PFUser query];
        [facebookFriendsQuery whereKey:kUserFacebookIDKey containedIn:sharedDataManager.facebookFriends];

        [facebookFriendsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                self.parseError = NO;
                self.previousTetherFriendsDictionary = [[NSMutableDictionary alloc] init];
                self.previousTetherFriendsDictionary = [sharedDataManager.tetherFriendsNearbyDictionary mutableCopy];
                sharedDataManager.tetherFriendsNearbyDictionary = [[NSMutableDictionary alloc] init];
                sharedDataManager.tetherFriends = [[NSMutableArray alloc] init];
                sharedDataManager.blockedFriends = [[NSMutableArray alloc] init];
                
                for (PFUser *user in objects) {
                    // check that you are no on their block list
                    NSMutableArray *blockedList = user[kUserBlockedListKey];
                    if (![blockedList containsObject:sharedDataManager.facebookId]) {
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
                        if (![self.facebookId isEqualToString:sharedDataManager.facebookId] && (![friend.statusMessage isEqualToString:((Friend*)[self.previousTetherFriendsDictionary objectForKey:friend.friendID]).statusMessage])) {
                            self.listsHaveChanged = YES;
                        }
                        
                        friend.placeId = @"";

                        if ([sharedDataManager.blockedList containsObject:friend.friendID]) {
                            friend.blocked = YES;
                            if (!sharedDataManager.blockedFriends) {
                                sharedDataManager.blockedFriends = [[NSMutableArray alloc] init];
                            }
                            [sharedDataManager.blockedFriends addObject:friend];
                        } else {
                            NSDate *startTime = [self getStartTime];
                            // Set friends place if they are going out, have been active today and have committed to a place
                            if ([sharedDataManager.friendsToPlacesMap objectForKey:friend.friendID] && [startTime compare:friend.timeLastUpdated] == NSOrderedAscending && friend.status) {
                                friend.placeId = [sharedDataManager.friendsToPlacesMap objectForKey:friend.friendID];
                            }
                            
                            if ([user[kUserCityKey] isEqualToString:city] && [user[kUserStateKey] isEqualToString:state]) {
                                [sharedDataManager.tetherFriendsNearbyDictionary setObject:friend forKey:friend.friendID];
                            }
                            [sharedDataManager.tetherFriendsDictionary setObject:friend forKey:friend.friendID];
                            [sharedDataManager.tetherFriends addObject:friend.friendID];
                        }
                    } else {
                        if ([sharedDataManager.tetherFriendsDictionary objectForKey:user[kUserFacebookIDKey]]) {
                            [sharedDataManager.tetherFriendsDictionary setObject:Nil forKey:user[kUserFacebookIDKey]];
                        }
                    }
                }
                
                [self sortTetherFriends];
                
                [self.placesViewController getFriendsCommitments];
                
                if ([self.rightPanelViewController.notificationsArray count] == 0) {
                    [self loadNotifications];
                }
                
                if (!sharedDataManager.hasUpdatedFriends) {
                    [self saveTethrFriends];
                }
                
                if ([userDetails boolForKey:@"isNew"]) {
                    [self notifyFriendsInCity];
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

-(void)saveTethrFriends {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSMutableArray *tetherFriends = [[NSMutableArray alloc] init];
    for (id key in sharedDataManager.tetherFriendsDictionary) {
        Friend *friend = [sharedDataManager.tetherFriendsDictionary objectForKey:key];
        [tetherFriends addObject:friend.friendID];
    }
    
    [self.currentUser setObject:tetherFriends forKey:@"tethrFriends"];
    [self.currentUser saveEventually];
    
    sharedDataManager.hasUpdatedFriends = YES;
}

-(void)notifyFriendsInCity {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    
    for (id key in sharedDataManager.tetherFriendsNearbyDictionary) {
        Friend *friend = [sharedDataManager.tetherFriendsNearbyDictionary objectForKey:key];
        PFQuery *friendQuery = [PFUser query];
        [friendQuery whereKey:kUserFacebookIDKey equalTo:friend.friendID];
        
        [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                // Create our Installation query
                PFUser * user = [objects objectAtIndex:0];
                PFQuery *pushQuery = [PFInstallation query];
                [pushQuery whereKey:@"owner" equalTo:user]; //change this to use friends installation
                NSString *messageHeader = [NSString stringWithFormat:@"Your Facebook friend %@ just joined tethr", sharedDataManager.name];
                NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                      messageHeader, @"alert",
                                      @"Increment", @"badge",
                                      nil];
                
                // Send push notification to query
                PFPush *push = [[PFPush alloc] init];
                [push setQuery:pushQuery]; // Set our Installation query
                [push setData:data];
                [push sendPushInBackground];
                
                PFObject *notification = [PFObject objectWithClassName:kNotificationClassKey];
                [notification setObject:sharedDataManager.facebookId forKey:kNotificationSenderKey];
                [notification setObject:messageHeader forKey:kNotificationMessageHeaderKey];
                [notification setObject:friend.friendID forKey:kNotificationRecipientKey];
                [notification setObject:[userDetails objectForKey:kUserDefaultsCityKey] forKey:kNotificationCityKey];
                [notification setObject:@"newUser" forKey:kNotificationTypeKey];
                [notification setObject:@"" forKey:kNotificationPlaceNameKey];
                [notification setObject:@"" forKey:kNotificationPlaceIdKey];
                [notification saveInBackground];
            }
        }];
    }
    [userDetails setBool:NO forKey:@"isNew"];
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
            if ((([startTime compare:friend.timeLastUpdated] == NSOrderedDescending || !friend.status) && ![sharedDataManager.friendsToPlacesMap objectForKey:friend.friendID]) || !friend.timeLastUpdated) {
                friend.placeId = @"";
                [tempFriendsUndecidedSet addObject:friend];
            } else {
                if ([friend.friendID isEqualToString:sharedDataManager.facebookId]) {
                    if (sharedDataManager.currentCommitmentPlace && ![sharedDataManager.currentCommitmentPlace.placeId isEqualToString:@""]) {
                        [tempFriendsGoingOutSet addObject:friend];
                    } else {
                        [tempFriendsNotGoingOutSet addObject:friend];
                    }
                } else {
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
    
    if (self.showingDecisionView) {
        self.decisionViewController.numberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)([sharedDataManager.tetherFriendsGoingOut count] + [sharedDataManager.tetherFriendsNotGoingOut count])];
        [self.decisionViewController layoutNumberLabel];
    }
    
    // if lists have changed or all are empty, update view
    if (self.listsHaveChanged || listsHaveChanged ||
        ([sharedDataManager.tetherFriendsUndecided count] == 0 &&
         [sharedDataManager.tetherFriendsNotGoingOut count] == 0 &&
         [sharedDataManager.tetherFriendsGoingOut count] == 0)) {
        [self.leftPanelViewController updateFriendsList];
    }
    [self refreshCommitmentName];
    self.listsHaveChanged = NO;
}

-(NSDate*)getStartTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH"];
    NSDate *now = [NSDate date];
    NSString *hour = [formatter stringFromDate:[NSDate date]];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:now];
    
    // if after 6am, start from today's date
    if ([hour intValue] > 5) {
        [components setHour:5.0];
        return [calendar dateFromComponents:components];
    } else { // if before 6am, start from yesterday's date
        NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
        [deltaComps setDay:-1.0];
        [components setHour:5.0];
        return [calendar dateByAddingComponents:deltaComps toDate:[calendar dateFromComponents:components] options:0];
    }
}

#pragma mark -
#pragma mark Setup View

- (void)setupView
{
    if (!self.showingDecisionView) {
        for (UIView *subview in [self.view subviews]) {
            [subview removeFromSuperview];
        }
        
        // setup center view
        self.centerViewController = [[CenterViewController alloc] init];
        self.centerViewController.view.tag = CENTER_TAG;
        self.centerViewController.delegate = self;
        self.centerViewController.placeToAnnotationDictionary = [[NSMutableDictionary alloc] init];
        self.centerViewController.placeToAnnotationViewDictionary = [[NSMutableDictionary alloc] init];
        
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        
        [self.view addSubview:self.centerViewController.view];
        [self addChildViewController:_centerViewController];
        [_centerViewController didMoveToParentViewController:self];
        
        if (!self.centerViewController.userProfilePictureView && sharedDataManager.facebookId) {
            self.centerViewController.userProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)sharedDataManager.facebookId pictureCropping:FBProfilePictureCroppingSquare];
            self.centerViewController.userProfilePictureView.layer.cornerRadius = 14.0;
            self.centerViewController.userProfilePictureView.clipsToBounds = YES;
            [self.centerViewController.userProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
            self.centerViewController.userProfilePictureView.frame = CGRectMake(self.view.frame.size.width - 28.0 - (self.centerViewController.bottomBar.frame.size.height - 28.0) / 2.0, (self.centerViewController.bottomBar.frame.size.height - 28.0) / 2.0, 28.0, 28.0);
            self.centerViewController.userProfilePictureView.tag = 1;
            UITapGestureRecognizer *userProfileTapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self.centerViewController action:@selector(movePanelLeft:)];
            [self.centerViewController.userProfilePictureView addGestureRecognizer:userProfileTapGesture];
            [self.centerViewController.bottomBar addSubview:self.centerViewController.userProfilePictureView];
            [self.centerViewController.bottomBar addSubview:self.centerViewController.settingsButtonLarge];
            [self.centerViewController.bottomBar bringSubviewToFront:self.centerViewController.notificationsLabel];
        }
        
        [self setupGestures];
        
        // define the view for the left panel view controller
        self.leftPanelViewController = [[LeftPanelViewController alloc] init];
        self.leftPanelViewController.view.tag = LEFT_PANEL_TAG;
        self.leftPanelViewController.delegate = self;
        
        // define the view for the left panel view controller
        self.rightPanelViewController = [[RightPanelViewController alloc] init];
        self.rightPanelViewController.delegate = self;
        self.rightPanelViewController.view.tag = RIGHT_PANEL_TAG;
        
        self.placesViewController = [[PlacesViewController alloc] init];
        self.placesViewController.delegate = self;
        
        //reset Datastore values associated with a specific day
        sharedDataManager.todaysNotificationsArray = [[NSMutableArray alloc] init];
        sharedDataManager.currentCommitmentPlace = nil;
        sharedDataManager.currentCommitmentParseObject = nil;
        sharedDataManager.tetherFriendsGoingOut = [[NSMutableArray alloc] init];
        sharedDataManager.tetherFriendsNotGoingOut = [[NSMutableArray alloc] init];
        sharedDataManager.tetherFriendsUndecided = [[NSMutableArray alloc] init];
        
        [self.centerViewController layoutCurrentCommitment];
        [self.centerViewController layoutNumberButton];
        [self updateNotificationsNumber];
        
        // check if user has input status today
        [self showDecisionView];
    }
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
    if (!self.showingDecisionView && [self shouldShowDecisionView]) {
        [self movePanelToOriginalPosition];
        self.decisionViewController = [[DecisionViewController alloc] init];
        self.decisionViewController.delegate = self;
        [self.decisionViewController addProfileImageView];
        self.showingDecisionView = YES;
        [self.view addSubview:self.decisionViewController.view];
        [self addChildViewController:_decisionViewController];
        [_decisionViewController didMoveToParentViewController:self];
    } else if ([self shouldShowDecisionView] && self.showingDecisionView) {
        [self.view bringSubviewToFront:self.decisionViewController.view];
    }
}

- (void)showCenterViewWithShadow:(BOOL)value withOffset:(double)offset
{
    if (value)
    {
        [_centerViewController.view.layer setShadowColor:[UIColor blackColor].CGColor];
        [_centerViewController.view.layer setShadowOpacity:0.6];
        [_centerViewController.view.layer setShadowOffset:CGSizeMake(0,0)];
        [_centerViewController.view.layer setShadowRadius:7.0];
        
        CGRect frame = _centerViewController.view.bounds;
        frame.size.height += 20.0;
        CGPathRef shadowPath = [UIBezierPath bezierPathWithRect:frame].CGPath;
        _centerViewController.view.layer.shadowPath = shadowPath;
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
        [self.leftPanelViewController hideSearchBar];
        self.showingLeftPanel = NO;
    }
    
    if (_rightPanelViewController != nil) {
        _centerViewController.notificationsButtonLarge.tag = 1;
         _centerViewController.userProfilePictureView.tag = 1;
        _centerViewController.listViewButton.userInteractionEnabled = YES;
        _centerViewController.listViewButtonLarge.userInteractionEnabled = YES;
        _centerViewController.userProfilePictureView.userInteractionEnabled = YES;
        _centerViewController.settingsButtonLarge.enabled = YES;
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
    
    if (self.rightPanelViewController) {
        [self.rightPanelViewController.view removeFromSuperview];
    }
    
    [self.view addSubview:self.leftPanelViewController.view];
    
    self.showingLeftPanel = YES;
    
    // set up view shadows
    [self showCenterViewWithShadow:YES withOffset:-6];
    
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
    
    if (self.leftPanelViewController) {
        [self.leftPanelViewController.view removeFromSuperview];
    }
    
    [self.view addSubview:self.rightPanelViewController.view];
    
    self.showingRightPanel = YES;
    
    UIView *view = self.rightPanelViewController.view;
    [self.rightPanelViewController.view setNeedsDisplay];
    [self.rightPanelViewController.view layoutIfNeeded];
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
     self.centerViewController.dragging = YES;
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
        CGFloat xCoord = 0.0;
        if (_showingLeftPanel) {
            xCoord = MAX(160.0,[sender view].center.x + translatedPoint.x + 0.0008*velocity.x);
        } else if (_showingRightPanel) {
            xCoord = MIN(160.0,[sender view].center.x + translatedPoint.x + 0.0008*velocity.x);
        }
        
        [sender view].center = CGPointMake(xCoord, [sender view].center.y);
        [(UIPanGestureRecognizer*)sender setTranslation:CGPointZero inView:self.view];
    }
}

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
    
    [UIView animateWithDuration:SLIDE_TIMING*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                            [self.settingsViewController.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showListView
{
    if (!self.centerViewController.dragging) {
        if (!self.placesViewController) {
            self.placesViewController = [[PlacesViewController alloc] init];
            self.placesViewController.delegate = self;
        }
        
        [self.placesViewController didMoveToParentViewController:self];
        [self.placesViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:self.placesViewController.view];
        
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.placesViewController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [self resetMainView];
                         }];
    }
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if (![userDetails boolForKey:kUserDefaultsHasSeenPlaceListTutorialKey]) {
        [userDetails setBool:YES forKey:kUserDefaultsHasSeenPlaceListTutorialKey];
        [userDetails synchronize];
        [self.centerViewController closeTutorial];
    }
}

-(void)showListViewNoReset {
    if (!self.centerViewController.dragging) {
        if (!self.placesViewController) {
            self.placesViewController = [[PlacesViewController alloc] init];
            self.placesViewController.delegate = self;
        }
        
        [self.placesViewController didMoveToParentViewController:self];
        [self.placesViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:self.placesViewController.view];
        
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.placesViewController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                              self.openingPlacePage = NO;
                         }];
    }
}

- (void)movePanelRight // to show left panel
{
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if (!self.centerViewController.listViewOpen) {
        self.centerViewController.dragging = YES;
        UIView *childView = [self getLeftView];
        [self.view sendSubviewToBack:childView];
        
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             _centerViewController.view.frame = CGRectMake(self.view.frame.size.width - PANEL_WIDTH, 0, self.view.frame.size.width, self.view.frame.size.height);
                             Datastore *sharedDataManager = [Datastore sharedDataManager];
                             if ((![userDetails boolForKey:kUserDefaultsHasSeenFriendInviteTutorialKey] && [sharedDataManager.tetherFriendsNearbyDictionary count] > 0)) {
                                 [self.leftPanelViewController addTutorialView];
                             }
                         }
                         completion:^(BOOL finished) {
                             _centerViewController.numberButton.tag = 0;
                             _centerViewController.triangleButton.tag = 0;
                             _centerViewController.leftPanelButtonLarge.tag = 0;
                             _centerViewController.mv.userInteractionEnabled = NO;
                             _centerViewController.userProfilePictureView.userInteractionEnabled = NO;
                             _centerViewController.settingsButtonLarge.enabled = NO;
                             UITapGestureRecognizer *mapTapGesture =
                             [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePanel:)];
                             [self.centerViewController.view addGestureRecognizer:mapTapGesture];
                         }];
    }
    
    if (![userDetails boolForKey:kUserDefaultsHasSeenFriendsListTutorialKey]) {
        [userDetails setBool:YES forKey:kUserDefaultsHasSeenFriendsListTutorialKey];
        [userDetails synchronize];
        [self.centerViewController closeTutorial];
    }
}

- (void)movePanelLeft // to show left panel
{
    if (!self.centerViewController.listViewOpen) {
        if (![self.view.subviews containsObject:self.decisionViewController]) {
            self.centerViewController.dragging = YES;
            UIView *childView = [self getRightView];
            [self.view sendSubviewToBack:childView];
            [childView setNeedsLayout];
            [childView layoutIfNeeded];
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
            self.centerViewController.listViewButton.userInteractionEnabled = NO;
            self.centerViewController.listViewButtonLarge.userInteractionEnabled = NO;
            
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            if (currentInstallation.badge != 0 || sharedDataManager.notifications != 0) {
                [self loadNotifications];
            }
            currentInstallation.badge = 0;
            [currentInstallation saveEventually];
            sharedDataManager.notifications = 0;
            [self updateNotificationsNumber];
            
            [UIView animateWithDuration:SLIDE_TIMING
                                  delay:0.0
                 usingSpringWithDamping:1.0
                  initialSpringVelocity:1.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 _centerViewController.view.frame = CGRectMake(-self.view.frame.size.width + PANEL_WIDTH, 0.0, self.view.frame.size.width, self.view.frame.size.height);
                             }
                             completion:^(BOOL finished) {
                                 _centerViewController.notificationsButtonLarge.tag = 0;
                                 _centerViewController.userProfilePictureView.tag = 0;
                                 _centerViewController.mv.userInteractionEnabled = NO;
                                 UITapGestureRecognizer *mapTapGesture =
                                 [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePanel:)];
                                 [self.centerViewController.view addGestureRecognizer:mapTapGesture];
                             }];
        }
    } else {
        [self movePanelToOriginalPosition];
    }
}

- (void)movePanelToOriginalPosition
{
    [UIView animateWithDuration:SLIDE_TIMING*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.01
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         _centerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                         [self resetMainView];
                          self.centerViewController.dragging = NO;
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
}

-(void)saveCity:(NSString*)city state:(NSString*)state {
    [self.currentUser setObject:city forKey:kUserCityKey];
    [self.currentUser setObject:state forKey:kUserStateKey];
    [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
           NSLog(@"Saving City, State: %@,%@", city, state);
        } else {
            NSLog(@"PARSE SAVING Error: %@ %@", error, [error userInfo]);
        }
    }];
}

-(void)openPageForPlaceWithId:(id)placeId {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (!self.openingPlacePage) {
        self.openingPlacePage = YES;
        if ([sharedDataManager.placesDictionary objectForKey:placeId]) {
            Place *place;
            place = [sharedDataManager.placesDictionary objectForKey:placeId];
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
            

            [UIView animateWithDuration:SLIDE_TIMING
                                  delay:0.0
                 usingSpringWithDamping:1.0
                  initialSpringVelocity:1.0
                                options:UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 [self.friendsListViewController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                             }
                             completion:^(BOOL finished) {
                                 self.openingPlacePage = NO;
                             }];
        } else {
            // TODO: fetch place from foursquare
            self.centerViewController.dragging = NO;
            [self showListViewNoReset];
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
            [self pollDatabase];
        }];

    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [userDetails setBool:choice forKey:kUserDefaultsStatusKey];
    [userDetails setObject:[NSDate date] forKey:kUserDefaultsTimeLastUpdatedKey];
    
    PFUser *user = [PFUser currentUser];
    [user setObject:[NSNumber numberWithBool:choice] forKey:kUserStatusKey];
    [user setObject:[NSDate date] forKey:kUserTimeLastUpdatedKey];
    [user saveInBackground];
    
    [self.centerViewController updateLocation];
    
    if (self.settingsViewController) {
        self.settingsViewController.goingOutSwitch.on = choice;
    }
    
    if (![userDetails boolForKey:kUserDefaultsHasSeenRefreshTutorialKey] || ![userDetails boolForKey:kUserDefaultsHasSeenFriendsListTutorialKey] || ![userDetails boolForKey:kUserDefaultsHasSeenPlaceListTutorialKey] || ![userDetails boolForKey:kUserDefaultsHasSeenCityChangeTutorialKey]) {
        [self.centerViewController addTutorialView];
    }
}

#pragma mark SettingsViewControllerDelegate

-(void)closeSettings {
    [UIView animateWithDuration:SLIDE_TIMING*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                            [self.settingsViewController.view setFrame:CGRectMake( 0.0f, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.settingsViewController.view removeFromSuperview];
                         [self.settingsViewController removeFromParentViewController];
                         self.listsHaveChanged = YES;
                     }];
}

-(void)userChangedLocationToCityName:(NSString*)city{
    CLGeocoder *geo = [[CLGeocoder alloc] init];
    [geo geocodeAddressString:city completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            if ([placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks objectAtIndex:0];
                CLLocation *location = placemark.location;
                NSLog(@"setting user coordinates from city name to %f %f", location.coordinate.latitude, location.coordinate.longitude);
                [self userChangedLocationInSettings:location];
            }
        } else {
            NSLog(@"Error: %@", error);
        }
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
      self.centerViewController.dragging = NO;
    [self movePanelToOriginalPosition];
    [self performSelector:@selector(showListView) withObject:nil afterDelay:0.2];
    [self.placesViewController.placesTableView reloadData];
    [self.placesViewController scrollToPlaceWithId:placeId];
}

-(void)inviteFriend:(Friend *)friend {
    self.inviteViewController = [[InviteViewController alloc] init];
    self.inviteViewController.delegate = self;
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentPlace) {
        self.inviteViewController.place = sharedDataManager.currentCommitmentPlace;
        [self.inviteViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.inviteViewController addFriend:friend];
        [self.inviteViewController layoutPlusIcon];
    } else {
        [self.inviteViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.inviteViewController setSearchPlaces];
        [self.inviteViewController searchBarCancelButtonClicked:self.inviteViewController.placeSearchBar];
        [self.inviteViewController addFriend:friend];
        [self.inviteViewController layoutPlusIcon];
    }

    [self.view addSubview:self.inviteViewController.view];
    [self addChildViewController:self.inviteViewController];
    [self.inviteViewController didMoveToParentViewController:self];
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.inviteViewController.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         if (self.leftPanelViewController) {
                             [self.leftPanelViewController hideSearchBar];
                         }
                     }];
}

#pragma mark FriendInviteViewControllerDelegate methods

-(void)closeInviteView {
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
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
        if ([place.friendsCommitted isEqualToSet:previousAnnotation.place.friendsCommitted] && !self.committingToPlace) {
            return;
        }
        
        [self removePlaceMarkFromMapView:place];
    }
    [self.centerViewController.placeToAnnotationDictionary  setObject:annotation forKey:place.placeId];
    if ([place.friendsCommitted count] > 0) {
        [self.centerViewController.mv addAnnotation:annotation];
    }
    self.committingToPlace = NO;
}

-(void)removePlaceMarkFromMapView:(Place*)place {
    if (place) {
        TetherAnnotation *annotation = [self.centerViewController.placeToAnnotationDictionary objectForKey:place.placeId];
        [self.centerViewController.mv removeAnnotation:annotation];
        
        if ([self.centerViewController.placeToAnnotationDictionary objectForKey:place.placeId]) {
            [self.centerViewController.placeToAnnotationDictionary removeObjectForKey:place.placeId];
            [self.centerViewController.placeToAnnotationViewDictionary removeObjectForKey:place.placeId];
        }
        
        if ([self.centerViewController.annotationsArray containsObject:annotation]) {
            [self.centerViewController.annotationsArray removeObject:annotation];
        }
    }
}

-(void)selectAnnotationForPlace:(Place*)place {
    [self movePanelToOriginalPosition];
    if ([self.centerViewController.placeToAnnotationViewDictionary objectForKey:place.placeId]) {
        TetherAnnotationView *annotationView = [self.centerViewController.placeToAnnotationViewDictionary objectForKey:place.placeId];
        if (!annotationView.isSelected) {
            annotationView.tag = 1;
            [self.centerViewController.mv selectAnnotation:((MKAnnotationView*)annotationView).annotation animated:YES];
            annotationView.placeTouchView.userInteractionEnabled = YES;
            annotationView.tag = 0;
        }

    }
}

-(void)closeListView {
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                        [self.placesViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.placesViewController.view removeFromSuperview];
                         [self.placesViewController removeFromParentViewController];
                         [self canUpdatePlaces:YES];
                         [self.placesViewController sortPlacesByPopularity];
                         self.centerViewController.listViewOpen = NO;
                         self.placesViewController.closingListView = NO;
                         self.placesViewController.disableSort = NO;
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
    self.committingToPlace = YES;
    [self confirmTetheringToPlace:place];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [self handleLocalCommitmentToPlace:place];
    
    if (sharedDataManager.currentCommitmentPlace) {
        [self removePreviousCommitment];
    }
    
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

            
            NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
            BOOL status = [userDetails boolForKey:kUserDefaultsStatusKey];
            NSDate *timeLastUpdated = [userDetails objectForKey:kUserDefaultsTimeLastUpdatedKey];
            
            if (!status || [[self getStartTime] compare:timeLastUpdated] == NSOrderedDescending) {
                [userDetails setBool:YES forKey:kUserDefaultsStatusKey];
                [userDetails setObject:[NSDate date] forKey:kUserDefaultsTimeLastUpdatedKey];
                [userDetails synchronize];
                
                PFUser *user = [PFUser currentUser];
                [user setObject:[NSNumber numberWithBool:YES] forKey:kUserStatusKey];
                [user setObject:[NSDate date] forKey:kUserTimeLastUpdatedKey];
                [user saveInBackground];
                
                self.settingsViewController.goingOutSwitch.on = YES;
            }
            
            if (![userDetails boolForKey:kUserDefaultsHasSeenTethrTutorialKey]) {
                [userDetails setBool:YES forKey:kUserDefaultsHasSeenTethrTutorialKey];
                [userDetails synchronize];
            }
            
            self.committingToPlace = YES;
            [commitment saveEventually:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    NSLog(@"PARSE SAVE: saved your new commitment");
                    sharedDataManager.currentCommitmentParseObject = commitment;
                    self.committingToPlace = NO;
                    self.listsHaveChanged = YES;
                    [self pollDatabase];
                } else {
                    NSLog(@"Committing Error: %@ %@", error, [error userInfo]);
                }
            }];
            
            [self notifyFriendsForCommitmentToPlace:place];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

-(void)handleLocalCommitmentToPlace:(Place*)place {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    Place *p = [sharedDataManager.placesDictionary objectForKey:place.placeId];
    if (p) {
        NSMutableSet *friendsCommitted = [[NSMutableSet alloc] init];
        if (p.friendsCommitted) {
            friendsCommitted = p.friendsCommitted;
        }
        
        [friendsCommitted addObject:sharedDataManager.facebookId];
        if (friendsCommitted) {
            p.numberCommitments = [friendsCommitted count];
        }

        sharedDataManager.currentCommitmentPlace = p;
        [sharedDataManager.placesDictionary setObject:p forKey:p.placeId];
        
        [self.placesViewController setCellForPlace:p tethered:YES];
        
        [self placeMarkOnMapView:p];
    }
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
        [friendQuery whereKey:kUserFacebookIDKey equalTo:friend.friendID];

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
                [invitation setObject:sharedDataManager.facebookId forKey:kNotificationSenderKey];
                [invitation setObject:place.name forKey:kNotificationPlaceNameKey];
                [invitation setObject:place.placeId forKey:kNotificationPlaceIdKey];
                [invitation setObject:messageHeader forKey:kNotificationMessageHeaderKey];
                [invitation setObject:friend.friendID forKey:kNotificationRecipientKey];
                [invitation setObject:place.city forKey:kNotificationCityKey];
                [invitation setObject:@"acceptance" forKey:kNotificationTypeKey];
                [invitation saveInBackground];
           }
        }];
    }
}

-(void)removePreviousCommitment {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentPlace) {
        if ([sharedDataManager.currentCommitmentPlace.friendsCommitted containsObject:sharedDataManager.facebookId]) {
            [sharedDataManager.currentCommitmentPlace.friendsCommitted removeObject:sharedDataManager.facebookId];
            sharedDataManager.currentCommitmentPlace.numberCommitments = [sharedDataManager.currentCommitmentPlace.friendsCommitted count];
            NSLog(@"Removing previous commitment to %@ with %lu commitments", sharedDataManager.currentCommitmentPlace.name, (unsigned long)[sharedDataManager.currentCommitmentPlace.friendsCommitted count]);
            sharedDataManager.currentCommitmentPlace.numberCommitments = MAX(0, sharedDataManager.currentCommitmentPlace.numberCommitments - 1);
            [sharedDataManager.placesDictionary setObject:sharedDataManager.currentCommitmentPlace
                                                   forKey:sharedDataManager.currentCommitmentPlace.placeId];
            [sharedDataManager.popularPlacesDictionary setObject:sharedDataManager.currentCommitmentPlace
                                                          forKey:sharedDataManager.currentCommitmentPlace.placeId];
            [self removePlaceMarkFromMapView:sharedDataManager.currentCommitmentPlace];
        }
        [self.placesViewController setCellForPlace:sharedDataManager.currentCommitmentPlace tethered:NO];
        sharedDataManager.currentCommitmentPlace = nil;
    }
}

-(void)removeCommitmentFromDatabase {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentParseObject) {
        [sharedDataManager.currentCommitmentParseObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                NSLog(@"PARSE DELETE: Removed previous commitment from database");
                sharedDataManager.currentCommitmentParseObject = nil;
                self.listsHaveChanged = YES;
                [self pollDatabase];
            } else {
                NSLog(@"PARSE DELETE Error: %@ %@", error, [error userInfo]);
            }
        }];
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
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.friendsListViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [self.friendsListViewController.view removeFromSuperview];
                             [self.friendsListViewController removeFromParentViewController];
                              self.centerViewController.listViewOpen = NO;
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
