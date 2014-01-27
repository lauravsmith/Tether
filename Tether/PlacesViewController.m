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
#define SEARCH_RESULTS_CELL_HEIGHT 60.0
#define SEARCH_BAR_HEIGHT 50.0
#define SEARCH_BAR_WIDTH 270.0
#define STATUS_BAR_HEIGHT 20.0
#define SLIDE_TIMING 0.6

@interface PlacesViewController () <InviteViewControllerDelegate, FriendsListViewControllerDelegate, PlaceCellDelegate, UIGestureRecognizerDelegate,UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *placesArray;
@property (nonatomic, strong) UITableViewController *placesTableViewController;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UIButton *backButtonLarge;
@property (retain, nonatomic) NSUserDefaults *userDetails;
@property (assign, nonatomic) bool friendStatusDetailsHaveLoaded;
@property (assign, nonatomic) bool foursquarePlacesDataHasLoaded;
@property (retain, nonatomic) NSIndexPath *previousCommitmentCellIndexPath;
@property (retain, nonatomic) UISearchBar *searchBar;
@property (retain, nonatomic) NSMutableArray *searchResultsArray;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UITableViewController *searchResultsTableViewController;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (assign, nonatomic) bool openingInviteView;

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
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = UIColorFromRGB(0x8e0528);
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.placesTableViewController.refreshControl = self.refreshControl;
    
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, (SEARCH_BAR_HEIGHT + STATUS_BAR_HEIGHT + 7.0) / 2.0, 10.0, 10.0)];
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
    [query whereKey:kCommitmentCityKey equalTo:userCity];
    [query whereKey:kCommitmentDateKey greaterThan:lastWeek];
    query.limit = 5000; // is this an appropriate limit?
    //TODO: Check for same State
    
    NSDate *startTime = [self getStartTime];

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"QUERY: finding friends commitments for tonight");
            // The find succeeded. The first 100 objects are available in objects
            NSLog(@"Commitments found: %lu",(unsigned long)[objects count]);
            PFGeoPoint *geoPoint;
            NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];

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
                    NSLog(@"Created place: %@", [object objectForKey:kCommitmentPlaceKey]);
                } else {
                    place = [tempDictionary objectForKey:[object objectForKey:kCommitmentPlaceIDKey]];
                    NSLog(@"Updated place %@", [object objectForKey:kCommitmentPlaceKey]);
                }
                
                NSDate *commitmentTime = [object objectForKey:kCommitmentDateKey];
                if (commitmentTime != nil && [startTime compare:commitmentTime] == NSOrderedAscending) {
                    // commitment for tonight
                    [place.friendsCommitted addObject:[object objectForKey:kUserFacebookIDKey]];
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
                } else {
                    place.numberPastCommitments = place.numberPastCommitments + 1;
                }

                [tempDictionary setObject:place forKey:[object objectForKey:kCommitmentPlaceIDKey]];
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

            NSLog(@"Updated your friends commitments");
            sharedDataManager.popularPlacesDictionary = tempDictionary;
            
            if (self.foursquarePlacesDataHasLoaded) {
                    [self addDictionaries];
                    [self sortPlacesByPopularity];
            }

            self.friendStatusDetailsHaveLoaded = YES;
        } else {
            // Log details of the failure
            NSLog(@"Error Querying friends commitments: %@ %@", error, [error userInfo]);
            if (self.foursquarePlacesDataHasLoaded) {
                [self addDictionaries];
                [self sortPlacesByPopularity];
            }
        }
    }];
    if (!self.foursquarePlacesDataHasLoaded) {
        [self loadPlaces];
    }
    }
}

-(void)addDictionaries {
    NSLog(@"Adding dictionaries");
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
}

-(void)sortPlacesByPopularity {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [self.placesArray removeAllObjects];
    NSLog(@"Sorting places");
    for(id key in sharedDataManager.placesDictionary) {
        [self.placesArray addObject:[sharedDataManager.placesDictionary objectForKey:key]];
    }
    
    // Sort places first by tonights popularity, then past popularity
    NSSortDescriptor *numberCommitmentsDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"numberCommitments" ascending:NO];
    NSSortDescriptor *numberPastCommitmentsDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"numberPastCommitments" ascending:NO];
    [self.placesArray sortUsingDescriptors:[NSArray arrayWithObjects:numberCommitmentsDescriptor, numberPastCommitmentsDescriptor, nil]];
    [self.placesTableView reloadData];
}

