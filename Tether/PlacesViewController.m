//
//  PlacesViewController.m
//  Tether
//
//  Created by Laura Smith on 11/29/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Constants.h"
#import "Datastore.h"
#import "Flurry.h"
#import "Friend.h"
#import "FriendsListViewController.h"
#import "InviteViewController.h"
#import "Place.h"
#import "PlaceCell.h"
#import "PlacesViewController.h"
#import "SearchResultCell.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <Parse/Parse.h>

#define CELL_HEIGHT 90.0
#define HEADER_HEIGHT 50.0
#define SEARCH_RESULTS_CELL_HEIGHT 60.0
#define SEARCH_BAR_HEIGHT 50.0
#define SEARCH_BAR_WIDTH 270.0
#define SLIDE_TIMING 0.6
#define SPINNER_SIZE 30.0
#define STATUS_BAR_HEIGHT 20.0

@interface PlacesViewController () <InviteViewControllerDelegate, FriendsListViewControllerDelegate, PlaceCellDelegate, UIGestureRecognizerDelegate,UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *placesArray;
@property (nonatomic, strong) UITableViewController *placesTableViewController;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UIButton *backButtonLarge;
@property (retain, nonatomic) NSUserDefaults *userDetails;
@property (assign, nonatomic) bool friendStatusDetailsHaveLoaded;
@property (assign, nonatomic) bool foursquarePlacesDataHasLoaded;
@property (retain, nonatomic) UISearchBar *searchBar;
@property (retain, nonatomic) NSMutableArray *searchResultsArray;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UITableViewController *searchResultsTableViewController;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (assign, nonatomic) bool openingInviteView;
@property (retain, nonatomic) UIView *confirmationView;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (retain, nonatomic) FriendsListViewController *friendsListViewController;

@end

@implementation PlacesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        sharedDataManager.popularPlacesDictionary = [[NSMutableDictionary alloc] init];
        sharedDataManager.foursquarePlacesDictionary = [[NSMutableDictionary alloc] init];
        sharedDataManager.friendsToPlacesMap = [[NSMutableDictionary alloc] init];
        self.placesArray = [[NSMutableArray alloc] init];
        self.friendStatusDetailsHaveLoaded = NO;
        self.foursquarePlacesDataHasLoaded = NO;
        self.userDetails = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBack:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];
    
    // set up search bar and corresponding search results tableview
    UIView *searchBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, STATUS_BAR_HEIGHT + SEARCH_BAR_HEIGHT)];
    [searchBarBackground setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:searchBarBackground];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake((self.view.frame.size.width - SEARCH_BAR_WIDTH) / 2, STATUS_BAR_HEIGHT, SEARCH_BAR_WIDTH, SEARCH_BAR_HEIGHT)];
    self.searchBar.delegate = self;
    [self.searchBar setBackgroundImage:[UIImage new]];
    [self.searchBar setTranslucent:YES];
    self.searchBar.layer.cornerRadius = 5.0;
    self.searchBar.placeholder = @"Search places...";
    [self.view addSubview:self.searchBar];
    
    self.searchResultsArray = [[NSMutableArray alloc] init];
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, STATUS_BAR_HEIGHT + self.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    self.searchResultsTableView.hidden = YES;
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    [self.searchResultsTableView reloadData];
    
    //set up friends going out table view
    self.placesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, STATUS_BAR_HEIGHT + self.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.searchBar.frame.size.height - STATUS_BAR_HEIGHT)];
    [self.placesTableView setSeparatorColor:UIColorFromRGB(0xc8c8c8)];
    [self.placesTableView setDataSource:self];
    [self.placesTableView setDelegate:self];
    self.placesTableView.showsVerticalScrollIndicator = NO;
    self.placesTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.placesTableView];
    [self.view addSubview:self.searchResultsTableView];
    
    self.placesTableViewController = [[UITableViewController alloc] init];
    self.placesTableViewController.tableView = self.placesTableView;
    
    [self.placesTableView setSeparatorInset:UIEdgeInsetsZero];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = UIColorFromRGB(0x8e0528);
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.placesTableViewController.refreshControl = self.refreshControl;
    
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, (SEARCH_BAR_HEIGHT + STATUS_BAR_HEIGHT + 7.0) / 2.0, 7.0, 11.0)];
    [self.backButton setImage:triangleImage forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(closeListView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButton];
    
    self.backButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, (self.view.frame.size.width - SEARCH_BAR_WIDTH) / 2.0, STATUS_BAR_HEIGHT + 60.0)];
    [self.backButtonLarge addTarget:self action:@selector(closeListView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButtonLarge];
}

