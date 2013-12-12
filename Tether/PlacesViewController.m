//
//  PlacesViewController.m
//  Tether
//
//  Created by Laura Smith on 11/29/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "Friend.h"
#import "FriendsListViewController.h"
#import "Place.h"
#import "PlaceCell.h"
#import "PlacesViewController.h"
#import "SearchResultCell.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <Parse/Parse.h>

#define BOTTOM_BAR_HEIGHT 60.0
#define CELL_HEIGHT 100.0
#define SEARCH_RESULTS_CELL_HEIGHT 60.0
#define SEARCH_BAR_HEIGHT 60.0

@interface PlacesViewController () <PlaceCellDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic, strong) NSMutableArray *placesArray;
@property (nonatomic, strong) UITableViewController *placesTableViewController;
@property (retain, nonatomic) UIView * bottomBar;
@property (retain, nonatomic) UILabel * bottomBarLabel;
@property (retain, nonatomic) UIButton *bottomLeftButton;
@property (retain, nonatomic) UIButton * bottomRightButton;
@property (retain, nonatomic) NSUserDefaults *userDetails;
@property (assign, nonatomic) bool friendStatusDetailsHaveLoaded;
@property (assign, nonatomic) bool foursquarePlacesDataHasLoaded;
@property (retain, nonatomic) NSIndexPath *previousCommitmentCellIndexPath;
@property (retain, nonatomic) UISearchBar *searchBar;
@property (retain, nonatomic) NSMutableArray *searchResultsArray;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UITableViewController *searchResultsTableViewController;

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
    
    // set up search bar and corresponding search results tableview
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, SEARCH_BAR_HEIGHT)];
    self.searchBar.delegate = self;
    [self.view addSubview:self.searchBar];
    
    self.searchResultsArray = [[NSMutableArray alloc] init];
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - BOTTOM_BAR_HEIGHT)];
    self.searchResultsTableView.hidden = YES;
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    [self.searchResultsTableView reloadData];
    
    //set up friends going out table view
    self.placesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - BOTTOM_BAR_HEIGHT)];
    [self.placesTableView setSeparatorColor:[UIColor whiteColor]];
    [self.placesTableView setBackgroundColor:UIColorFromRGB(0xD6D6D6)];
    [self.placesTableView setDataSource:self];
    [self.placesTableView setDelegate:self];
    self.placesTableView.showsVerticalScrollIndicator = NO;
    
    [self.view addSubview:self.placesTableView];
    [self.view addSubview:self.searchResultsTableView];
    
    self.placesTableViewController = [[UITableViewController alloc] init];
    self.placesTableViewController.tableView = self.placesTableView;
    
    // bottom nav bar setup
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT)];
    self.bottomBar.layer.masksToBounds = NO;
    self.bottomBar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bottomBar.layer.shadowOffset = CGSizeMake(0.0f, 2.0f);
    self.bottomBar.layer.shadowOpacity = 0.5f;
    
    UIImage *shadowImage = [[UIImage imageNamed:@"ListIcon.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0)
                            resizingMode:UIImageResizingModeStretch];
    UIImageView *shadowImageView = [[UIImageView alloc] initWithImage:shadowImage];
    shadowImageView.frame = CGRectMake(-62.0, self.view.frame.size.height - 80.0, 442, 120.0);
    [self.view addSubview:shadowImageView];
    
    // left panel view button setup
    UIImage *leftPanelButtonImage = [UIImage imageNamed:@"chevron-left"];
    self.bottomLeftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 10, 30, 30)];
    [self.bottomLeftButton setImage:leftPanelButtonImage forState:UIControlStateNormal];
    [self.bottomBar addSubview:self.bottomLeftButton];
    self.bottomLeftButton.tag = 1;
    [self.bottomLeftButton addTarget:self action:@selector(closeListView) forControlEvents:UIControlEventTouchDown];
    
    // Tether label setup
    self.bottomBarLabel = [[UILabel alloc] init];
    self.bottomBarLabel.text = @"T  E  T  H  E  R";
    CGRect frame = self.bottomBarLabel.frame;
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
}

