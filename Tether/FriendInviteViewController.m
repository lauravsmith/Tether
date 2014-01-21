//
//  FriendInviteViewController.m
//  Tether
//
//  Created by Laura Smith on 1/16/2014.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Datastore.h"
#import "FriendInviteViewController.h"
#import "SearchResultCell.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>

#define LEFT_PADDING 40.0
#define SEARCH_BAR_HEIGHT 40.0
#define SEARCH_BAR_WIDTH 280.0
#define SEARCH_RESULTS_CELL_HEIGHT 60.0
#define STATUS_BAR_HEIGHT 20.0

@interface FriendInviteViewController () <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>
@property (retain, nonatomic) UISearchBar *placeSearchBar;
@property (retain, nonatomic) NSMutableArray *placeSearchResultsArray;
@property (nonatomic, strong) UITableView *placeSearchResultsTableView;
@property (nonatomic, strong) UITableViewController *placeSearchResultsTableViewController;
@end

@implementation FriendInviteViewController

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
	// Do any additional setup after loading the view.
    [self.searchBar setHidden:YES];
    CGRect frame = self.searchBarBackgroundView.frame;
    frame.size.height = 0.0;
    self.searchBarBackgroundView.frame = frame;
    
    self.placeSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake((self.topBarView.frame.size.width - SEARCH_BAR_WIDTH) / 2.0, (self.topBarView.frame.size.height - SEARCH_BAR_HEIGHT) / 2.0 + 5.0, SEARCH_BAR_WIDTH, SEARCH_BAR_HEIGHT)];
    self.placeSearchBar.delegate = self;
    self.placeSearchBar.placeholder = @"Search places...";
    [self.placeSearchBar setBackgroundImage:[UIImage new]];
    [self.placeSearchBar setTranslucent:YES];
    [self.view addSubview:self.placeSearchBar];
    
    self.placeSearchResultsArray = [[NSMutableArray alloc] init];
    
    self.placeSearchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, self.topBarView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.placeSearchBar.frame.size.height)];
    self.placeSearchResultsTableView.hidden = YES;
    [self.placeSearchResultsTableView setDataSource:self];
    [self.placeSearchResultsTableView setDelegate:self];
    
    self.placeSearchResultsTableViewController = [[UITableViewController alloc] init];
    self.placeSearchResultsTableViewController.tableView = self.placeSearchResultsTableView;
    [self.placeSearchResultsTableView reloadData];
    
    [self.view addSubview:self.placeSearchResultsTableView];
}

-(void)setDestination:(Place*)place {
    self.place = place;
    self.placeLabel.text = place.name;
    [self.placeSearchBar setHidden:YES];
    
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:16.0f];
    self.placeLabel.font = montserratLarge;
    CGSize size = [self.placeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratLarge}];
    self.placeLabel.frame = CGRectMake(LEFT_PADDING, STATUS_BAR_HEIGHT, MIN(self.view.frame.size.width - LEFT_PADDING, size.width), size.height);
    
    self.searchBar.placeholder = @"Invite more friends...";
    [self.searchBar setHidden:NO];
    CGRect frame = self.searchBarBackgroundView.frame;
    frame.size.height = SEARCH_BAR_HEIGHT;
    self.searchBarBackgroundView.frame = frame;
    
    [self layoutFriendsInvitedView];
}

#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (searchBar == self.placeSearchBar) {
        [self.placeSearchBar setShowsCancelButton:YES animated:YES];
    } else {
        [super searchBarTextDidBeginEditing:searchBar];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if (searchBar == self.placeSearchBar) {
        searchBar.text=@"";
        
        [searchBar setShowsCancelButton:NO animated:YES];
        [searchBar resignFirstResponder];
        
        self.placeSearchResultsArray = nil;
        [self.placeSearchResultsTableView reloadData];
        self.placeSearchResultsTableView.hidden = YES;
    } else {
        [super searchBarCancelButtonClicked:searchBar];
    }
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchBar == self.placeSearchBar) {
        self.placeSearchResultsTableView.hidden = NO;
        [self loadPlacesForSearch:searchBar.text];
    } else {
        [super searchBar:searchBar textDidChange:searchText];
    }
}

// Search foursquare data call
- (void)loadPlacesForSearch:(NSString*)search {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSString *urlString1 = @"https://api.foursquare.com/v2/venues/search?near=";
    NSString *urlString2 = @"&query=";
    NSString *urlString3 = @"&limit=50&oauth_token=5IQQDYZZ0KJLYNQROEEFAEWR4V400IADTACODH2SYCVBNQ3P&v=20131113";
    NSString *joinString=[NSString stringWithFormat:@"%@%@%@%@%@%@%@",urlString1,[userDetails objectForKey:@"city"] ,@"%20",[userDetails objectForKey:@"state"],urlString2, search, urlString3];
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
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSDictionary *response = [json objectForKey:@"response"];
    self.placeSearchResultsArray = [[NSMutableArray alloc] init];
    NSArray *venues = [response objectForKey:@"venues"];
    for (NSDictionary *venue in venues) {
        Place *newPlace = [[Place alloc] init];
        newPlace.placeId = [venue objectForKey:@"id"];
        newPlace.name = [venue objectForKey:@"name"];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([(NSString*)[[venue objectForKey:@"location"] objectForKey:@"lat"] doubleValue], [[[venue objectForKey:@"location"] objectForKey:@"lng"] doubleValue]);
        newPlace.coord = location;
        newPlace.city = [userDetails objectForKey:@"city"];
        newPlace.state = [userDetails objectForKey:@"state"];
        NSDictionary *locationDetails = [venue objectForKey:@"location"];
        newPlace.address = [locationDetails objectForKey:@"address"];
        
        [self.placeSearchResultsArray addObject:newPlace];
    }
    [self.placeSearchResultsTableView reloadData];
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.placeSearchResultsTableView) {
        return SEARCH_RESULTS_CELL_HEIGHT;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.placeSearchResultsTableView) {
        return [self.placeSearchResultsArray count] + 1;
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.placeSearchResultsTableView) {
        if (indexPath.row == [self.placeSearchResultsArray count]) {
            UIImageView *foursquareImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"poweredByFoursquare"]];
            foursquareImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, SEARCH_RESULTS_CELL_HEIGHT);
            foursquareImageView.contentMode = UIViewContentModeScaleAspectFit;
            UITableViewCell *cell = [[UITableViewCell alloc] init];
            [cell addSubview:foursquareImageView];
            return cell;
        }
        SearchResultCell *cell = [[SearchResultCell alloc] init];
        Place *p = [self.placeSearchResultsArray objectAtIndex:indexPath.row];
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
    } else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView ==  self.placeSearchResultsTableView) {
        SearchResultCell *cell = (SearchResultCell*)[tableView cellForRowAtIndexPath:indexPath];
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if (![sharedDataManager.foursquarePlacesDictionary objectForKey:cell.place.placeId]) {
            [sharedDataManager.foursquarePlacesDictionary setObject:cell.place forKey:cell.place.placeId];
        }
        [self searchBarCancelButtonClicked:self.placeSearchBar];
        [self setDestination:cell.place];
    } else {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