-(void)getFriendsCommitments {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSMutableArray *friendsArrayWithMe = [[NSMutableArray alloc] initWithArray:sharedDataManager.tetherFriends];

    if (sharedDataManager.facebookId) {
        [friendsArrayWithMe addObject:sharedDataManager.facebookId];
    
    NSString *userCity;
    NSString *userState = [[NSString alloc] init];
    userCity = [self.userDetails objectForKey:kUserDefaultsCityKey];
    userState = [self.userDetails objectForKey:kUserDefaultsStateKey];
        
    NSDate *lastWeek = [self getThisWeek];
    
    PFQuery *query = [PFQuery queryWithClassName:kCommitmentClassKey];
    [query whereKey:kUserFacebookIDKey containedIn:friendsArrayWithMe];        
    if ([self.userDetails boolForKey:@"cityFriendsOnly"]) {
        [query whereKey:kCommitmentCityKey equalTo:userCity];
    }
    [query whereKey:kCommitmentDateKey greaterThan:lastWeek];
    query.limit = 5000; // is this an appropriate limit?
    
    NSDate *startTime = [self getStartTime];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFGeoPoint *geoPoint;
            NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];

            sharedDataManager.friendsToPlacesMap = [[NSMutableDictionary alloc] init];
            for (PFObject *object in objects) {
                Place *place = [[Place alloc] init];
                geoPoint = [object objectForKey:kCommitmentGeoPointKey];
                id friendID =[object objectForKey:kUserFacebookIDKey];
                if (![tempDictionary objectForKey:[object objectForKey:kCommitmentPlaceIDKey]]) {
                    place.city = [object objectForKey:kCommitmentCityKey];
                    place.name = [object objectForKey:kCommitmentPlaceKey];
                    place.address = [object objectForKey:kCommitmentAddressKey];
                    place.coord = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
                    place.placeId = [object objectForKey:kCommitmentPlaceIDKey];
                    place.numberCommitments = 0;
                    place.numberPastCommitments = 0;
                    place.friendsCommitted = [[NSMutableSet alloc] init];
                } else {
                    place = [tempDictionary objectForKey:[object objectForKey:kCommitmentPlaceIDKey]];
                }
                
                NSDate *commitmentTime = [object objectForKey:kCommitmentDateKey];
                if (commitmentTime != nil && [startTime compare:commitmentTime] == NSOrderedAscending) {
                    // commitment for tonight
                    [place.friendsCommitted addObject:[object objectForKey:kUserFacebookIDKey]];
                    NSLog(@"Adding commitments to %@", place.name);
                    place.numberCommitments = place.numberCommitments + 1;
                    if ([sharedDataManager.facebookId isEqualToString:friendID] && ![sharedDataManager.currentCommitmentPlace.name isEqualToString:place.name]) {
                        NSLog(@"Setting your current commitment to %@", place.name);
                        sharedDataManager.currentCommitmentPlace = place;
                        sharedDataManager.currentCommitmentParseObject = object;
                        if ([self.delegate respondsToSelector:@selector(refreshCommitmentName)]) {
                            [self.delegate refreshCommitmentName];
                        }
                    }
                    if ([self.delegate respondsToSelector:@selector(setPlace:forFriend:)]) {
                        [self.delegate setPlace:place.placeId forFriend:friendID];
                    }
                    
                    if ([object objectForKey:kCommitmentPlaceIDKey]) {
                        [tempDictionary setObject:place forKey:[object objectForKey:kCommitmentPlaceIDKey]];
                    }
                } else {
                    place.numberPastCommitments = place.numberPastCommitments + 1;
                    
                    if ([object objectForKey:kCommitmentPlaceIDKey] && [[object objectForKey:kCommitmentCityKey] isEqualToString:userCity]) {
                        [tempDictionary setObject:place forKey:[object objectForKey:kCommitmentPlaceIDKey]];
                    }
                }
            }
            
            if ([self.delegate respondsToSelector:@selector(sortFriendsList)]) {
                [self.delegate sortFriendsList];
            }
            
            if (self.friendStatusDetailsHaveLoaded) {
                if (sharedDataManager.currentCommitmentPlace.placeId && [sharedDataManager.currentCommitmentPlace.city isEqualToString:userCity]) {
                    Place *p = [tempDictionary objectForKey:sharedDataManager.currentCommitmentPlace.placeId];
                    if (!p) {
                        [tempDictionary setObject:sharedDataManager.currentCommitmentPlace forKey:sharedDataManager.currentCommitmentPlace.placeId];
                    }
                }
            }
            
            //check for old commitments to remove from the map
            for (id key in sharedDataManager.popularPlacesDictionary) {
                Place *place = [sharedDataManager.popularPlacesDictionary objectForKey:key];
                if ([tempDictionary objectForKey:key]) {
                    Place *placeTemp = [tempDictionary objectForKey:key];
                    if (![place.friendsCommitted isEqualToSet:placeTemp.friendsCommitted]) {
                        [self.delegate removePlaceMarkFromMapView:place];
                    }
                } else {
                    [self.delegate removePlaceMarkFromMapView:place];
                }
            }

            sharedDataManager.popularPlacesDictionary = tempDictionary;
            
            if (self.foursquarePlacesDataHasLoaded) {
                    [self addDictionaries];
                    [self sortPlacesByPopularity];
            }

            self.friendStatusDetailsHaveLoaded = YES;
        } else {
            NSLog(@"Error Querying friends commitments: %@ %@", error, [error userInfo]);
            if (self.foursquarePlacesDataHasLoaded) {
                [self addDictionaries];
                [self sortPlacesByPopularity];
            }
        }
    }];
    if (!self.foursquarePlacesDataHasLoaded) {
        [self loadStoredPlaces];
    }
    }
}

