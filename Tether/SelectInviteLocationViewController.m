//
//  SelectInviteLocationViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-05-02.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#define SEARCH_BAR_HEIGHT 50.0
#define SEARCH_RESULTS_CELL_HEIGHT 60.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

#import "CenterViewController.h"
#import "Datastore.h"
#import "Flurry.h"
#import "SearchResultCell.h"
#import "SelectInviteLocationViewController.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>

@interface SelectInviteLocationViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UIButton *cancelButton;
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UILabel * topBarLabel;
@property (retain, nonatomic) UISearchBar * searchBar;
@property (retain, nonatomic) NSMutableArray *placeSearchResultsArray;
@property (nonatomic, strong) UITableView *placeSearchResultsTableView;
@property (nonatomic, strong) UITableViewController *placeSearchResultsTableViewController;

@end

@implementation SelectInviteLocationViewController

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
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // top bar setup
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, self.view.frame.size.width,TOP_BAR_HEIGHT)];
    self.topBar.layer.backgroundColor = UIColorFromRGB(0x8e0528).CGColor;
    [self.view addSubview:self.topBar];
    
    self.topBarLabel = [[UILabel alloc] init];
    self.topBarLabel.text = @"Choose a Location";
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
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, SEARCH_BAR_HEIGHT)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search locations...";
    self.searchBar.barTintColor = UIColorFromRGB(0xc8c8c8);
    [self.searchBar becomeFirstResponder];
    [self.view addSubview:self.searchBar];
    
    self.placeSearchResultsArray = [[NSMutableArray alloc] init];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    NSString *currentTethrKey = @"";
    currentTethrKey = sharedDataManager.currentCommitmentPlace.placeId;
    for (id key in sharedDataManager.placesDictionary) {
        if (![currentTethrKey isEqualToString:key]) {
            Place *place = [sharedDataManager.placesDictionary objectForKey:key];
            [self.placeSearchResultsArray addObject:place];
        }
    }
    
    if (currentTethrKey) {
        [self.placeSearchResultsArray insertObject:sharedDataManager.currentCommitmentPlace atIndex:0];
    }
    
    self.placeSearchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT + self.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT - self.searchBar.frame.size.height)];
    [self.placeSearchResultsTableView setDataSource:self];
    [self.placeSearchResultsTableView setDelegate:self];
    
    self.placeSearchResultsTableViewController = [[UITableViewController alloc] init];
    self.placeSearchResultsTableViewController.tableView = self.placeSearchResultsTableView;
    [self.placeSearchResultsTableView reloadData];
    
    [self.view addSubview:self.placeSearchResultsTableView];
}

#pragma mark IBAction handlers

-(IBAction)closeView:(id)sender {
    if ([self.delegate respondsToSelector:@selector(closeSelectInviteLocationView)]) {
        [self.delegate closeSelectInviteLocationView];
    }
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SEARCH_RESULTS_CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.placeSearchResultsArray count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchResultCell *cell = (SearchResultCell*)[tableView cellForRowAtIndexPath:indexPath];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (![sharedDataManager.foursquarePlacesDictionary objectForKey:cell.place.placeId]) {
        [sharedDataManager.foursquarePlacesDictionary setObject:cell.place forKey:cell.place.placeId];
    }
    
    // send invite in current message thread
    if ([self.delegate respondsToSelector:@selector(inviteToPlace:)]) {
        [self.delegate inviteToPlace:cell.place];
    }
    
    if ([self.delegate respondsToSelector:@selector(closeSelectInviteLocationView)]) {
        [self.delegate closeSelectInviteLocationView];
    }
    
}

#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar becomeFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text=@"";
    self.placeSearchResultsArray = nil;
    [self.placeSearchResultsTableView reloadData];
    self.placeSearchResultsTableView.hidden = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self loadPlacesForSearch:searchBar.text];
}

// Search foursquare data call
- (void)loadPlacesForSearch:(NSString*)search {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    NSString *today = [formatter stringFromDate:[NSDate date]];
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSString *urlString1 = @"https://api.foursquare.com/v2/venues/search?near=";
    NSString *urlString2 = @"&query=";
    NSString *urlString3 = @"&limit=50&client_id=VLMUFMIAUWTTEVXXFQEQNKFDMCOFYEHTZU1U53IPQCI1PONX&client_secret=RH1CZUW0WWVM5LIEGZNFLU133YZX1ZMESAJ4PWNSDDSFMGYS&v=";
    NSString *joinString=[NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",urlString1,[userDetails objectForKey:@"city"] ,@"%20",[userDetails objectForKey:@"state"],urlString2, search, urlString3, today];
    joinString = [joinString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:joinString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        [self processSearchResults:jsonDict];
        [Flurry logEvent:@"Foursquare_User_Search_Invite"];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