-(void)addPinsToMap {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    for (id key in sharedDataManager.popularPlacesDictionary) {
        Place *p = [sharedDataManager.popularPlacesDictionary objectForKey:key];
        if (p) {
            if ([p.friendsCommitted count] > 0) {
                NSLog(@"PLACES VIEW: Adding %@ with %d commitments to map", p.name, p.numberCommitments);
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
}

-(void)openPageForPlaceWithId:(id)placeId {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    Place *place = [sharedDataManager.placesDictionary objectForKey:placeId];
    if (place.numberCommitments > 0) {
        if (place.numberCommitments == 1 && [place.friendsCommitted containsObject:sharedDataManager.facebookId]) {
            return;
        } else {
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
        if(velocity.x > 0) {
            [self closeListView];
        }
    }
}

#pragma mark PlaceCellDelegate Methods

-(void)commitToPlace:(Place*)place fromCell:(PlaceCell *)cell {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if ([self.delegate respondsToSelector:@selector(commitToPlace:)]) {

        Place *p = [sharedDataManager.placesDictionary objectForKey:place.placeId];
        if (p) {
            NSMutableSet *friendsCommitted;
            if (p.friendsCommitted) {
                friendsCommitted = [[NSMutableSet alloc] init];
                friendsCommitted = p.friendsCommitted;
            } else {
                friendsCommitted = [[NSMutableSet alloc] init];
            }
            
            NSString *myID = sharedDataManager.facebookId;
            [friendsCommitted addObject:myID];
            p.friendsCommitted = friendsCommitted;
            if (p.numberCommitments) {
                p.numberCommitments += 1;
            } else {
                p.numberCommitments = 1;
            }
            [sharedDataManager.placesDictionary setObject:p forKey:place.placeId];
            [sharedDataManager.popularPlacesDictionary setObject:p forKey:place.placeId];
            
            [self.delegate commitToPlace:place];
        }
    }
    
    // remove "tethered" from previous place committed in tableview
    if (self.previousCommitmentCellIndexPath) {
        [self unhighlightCellWithCellIndex:self.previousCommitmentCellIndexPath];
    }
    self.previousCommitmentCellIndexPath = [self.placesTableView indexPathForCell:cell];
    
    if (sharedDataManager.currentCommitmentPlace) {
            NSLog(@"PLACE VIEW: previous commitment %@", sharedDataManager.currentCommitmentPlace.name);
            [self removePreviousCommitment];
    }
    sharedDataManager.currentCommitmentPlace = place;
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
    if ([self.delegate respondsToSelector:@selector(canUpdatePlaces:)]) {
        [self.delegate canUpdatePlaces:NO];
    }
    Place *place = placeCell.place;
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if ([place.friendsCommitted count] > 0) {
        FriendsListViewController *friendsListViewController = [[FriendsListViewController alloc] init];
        friendsListViewController.delegate = self;
        NSMutableSet *friends = [[NSMutableSet alloc] init];
        for (id friendId in place.friendsCommitted) {
            if ([sharedDataManager.tetherFriendsDictionary objectForKey:friendId]) {
                Friend *friend = [sharedDataManager.tetherFriendsDictionary objectForKey:friendId];
                [friends addObject:friend];
            }
        }
        friendsListViewController.friendsArray = [[friends allObjects] mutableCopy];
        friendsListViewController.place = placeCell.place;
        [friendsListViewController loadFriendsOfFriends];
        [friendsListViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:friendsListViewController.view];
        [self addChildViewController:friendsListViewController];
        [friendsListViewController didMoveToParentViewController:self];
        
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [friendsListViewController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
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

-(void)unhighlightCellWithCellIndex:(NSIndexPath*)cellIndex {
    //indicate in list view that you are no longer tethered to the previous location
    PlaceCell *cell = (PlaceCell*)[self.placesTableView cellForRowAtIndexPath:cellIndex];
    [cell setTethered:NO];
}

#pragma mark FriendsListViewControllerDelegate

-(void)commitToPlace:(Place *)place {
    if ([self.delegate respondsToSelector:@selector(commitToPlace:)]) {
        [self.delegate commitToPlace:place];
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
    [self loadPlacesForSearch:searchBar.text];
}

// Intial foursquare data call
- (void)loadPlaces {
    NSString *urlString1 = @"https://api.foursquare.com/v2/venues/search?near=";
    NSString *urlString2 = @"&categoryId=4d4b7105d754a06376d81259&limit=100&oauth_token=5IQQDYZZ0KJLYNQROEEFAEWR4V400IADTACODH2SYCVBNQ3P&v=20131113";
    NSString *joinString=[NSString stringWithFormat:@"%@%@%@%@%@",urlString1,[self.userDetails objectForKey:@"city"] ,@"%20",[self.userDetails objectForKey:@"state"],urlString2];
    joinString = [joinString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:joinString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        [self process:jsonDict];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure");
    }];
    [operation start];
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
    
    if (self.friendStatusDetailsHaveLoaded) {
        [self addDictionaries];
        [self sortPlacesByPopularity];
    }
    NSLog(@"FINISHED LOADING FOURSQUARE DATA with %d objects", [sharedDataManager.foursquarePlacesDictionary count]);
    self.foursquarePlacesDataHasLoaded = YES;
}

// Search foursquare data call
- (void)loadPlacesForSearch:(NSString*)search {
    NSString *urlString1 = @"https://api.foursquare.com/v2/venues/search?near=";
    NSString *urlString2 = @"&query=";
    NSString *urlString3 = @"&limit=50&oauth_token=5IQQDYZZ0KJLYNQROEEFAEWR4V400IADTACODH2SYCVBNQ3P&v=20131113";
    NSString *joinString=[NSString stringWithFormat:@"%@%@%@%@%@%@%@",urlString1,[self.userDetails objectForKey:@"city"] ,@"%20",[self.userDetails objectForKey:@"state"],urlString2, search, urlString3];
    joinString = [joinString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:joinString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        [self processSearchResults:jsonDict];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure");
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

#pragma mark UITableViewDataSource Methods

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
            self.previousCommitmentCellIndexPath = indexPath;
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
        PlaceCell *cell = (PlaceCell*)[tableView cellForRowAtIndexPath:indexPath];
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if ([cell.place.placeId isEqualToString:sharedDataManager.currentCommitmentPlace.placeId]) {
            [self removePreviousCommitment];
            [self removeCommitmentFromDatabase];
            [cell setTethered:NO];
            self.previousCommitmentCellIndexPath = nil;
        } else {
            [cell setTethered:YES];
            [self commitToPlace:cell.place fromCell:cell];
            self.previousCommitmentCellIndexPath = indexPath;
        }
        [cell layoutCommitButton];
        [cell setNeedsLayout];
         [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    return;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