-(void)addDictionaries {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    sharedDataManager.placesDictionary = [[NSMutableDictionary alloc] init];
    for (id key in sharedDataManager.popularPlacesDictionary) {
        Place *place = [sharedDataManager.popularPlacesDictionary objectForKey:key];
        
        if ([sharedDataManager.foursquarePlacesDictionary objectForKey:key]) {
            Place *tempPlace = [sharedDataManager.foursquarePlacesDictionary objectForKey:key];
            [place.friendsCommitted unionSet:tempPlace.friendsCommitted];
            place.numberCommitments = [place.friendsCommitted count];
        }
        [sharedDataManager.placesDictionary setObject:place forKey:place.placeId];
    }
    
    for (id key in sharedDataManager.foursquarePlacesDictionary) {
        if (![sharedDataManager.placesDictionary objectForKey:key]) {
            Place *place = [sharedDataManager.foursquarePlacesDictionary objectForKey:key];
            [sharedDataManager.placesDictionary setObject:place forKey:place.placeId];
        }
    }
    
    [self addPinsToMap];
    
    // update current commitment
    if ([sharedDataManager.placesDictionary objectForKey:sharedDataManager.currentCommitmentPlace.placeId]) {
        sharedDataManager.currentCommitmentPlace = [sharedDataManager.placesDictionary objectForKey:sharedDataManager.currentCommitmentPlace.placeId];
        if ([self.delegate respondsToSelector:@selector(refreshCommitmentName)]) {
            [self.delegate refreshCommitmentName];
        }
    }
    
    if (sharedDataManager.placeIDForNotification && ![sharedDataManager.placeIDForNotification isEqualToString:@""]) {
        if ([self.delegate respondsToSelector:@selector(openPageForPlaceWithId:)]) {
            [self.delegate openPageForPlaceWithId:sharedDataManager.placeIDForNotification];
            sharedDataManager.placeIDForNotification = @"";
        }
    }
}

-(void)sortPlacesByPopularity {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [self.placesArray removeAllObjects];
    for(id key in sharedDataManager.placesDictionary) {
        [self.placesArray addObject:[sharedDataManager.placesDictionary objectForKey:key]];
    }
    
    sharedDataManager.placesArray = [[NSMutableArray alloc] init];
    sharedDataManager.placesArray = [self.placesArray mutableCopy];
    
    // Sort places first by tonights popularity, then past popularity
    NSSortDescriptor *numberCommitmentsDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"numberCommitments" ascending:NO];
    NSSortDescriptor *numberPastCommitmentsDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"numberPastCommitments" ascending:NO];
    [self.placesArray sortUsingDescriptors:[NSArray arrayWithObjects:numberCommitmentsDescriptor, numberPastCommitmentsDescriptor, nil]];
    if ([self.delegate respondsToSelector:@selector(dismissConfirmation)]) {
        [self.delegate dismissConfirmation];
    }
    
    [self.placesTableView reloadData];
    if (self.disableSort && sharedDataManager.currentCommitmentPlace) {
        [self scrollToPlaceWithId:sharedDataManager.currentCommitmentPlace.placeId];
        self.disableSort = NO;
    }
}