-(void)getFriendsCommitments {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSMutableArray *friendsArrayWithMe = [[NSMutableArray alloc] initWithArray:sharedDataManager.facebookFriends];

    if  (sharedDataManager.facebookId && !self.friendStatusDetailsHaveLoaded) {
        [friendsArrayWithMe addObject:sharedDataManager.facebookId];
    }
    
    NSString *userCity;
    NSString *userState = [[NSString alloc] init];
    userCity = [self.userDetails objectForKey:@"city"];
    userState = [self.userDetails objectForKey:@"state"];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Commitment"];
    [query whereKey:@"facebookId" containedIn:friendsArrayWithMe];
    [query whereKey:@"placeCityName" equalTo:userCity];
    query.limit = 1000; // is this an appropriate limit?
    //TODO: Check for same State
    
    NSDate *startTime = [self getStartTime];

    //TODO: more than 100 objects?
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSLog(@"QUERY: finding friends commitments for tonight");
            // The find succeeded. The first 100 objects are available in objects
            NSLog(@"Commitments found: %lu",(unsigned long)[objects count]);
            PFGeoPoint *geoPoint;
            NSMutableDictionary *tempDictionary = [[NSMutableDictionary alloc] init];
            for (PFObject *object in objects) {
                Place *place = [[Place alloc] init];
                geoPoint = [object objectForKey:@"placePoint"];
                id friendID =[object objectForKey:@"facebookId"];
                if (![tempDictionary objectForKey:[object objectForKey:@"placeId"]]) {
                    place.city = [object objectForKey:@"placeCityName"];
                    place.name = [object objectForKey:@"placeName"];
                    place.address = [object objectForKey:@"address"];
                    place.coord = CLLocationCoordinate2DMake(geoPoint.latitude, geoPoint.longitude);
                    place.placeId = [object objectForKey:@"placeId"];
                    place.numberCommitments = 0;
                    place.numberPastCommitments = 0;
                    place.friendsCommitted = [[NSMutableArray alloc] init];
                    NSLog(@"Created place: %@", [object objectForKey:@"placeName"]);
                } else {
                    place = [tempDictionary objectForKey:[object objectForKey:@"placeId"]];
                    NSLog(@"Updated place %@", [object objectForKey:@"placeName"]);
                }
                
                NSDate *commitmentTime = [object objectForKey:@"dateCommitted"];
                if (commitmentTime != nil && [startTime compare:commitmentTime] == NSOrderedAscending) {
                    // commitment for tonight
                    [place.friendsCommitted addObject:[object objectForKey:@"facebookId"]];
                    place.numberCommitments = place.numberCommitments + 1;
                    if ([sharedDataManager.facebookId isEqualToString:friendID]) {
                        NSLog(@"Setting your current commitment to %@", place.name);
                        sharedDataManager.currentCommitmentPlace = place;
                        sharedDataManager.currentCommitmentParseObject = object;
                    }
                    if ([self.delegate respondsToSelector:@selector(setPlace:forFriend:)]) {
                        [self.delegate setPlace:place.placeId forFriend:friendID];
                    }
                } else {
                    place.numberPastCommitments = place.numberPastCommitments + 1;
                }

                [tempDictionary setObject:place forKey:[object objectForKey:@"placeId"]];
            }
            
            if (self.friendStatusDetailsHaveLoaded) {
                if (sharedDataManager.currentCommitmentPlace.placeId && [sharedDataManager.currentCommitmentPlace.city isEqualToString:userCity]) {
                    Place *p = [tempDictionary objectForKey:sharedDataManager.currentCommitmentPlace.placeId];
                    if (p) {
                        [p.friendsCommitted addObject:sharedDataManager.facebookId];
                        p.numberCommitments +=1;
                        [tempDictionary setObject:p forKey:p.placeId];
                    } else {
                        [tempDictionary setObject:sharedDataManager.currentCommitmentPlace forKey:sharedDataManager.currentCommitmentPlace.placeId];
                    }
                }
            }
            
            NSArray *tempKeys = [tempDictionary allKeys];
            NSArray *keys = [sharedDataManager.popularPlacesDictionary allKeys];
            NSSet *tempKeySet = [NSSet setWithArray:tempKeys];
            NSSet *keySet = [NSSet setWithArray:keys];
            // check if commitments have changed, if so update map
            if (![tempKeySet isEqualToSet:keySet]) {
                NSLog(@"Updated your friends commitments");
                sharedDataManager.popularPlacesDictionary = tempDictionary;
                [self addPinsToMap];
            }
            
            if (self.foursquarePlacesDataHasLoaded) {
                if (![tempKeySet isEqualToSet:keySet]) {
                    [self addDictionaries];
                    [self sortPlacesByPopularity];
                }
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

-(void)addDictionaries {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    sharedDataManager.placesDictionary = [[NSMutableDictionary alloc] init];
    for (id key in sharedDataManager.popularPlacesDictionary) {
        Place *place = [sharedDataManager.popularPlacesDictionary objectForKey:key];
        
        if ([sharedDataManager.foursquarePlacesDictionary objectForKey:key]) {
            Place *tempPlace = [sharedDataManager.foursquarePlacesDictionary objectForKey:key];
            [place.friendsCommitted addObjectsFromArray:tempPlace.friendsCommitted];
            place.numberCommitments += tempPlace.numberCommitments;
        }
        [sharedDataManager.placesDictionary setObject:place forKey:place.placeId];
    }
    
    for (id key in sharedDataManager.foursquarePlacesDictionary) {
        if (![sharedDataManager.placesDictionary objectForKey:key]) {
            Place *place = [sharedDataManager.foursquarePlacesDictionary objectForKey:key];
            [sharedDataManager.placesDictionary setObject:place forKey:place.placeId];
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
    if ([self.delegate respondsToSelector:@selector(closeListView)]) {
        [self.delegate closeListView];
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

-(void)scrollToPlaceWithId:(id)placeId {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    Place *place = [sharedDataManager.placesDictionary objectForKey:placeId];
    
    [self.placesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.placesArray indexOfObject:place] inSection:0]
                                atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

#pragma mark PlaceCellDelegate Methods

-(void)commitToPlace:(Place*)place fromCell:(PlaceCell *)cell {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if ([self.delegate respondsToSelector:@selector(commitToPlace:)]) {

        Place *p = [sharedDataManager.placesDictionary objectForKey:place.placeId];
        if (p) {
            NSMutableArray *friendsCommitted;
            if (p.friendsCommitted) {
                friendsCommitted = [NSMutableArray arrayWithArray:p.friendsCommitted];
            } else {
                friendsCommitted = [[NSMutableArray alloc] init];
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
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentPlace) {
        NSLog(@"Removing previous commitment to %@", sharedDataManager.currentCommitmentPlace.name);
        if ([sharedDataManager.currentCommitmentPlace.friendsCommitted containsObject:sharedDataManager.facebookId]) {
            NSUInteger index = [sharedDataManager.currentCommitmentPlace.friendsCommitted indexOfObject:sharedDataManager.facebookId];
            [sharedDataManager.currentCommitmentPlace.friendsCommitted removeObjectAtIndex:index];
            sharedDataManager.currentCommitmentPlace.numberCommitments -=1;
            [sharedDataManager.placesDictionary setObject:sharedDataManager.currentCommitmentPlace
                                                   forKey:sharedDataManager.currentCommitmentPlace.placeId];
            [sharedDataManager.popularPlacesDictionary removeObjectForKey:sharedDataManager.currentCommitmentPlace.placeId];
            if ([self.delegate respondsToSelector:@selector(placeMarkOnMapView:)]) {
                [self.delegate placeMarkOnMapView:sharedDataManager.currentCommitmentPlace];
            }
        }
        sharedDataManager.currentCommitmentPlace = nil;
    }
}

-(void)removeCommitmentFromDatabase {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentParseObject) {
        [sharedDataManager.currentCommitmentParseObject deleteInBackground];
        NSLog(@"PARSE DELETE: Removed previous commitment from database");
        sharedDataManager.currentCommitmentParseObject = nil;
    }
}

-(void)showFriendsView {
//    Place *place = [self.placesArray objectAtIndex:0];
//    Datastore *sharedDataManager = [Datastore sharedDataManager];
//    if ([place.friendsCommitted count] > 0) {
//        FriendsListViewController *friendsListViewController = [[FriendsListViewController alloc] init];
//        NSMutableArray *friends = [[NSMutableArray alloc] init];
//        for (id friendId in place.friendsCommitted) {
//            if ([sharedDataManager.tetherFriendsDictionary objectForKey:friendId]) {
//                Friend *friend = [sharedDataManager.tetherFriendsDictionary objectForKey:friendId];
//                [friends addObject:friend];
//            }
//        }
//        friendsListViewController.friendsArray = friends;
//        [self.view addSubview:friendsListViewController.view];
//    }
}

-(void)unhighlightCellWithCellIndex:(NSIndexPath*)cellIndex {
    //indicate in list view that you are no longer tethered to the previous location
    PlaceCell *cell = (PlaceCell*)[self.placesTableView cellForRowAtIndexPath:cellIndex];
    [cell setTethered:NO];
}

#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:YES animated:YES];
    self.searchResultsTableView.hidden = NO;
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
    NSLog(@"FINISHED LOADING FOURSQUARE DATA FOR SEARCH");
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
        return [self.searchResultsArray count];
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
        if (sharedDataManager.currentCommitmentPlace && place.placeId == sharedDataManager.currentCommitmentPlace.placeId) {
            [cell setTethered:YES];
            self.previousCommitmentCellIndexPath = indexPath;
        }
        return cell;
    } else {
        SearchResultCell *cell = [[SearchResultCell alloc] init];
        Place *p = [self.searchResultsArray objectAtIndex:indexPath.row];
        cell.place = p;
        UILabel *placeNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
        placeNameLabel.text = p.name;
        [cell addSubview:placeNameLabel];
        
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
    }
    
    return;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