-(void)addPinsToMap {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    for (id key in sharedDataManager.popularPlacesDictionary) {
        Place *p = [sharedDataManager.popularPlacesDictionary objectForKey:key];
        if (p) {
            if ([p.friendsCommitted count] > 0) {
                [self.delegate placeMarkOnMapView:p];
            }
        }
    }
}

-(void)closeListView {
    if (!self.closingListView) {
        self.closingListView = YES;
        [self searchBarCancelButtonClicked:self.searchBar];
        if ([self.delegate respondsToSelector:@selector(closeListView)]) {
            [self.delegate closeListView];
        }
        
        if (![self.userDetails boolForKey:kUserDefaultsHasSeenTethrTutorialKey]) {
            [self closeTutorial];
        }
    }
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

-(NSDate*)getThisWeek{
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:now];
    NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
    [deltaComps setDay:-7.0];
    return [calendar dateByAddingComponents:deltaComps toDate:[calendar dateFromComponents:components] options:0];
}

-(void)scrollToPlaceWithId:(id)placeId {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    Place *place = [sharedDataManager.placesDictionary objectForKey:placeId];
    
    [self.placesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.placesArray indexOfObject:place] inSection:0]
                                atScrollPosition:UITableViewScrollPositionTop animated:NO];
    
    PlaceCell *cell = (PlaceCell*)[self.placesTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.placesArray indexOfObject:place] inSection:0]];
   [self showFriendsViewFromCell:cell];
}

-(void)openPageForPlaceWithId:(id)placeId {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    Place *place = [sharedDataManager.placesDictionary objectForKey:placeId];
    if (place.numberCommitments > 0) {
        if (place.numberCommitments == 1 && [place.friendsCommitted containsObject:sharedDataManager.facebookId]) {
            return;
        } else {
            [self scrollToPlaceWithId:placeId];
            PlaceCell *cell = (PlaceCell*)[self.placesTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.placesArray indexOfObject:place] inSection:0]];
            [self showFriendsViewFromCell:cell];
        }
    }
}

-(void)refresh {
    [self.refreshControl beginRefreshing];
    [self performSelector:@selector(endRefresh:) withObject:self.refreshControl afterDelay:1.0f];
    [self getFriendsCommitments];
}

- (void)endRefresh:(UIRefreshControl *)refresh
{
    [refresh performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:NO];
}

#pragma mark gesture handlers

-(void)moveBack:(id)sender {
    [[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];
    
    CGPoint velocity = [(UIPanGestureRecognizer*)sender velocityInView:[sender view]];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if(velocity.x > 0 && !self.friendsListViewController) {
            [self closeListView];
        }
    }
}

#pragma mark PlaceCellDelegate Methods

-(void)commitToPlace:(Place*)place fromCell:(PlaceCell *)cell {
    self.disableSort = YES;
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    if ([self.delegate respondsToSelector:@selector(commitToPlace:)]) {
       [self.delegate commitToPlace:place];
    }
    sharedDataManager.currentCommitmentPlace = place;
    [cell layoutCommitButton];
    [cell setNeedsLayout];
}

-(void)removePreviousCommitment {
    if ([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
        [self.delegate removePreviousCommitment];
    }
}

-(void)removeCommitmentFromDatabase {
    if ([self.delegate respondsToSelector:@selector(removeCommitmentFromDatabase)]) {
        [self.delegate removeCommitmentFromDatabase];
    }
}

-(void)showFriendsViewFromCell:(PlaceCell*) placeCell {
    if  (!self.friendsListViewController) {
        if ([self.delegate respondsToSelector:@selector(canUpdatePlaces:)]) {
            [self.delegate canUpdatePlaces:NO];
        }
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        Place *place =  [sharedDataManager.placesDictionary objectForKey:placeCell.place.placeId];
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
        self.friendsListViewController.place = placeCell.place;
        [self.friendsListViewController loadFriendsOfFriends];
        [self.friendsListViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:self.friendsListViewController.view];
        [self addChildViewController:self.friendsListViewController];
        [self.friendsListViewController didMoveToParentViewController:self];
        
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.friendsListViewController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [self searchBarCancelButtonClicked:self.searchBar];
                         }];
    }
}

-(void)inviteToPlace:(Place *)place {
    if (!self.openingInviteView) {
        self.openingInviteView = YES;
        InviteViewController *inviteViewController = [[InviteViewController alloc] init];
        inviteViewController.delegate = self;
        inviteViewController.place = place;
        [inviteViewController layoutPlusIcon];
        [inviteViewController.view setBackgroundColor:[UIColor blackColor]];
        [inviteViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:inviteViewController.view];
        [self addChildViewController:inviteViewController];
        [inviteViewController didMoveToParentViewController:self];
        
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [inviteViewController.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [self searchBarCancelButtonClicked:self.searchBar];
                             self.openingInviteView = NO;
                         }];
    }
}

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
                             self.friendsListViewController = nil;
                         }];
}

-(void)setCellForPlace:(Place*)place tethered:(BOOL)tethered {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    Place *p = [sharedDataManager.placesDictionary objectForKey:place.placeId];
    PlaceCell *cell = (PlaceCell*)[self.placesTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.placesArray indexOfObject:p] inSection:0]];
    
    [cell setTethered:tethered];
    [cell setNeedsDisplay];
    [cell setNeedsLayout];
}

#pragma mark FriendsListViewControllerDelegate

-(void)commitToPlace:(Place *)place {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
        
    Place *p = [sharedDataManager.placesDictionary objectForKey:place.placeId];
        
    PlaceCell *cell = (PlaceCell*)[self.placesTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[self.placesArray indexOfObject:p] inSection:0]];
    if ([cell.place.placeId isEqualToString:sharedDataManager.currentCommitmentPlace.placeId]) {
        [self removePreviousCommitment];
        [self removeCommitmentFromDatabase];
    } else {
        [self commitToPlace:cell.place fromCell:cell];
    }
}

-(void)selectAnnotationForPlace:(Place*)place {
    if ([self.delegate respondsToSelector:@selector(selectAnnotationForPlace:)]) {
        [self.delegate selectAnnotationForPlace:place];
        [self closeListView];
    }
}

#pragma mark InviteViewControllerDelegate
-(void)closeInviteView {
    for (UIViewController *childViewController in self.childViewControllers) {
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [childViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [childViewController.view removeFromSuperview];
                             [childViewController removeFromParentViewController];
                         }];
    }
}


#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text=@"";
    
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    
    self.searchResultsArray = nil;
    [self.searchResultsTableView reloadData];
    self.searchResultsTableView.hidden = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self loadPlacesForSearch:searchBar.text];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchResultsTableView.hidden = NO;
}

-(void)loadStoredPlaces {
    NSString *city = [self.userDetails objectForKey:@"city"];
    NSString *state = [self.userDetails objectForKey:@"state"];
    
    PFQuery *query = [PFQuery queryWithClassName:kCityPlaceSearchClassKey];
    [query whereKey:kCityPlaceSearchCityKey equalTo:city];
    [query whereKey:kCityPlaceSearchStateKey equalTo:state];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFObject *cityPlaceSearch;
            if ([objects count] > 0) {
                cityPlaceSearch = [objects objectAtIndex:0];
                NSDate *placeSearchTime = [cityPlaceSearch objectForKey:kCityPlaceSearchDateKey];
                NSDate *previousMonth = [self getPreviousMonthTime];
                if (placeSearchTime != nil &&
                    [previousMonth compare:placeSearchTime] == NSOrderedAscending) {
                    // get stored places
                    [self loadStoredPlacesFromSearchObject:cityPlaceSearch];
                } else {
                    //delete all places associated with this search
                    //load places from foursquare
                    NSLog(@"no stored places");
                    [self deleteSavedPlaceSearchObject:cityPlaceSearch];
                    [self loadPlaces];
                }
            } else {
                // load places from foursquare
                [self loadPlaces];
            }
        } else {
            [self loadPlaces];
        }
    }];
}

-(void)loadStoredPlacesFromSearchObject:(PFObject*)object {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    PFQuery *query = [PFQuery queryWithClassName:kPlaceClassKey];
    [query whereKey:kPlaceSearchKey equalTo:object.objectId];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if ([objects count] > 30) {
                for (PFObject *placeObject in objects) {
                    Place *newPlace = [[Place alloc] init];
                    newPlace.placeId = [placeObject objectForKey:@"placeId"];
                    newPlace.name = [placeObject objectForKey:kPlaceNameKey];
                    newPlace.city = [placeObject objectForKey:kPlaceCityKey];
                    newPlace.state = [self.userDetails objectForKey:kPlaceStateKey];
                    newPlace.address = [placeObject objectForKey:kPlaceAddressKey];
                    PFGeoPoint *geoPoint = [placeObject objectForKey:kPlaceCoordinateKey];
                    newPlace.coord = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
                    
                    if (![sharedDataManager.foursquarePlacesDictionary objectForKey:newPlace.placeId]) {
                        [sharedDataManager.foursquarePlacesDictionary setObject:newPlace forKey:newPlace.placeId];
                    }
                }
                
                if (self.friendStatusDetailsHaveLoaded) {
                    [self addDictionaries];
                    [self sortPlacesByPopularity];
                }
                NSLog(@"FINISHED LOADING FOURSQUARE DATA FROM PARSE DATASTORE with %lu objects", (unsigned long)[sharedDataManager.foursquarePlacesDictionary count]);
                self.foursquarePlacesDataHasLoaded = YES;
            } else {
                [self loadPlaces];
            }
        } else {
            //load places from foursquare
            [self loadPlaces];
        }
    }];
}

-(NSDate*)getPreviousMonthTime{
    NSDate *today = [[NSDate alloc] init];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setMonth:-1]; // note that I'm setting it to -1
    NSDate *previousMonth= [calendar dateByAddingComponents:offsetComponents toDate:today options:0];
    return previousMonth;
}

-(void)saveFoursquareSearch {
    NSString *city = [self.userDetails objectForKey:@"city"];
    NSString *state = [self.userDetails objectForKey:@"state"];
    
    // delete old objects ?
    PFObject *placeSearch = [PFObject objectWithClassName:kCityPlaceSearchClassKey];
    [placeSearch setObject:[NSDate date] forKey:kCityPlaceSearchDateKey];
    [placeSearch setObject:city forKey:kCityPlaceSearchCityKey];
    [placeSearch setObject:state forKey:kCityPlaceSearchStateKey];
    [placeSearch saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSString *cityPlaceSearchObjectId = [placeSearch objectId];
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            
            for (id key in sharedDataManager.foursquarePlacesDictionary) {
                Place *place = [sharedDataManager.foursquarePlacesDictionary objectForKey:key];
                PFObject *placeObject = [PFObject objectWithClassName:kPlaceClassKey];
                
                if (place.placeId) {
                    [placeObject setObject:place.placeId forKey:@"placeId"];
                }
                
                if (cityPlaceSearchObjectId) {
                    [placeObject setObject:cityPlaceSearchObjectId forKey:kPlaceSearchKey];
                }
                
                if (place.name) {
                    [placeObject setObject:place.name forKey:kPlaceNameKey];
                }
                
                if (place.address) {
                    [placeObject setObject:place.address forKey:kPlaceAddressKey];
                }
                
                if (city) {
                    [placeObject setObject:city forKey:kPlaceCityKey];
                }
                
                if (state) {
                    [placeObject setObject:state forKey:kPlaceStateKey];
                }
                
                if (place.coord.latitude) {
                    [placeObject setObject:[PFGeoPoint geoPointWithLatitude:place.coord.latitude
                                                                  longitude:place.coord.longitude] forKey:kPlaceCoordinateKey];
                }
                
                [placeObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (error) {
                        NSLog(@"Place save Error: %@ %@", error, [error userInfo]);
                    }
                }];
            }
        } else {

        }
    }];


}

-(void)deleteSavedPlaceSearchObject:(PFObject*)object {
    PFQuery *query = [PFQuery queryWithClassName:kPlaceClassKey];
    [query whereKey:kPlaceSearchKey equalTo:object.objectId];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *placeObject in objects) {
                [placeObject deleteInBackground];
            }
            [object deleteInBackground];
        }
    }];
}

// Intial foursquare data call
- (void)loadPlaces {
    NSString *city = [self.userDetails objectForKey:@"city"];
    NSString *state = [self.userDetails objectForKey:@"state"];
    // check if city name contains illegal characters
    NSCharacterSet * set = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789"] invertedSet];
    
    if ([city rangeOfCharacterFromSet:set].location != NSNotFound) {
        NSLog(@"This string contains illegal characters");
        
        city = [self removeIllegalCharactersFromString:city];
    }
    
    if ([state rangeOfCharacterFromSet:set].location != NSNotFound) {
        state = [self removeIllegalCharactersFromString:state];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    NSString *today = [formatter stringFromDate:[NSDate date]];
    NSLog(@"%@",today);
    
    NSString *urlString1 = @"https://api.foursquare.com/v2/venues/search?near=";
    NSString *urlString2 = @"&categoryId=4d4b7105d754a06376d81259&limit=100&client_id=VLMUFMIAUWTTEVXXFQEQNKFDMCOFYEHTZU1U53IPQCI1PONX&client_secret=RH1CZUW0WWVM5LIEGZNFLU133YZX1ZMESAJ4PWNSDDSFMGYS&v=";
    
    NSString *joinString=[NSString stringWithFormat:@"%@%@%@%@%@%@",urlString1, city,@"%20",state,urlString2, today];
    joinString = [joinString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:joinString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        [self process:jsonDict];
        [Flurry logEvent:@"Foursquare_Loading_Places"];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error loading places %@ %@", error, [error userInfo]);
    }];
    [operation start];
}

-(NSString*)removeIllegalCharactersFromString:(NSString*)string {
    NSData *asciiEncoded = [string dataUsingEncoding:NSASCIIStringEncoding
                             allowLossyConversion:YES];
    
    // take the data object and recreate a string using the lossy conversion
    NSString *other = [[NSString alloc] initWithData:asciiEncoded
                                            encoding:NSASCIIStringEncoding];

    return other;
}

- (void)process:(NSDictionary *)json {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSDictionary *response = [json objectForKey:@"response"];
    NSArray *venues = [response objectForKey:@"venues"];
    for (NSDictionary *venue in venues) {
        Place *newPlace = [[Place alloc] init];
        newPlace.placeId = [venue objectForKey:@"id"];
        newPlace.name = [venue objectForKey:@"name"];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([(NSString*)[[venue objectForKey:@"location"] objectForKey:@"lat"] doubleValue], [[[venue objectForKey:@"location"] objectForKey:@"lng"] doubleValue]);
        newPlace.coord = location;
        newPlace.city = [self.userDetails objectForKey:@"city"];
        newPlace.state = [self.userDetails objectForKey:@"state"];
        NSDictionary *locationDetails = [venue objectForKey:@"location"];
        newPlace.address = [locationDetails objectForKey:@"address"];
        
        if (![sharedDataManager.foursquarePlacesDictionary objectForKey:newPlace.placeId]) {
            [sharedDataManager.foursquarePlacesDictionary setObject:newPlace forKey:newPlace.placeId];
        }
    }
    //TODO: save cityPlaceSearch
    if (self.friendStatusDetailsHaveLoaded) {
        [self addDictionaries];
        [self sortPlacesByPopularity];
    }
    NSLog(@"FINISHED LOADING FOURSQUARE DATA with %lu objects", (unsigned long)[sharedDataManager.foursquarePlacesDictionary count]);
    self.foursquarePlacesDataHasLoaded = YES;
    
    [self saveFoursquareSearch];
}

// Search foursquare data call
- (void)loadPlacesForSearch:(NSString*)search {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    NSString *today = [formatter stringFromDate:[NSDate date]];
    
    NSString *urlString1 = @"https://api.foursquare.com/v2/venues/search?near=";
    NSString *urlString2 = @"&query=";
    NSString *urlString3 = @"&limit=50&client_id=VLMUFMIAUWTTEVXXFQEQNKFDMCOFYEHTZU1U53IPQCI1PONX&client_secret=RH1CZUW0WWVM5LIEGZNFLU133YZX1ZMESAJ4PWNSDDSFMGYS&v=";
    NSString *joinString=[NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",urlString1,[self.userDetails objectForKey:@"city"] ,@"%20",[self.userDetails objectForKey:@"state"],urlString2, search, urlString3, today];
    joinString = [joinString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:joinString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        [self processSearchResults:jsonDict];
        [Flurry logEvent:@"Foursquare_User_Search"];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure");
        [self localSearchWithSearch:search];
    }];
    [operation start];
}

- (void)processSearchResults:(NSDictionary *)json {
    NSDictionary *response = [json objectForKey:@"response"];
    self.searchResultsArray = [[NSMutableArray alloc] init];
    NSArray *venues = [response objectForKey:@"venues"];
    for (NSDictionary *venue in venues) {
        Place *newPlace = [[Place alloc] init];
        newPlace.placeId = [venue objectForKey:@"id"];
        newPlace.name = [venue objectForKey:@"name"];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([(NSString*)[[venue objectForKey:@"location"] objectForKey:@"lat"] doubleValue], [[[venue objectForKey:@"location"] objectForKey:@"lng"] doubleValue]);
        newPlace.coord = location;
        newPlace.city = [self.userDetails objectForKey:@"city"];
        newPlace.state = [self.userDetails objectForKey:@"state"];
        NSDictionary *locationDetails = [venue objectForKey:@"location"];
        newPlace.address = [locationDetails objectForKey:@"address"];
        
        [self.searchResultsArray addObject:newPlace];
    }
    [self.searchResultsTableView reloadData];
}

-(void)localSearchWithSearch:(NSString*)search {
    self.searchResultsArray = [[NSMutableArray alloc] init];
    for (Place *place in self.placesArray) {
        if (place.name ) {
            if ([[place.name lowercaseString] rangeOfString:[search lowercaseString]].location != NSNotFound) {
                [self.searchResultsArray addObject:place];
            }
        }
    }
    
    [self.searchResultsTableView reloadData];
}

- (void)tutorialTapped:(UIGestureRecognizer*)recognizer {
    [self closeTutorial];
}

-(void)closeTutorial {
    [self.userDetails setBool:YES forKey:kUserDefaultsHasSeenTethrTutorialKey];
    [self.userDetails synchronize];
    [self.placesTableView reloadData];
}

#pragma mark UITableViewDataSource Methods

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.placesTableView && ![self.userDetails boolForKey:kUserDefaultsHasSeenTethrTutorialKey]) {
        return HEADER_HEIGHT;
    }
    return 0.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *tutorialView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 50.0)];
    [tutorialView setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.text = @"Tap a location to see who is going";
    UIFont *montserratLabelFont = [UIFont fontWithName:@"Montserrat" size:13];
    headerLabel.font = montserratLabelFont;
    [headerLabel setTextColor:UIColorFromRGB(0x8e0528)];
    CGSize size = [headerLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLabelFont}];
    headerLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, (50.0 - size.height) / 2.0, size.width, size.height);
    [tutorialView addSubview:headerLabel];
    
    tutorialView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tutorialTapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tutorialTapped:)];
    [tutorialView addGestureRecognizer:tutorialTapGesture];
    
    return tutorialView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.placesTableView) {
        return CELL_HEIGHT;
    } else {
        return SEARCH_RESULTS_CELL_HEIGHT;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.placesTableView) {
        return [self.placesArray count];
    } else {
        return [self.searchResultsArray count] + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.placesTableView) {
        PlaceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (!cell) {
            cell = [[PlaceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
            cell.delegate = self;
            cell.cellIndexPath = indexPath;
        }
        
        Place *place = [self.placesArray objectAtIndex:indexPath.row];
        [cell setPlace:place];
        
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if (sharedDataManager.currentCommitmentPlace && [place.placeId isEqualToString:sharedDataManager.currentCommitmentPlace.placeId]) {
            [cell setTethered:YES];
        }
        
        return cell;
    } else {
        if (indexPath.row == [self.searchResultsArray count]) {
             UIImageView *foursquareImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"poweredByFoursquare"]];
            foursquareImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, SEARCH_RESULTS_CELL_HEIGHT);
            foursquareImageView.contentMode = UIViewContentModeScaleAspectFit;
            UITableViewCell *cell = [[UITableViewCell alloc] init];
            [cell addSubview:foursquareImageView];
            return cell;
        }
        SearchResultCell *cell = [[SearchResultCell alloc] init];
        Place *p = [self.searchResultsArray objectAtIndex:indexPath.row];
        cell.place = p;
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:18];
        UIFont *montserratSubLabelFont = [UIFont fontWithName:@"Montserrat" size:12];
        UILabel *placeNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20.0)];
        placeNameLabel.text = p.name;
        placeNameLabel.font = montserrat;
        [cell addSubview:placeNameLabel];
        UILabel *placeAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30.0, self.view.frame.size.width, 15.0)];
        placeAddressLabel.text = p.address;
        placeAddressLabel.font = montserratSubLabelFont;
        [cell addSubview:placeAddressLabel];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchResultsTableView ) {
        if (indexPath.row >= [self.searchResultsArray count]) {
            return;
        }
        SearchResultCell *cell = (SearchResultCell*)[tableView cellForRowAtIndexPath:indexPath];
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if (![sharedDataManager.foursquarePlacesDictionary objectForKey:cell.place.placeId]) {
            [sharedDataManager.foursquarePlacesDictionary setObject:cell.place forKey:cell.place.placeId];
            [self addDictionaries];
            [self sortPlacesByPopularity];
        }
        [self scrollToPlaceWithId:cell.place.placeId];
        [self searchBarCancelButtonClicked:self.searchBar];
    } else {
        if (!self.friendsListViewController) {
            PlaceCell *cell = (PlaceCell*)[tableView cellForRowAtIndexPath:indexPath];
            [self showFriendsViewFromCell:cell];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
        if (![userDetails boolForKey:kUserDefaultsHasSeenTethrTutorialKey]) {
            [userDetails setBool:YES forKey:kUserDefaultsHasSeenTethrTutorialKey];
            [userDetails synchronize];
            [self.placesTableView reloadData];
        }
    }
    
    return;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
