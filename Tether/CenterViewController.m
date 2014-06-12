//
//  CenterViewController.m
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "ActivityCell.h"
#import "AppDelegate.h"
#import "CenterViewController.h"
#import "CommentViewController.h"
#import "Constants.h"
#import "CreatePlaceViewController.h"
#import "Datastore.h"
#import "Flurry.h"
#import "ParticipantsListViewController.h"
#import "Place.h"
#import "SearchResultCell.h"
#import "TetherAnnotation.h"
#import "TetherAnnotationView.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <FacebookSDK/FacebookSDK.h>

#define BOTTOM_BAR_HEIGHT 45.0
#define CORNER_RADIUS 20.0
#define DISTANCE_FACE_TO_PIN 20.0
#define FACE_SIZE 40.0
#define MAX_FRIENDS_ON_PIN 15.0
#define NOTIFICATIONS_SIZE 32.0
#define PADDING 20.0
#define SEARCH_BAR_HEIGHT 45.0
#define SEARCH_BAR_WIDTH 270.0
#define SEARCH_RESULTS_CELL_HEIGHT 60.0
#define SLIDE_TIMING 0.6
#define SPINNER_SIZE 30.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0
#define TUTORIAL_HEADER_HEIGHT 50.0

#define degreesToRadian(x) (M_PI * (x) / 180.0)

@interface CenterViewController () <ActivityCellDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, CreatePlaceViewControllerDelegate, UIActionSheetDelegate, PartcipantsListViewControllerDelegate,CommentViewControllerDelegate>
@property (retain, nonatomic) NSString * cityLocation;
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UISearchBar *searchBar;
@property (retain, nonatomic) UISearchBar *feedSearchBar;
@property (retain, nonatomic) UISearchBar *popularSearchBar;
@property (retain, nonatomic) NSMutableArray *searchResultsArray;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UITableViewController *searchResultsTableViewController;
@property (assign, nonatomic) bool mapHasAdjusted;
@property (strong, nonatomic) NSTimer * finishLoadingTimer;
@property (retain, nonatomic) UITapGestureRecognizer * cityTapGesture;
@property (strong, nonatomic) UIButton *commitmentButton;
@property (strong, nonatomic) UIView *dismissSearchView;
@property (assign, nonatomic) bool hasSearched;
@property (retain, nonatomic) CreatePlaceViewController *createVC;
@property (retain, nonatomic) NSMutableArray *followingActivityArray;
@property (nonatomic, strong) UITableViewController *followingActivityTableViewController;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) CGFloat difference;
@property (nonatomic, strong) UIView *backView;
@property (retain, nonatomic) NSMutableArray *nearbyActivityArray;
@property (nonatomic, strong) UITableView *nearbyActivitytsTableView;
@property (nonatomic, strong) UITableViewController *nearbyActivityTableViewController;
@property (nonatomic, strong) ParticipantsListViewController *participantsListViewController;
@property (retain, nonatomic) CommentViewController * commentVC;
@property (retain, nonatomic) PFObject * postToDelete;
@property (strong, nonatomic) UIView *separatorBar;
@property (strong, nonatomic) UIImageView *switchPicker;
@property (strong, nonatomic) UIButton *popularSwitchButton;
@property (strong, nonatomic) UIButton *mapSwitchButton;
@property (strong, nonatomic) UIButton *feedSwitchButton;
@property (strong, nonatomic) UITapGestureRecognizer *refreshTapGesture;
@property (strong, nonatomic) UITapGestureRecognizer *feedTapGesture;
@property (strong, nonatomic) UITapGestureRecognizer *nearbyTapGesture;

@end

@implementation CenterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.mapHasAdjusted = NO;
        self.annotationsArray = [[NSMutableArray alloc] init];
        
        self.difference = 0.0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.backView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height + 20.0)];
    [self.view addSubview:self.backView];
    
    self.listViewOpen = NO;
    
    // mapview setup
    self.mv = [[MKMapView alloc] initWithFrame:CGRectMake(0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
    self.mv.delegate = self;
    [self.backView addSubview:self.mv];
    
    UIView *legalView = nil;
    
    for (UIView *subview in self.mv.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            legalView = subview;
            [subview removeFromSuperview];
            break;
        }
    }
    legalView.frame = CGRectMake(150, self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT - legalView.frame.size.height
                                 , legalView.frame.size.width, legalView.frame.size.height);
    [self.mv  addSubview:legalView];
    
    // top bar setup
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, self.view.frame.size.width,TOP_BAR_HEIGHT)];
    self.topBar.layer.backgroundColor = UIColorFromRGB(0x8e0528).CGColor;
    [self.backView addSubview:self.topBar];
    
    self.switchBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT - 10.0, self.view.frame.size.width, 40.0)];
    [self.switchBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.switchBar setHidden:YES];
    [self.backView addSubview:self.switchBar];
    
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:14];
    
    self.popularSwitchButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width / 3.0, 40.0)];
    [self.popularSwitchButton addTarget:self action:@selector(popularClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.popularSwitchButton.titleLabel.font = montserratSmall;
    [self.popularSwitchButton setTitle:@"Trending" forState:UIControlStateNormal];
    [self.popularSwitchButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 8.0, 0.0)];
    [self.switchBar addSubview:self.popularSwitchButton];

    self.mapSwitchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 3.0, 0.0, self.view.frame.size.width / 3.0, 40.0)];
    [self.mapSwitchButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 8.0, 0.0)];
    [self.mapSwitchButton addTarget:self action:@selector(mapClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.mapSwitchButton.titleLabel.font = montserratSmall;
    [self.mapSwitchButton setTitle:@"Map" forState:UIControlStateNormal];
    [self.switchBar addSubview:self.mapSwitchButton];

    self.feedSwitchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 3.0 * 2.0, 0.0, self.view.frame.size.width / 3.0, 40.0)];
    [self.feedSwitchButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 8.0, 0.0)];
    [self.feedSwitchButton addTarget:self action:@selector(feedClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.feedSwitchButton.titleLabel.font = montserratSmall;
    [self.feedSwitchButton setTitle:@"Following" forState:UIControlStateNormal];
    [self.switchBar addSubview:self.feedSwitchButton];
    
    // set up search bar and corresponding search results tableview
    self.searchBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, self.topBar.frame.size.height + self.switchBar.frame.size.height - 10.0, self.view.frame.size.width,SEARCH_BAR_HEIGHT)];
    [self.searchBarBackground setBackgroundColor:[UIColor whiteColor]];
    [self.searchBarBackground setAlpha:0.95];
    [self.backView addSubview:self.searchBarBackground];
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake((self.view.frame.size.width - SEARCH_BAR_WIDTH) / 2.0, 0.0, SEARCH_BAR_WIDTH,SEARCH_BAR_HEIGHT)];
    self.searchBar.delegate = self;
    [self.searchBar setBackgroundImage:[UIImage new]];
    [self.searchBar setTranslucent:YES];
    self.searchBar.layer.cornerRadius = 5.0;
    self.searchBar.placeholder = @"Where are you going?";
    [self.searchBarBackground addSubview:self.searchBar];
    self.searchBarBackground.hidden = YES;
    
    // activity table view
    self.followingActivityArray = [[NSMutableArray alloc] init];
    
    self.followingActivitytsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT + 30.0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.followingActivitytsTableView setShowsVerticalScrollIndicator:NO];
    self.followingActivitytsTableView.hidden = YES;
    [self.followingActivitytsTableView setDataSource:self];
    [self.followingActivitytsTableView setDelegate:self];
    [self.backView addSubview:self.followingActivitytsTableView];
    
    self.followingActivityTableViewController = [[UITableViewController alloc] init];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(loadFollowingActivity) forControlEvents:UIControlEventValueChanged];
    self.followingActivityTableViewController.refreshControl = refreshControl;
    self.followingActivityTableViewController.tableView = self.followingActivitytsTableView;
    [self.followingActivitytsTableView reloadData];
    
    // nearby table view
    self.nearbyActivityArray = [[NSMutableArray alloc] init];
    
    self.nearbyActivitytsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT + 30.0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.nearbyActivitytsTableView setShowsVerticalScrollIndicator:NO];
    self.nearbyActivitytsTableView.hidden = YES;
    [self.nearbyActivitytsTableView setDataSource:self];
    [self.nearbyActivitytsTableView setDelegate:self];
    [self.backView addSubview:self.nearbyActivitytsTableView];
    
    self.nearbyActivityTableViewController = [[UITableViewController alloc] init];
    UIRefreshControl *refreshControlNearby = [[UIRefreshControl alloc] init];
    [refreshControlNearby addTarget:self action:@selector(loadNearbyActivity) forControlEvents:UIControlEventValueChanged];
    self.nearbyActivityTableViewController.refreshControl = refreshControlNearby;
    self.nearbyActivityTableViewController.tableView = self.nearbyActivitytsTableView;
    [self.nearbyActivitytsTableView reloadData];
    
    self.dismissSearchView = [[UIView alloc] initWithFrame:CGRectMake(0, self.searchBarBackground.frame.origin.y + self.searchBarBackground.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.searchBarBackground.frame.origin.y - self.searchBarBackground.frame.size.height)];
    [self.dismissSearchView setHidden:YES];
    [self.dismissSearchView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *dismissSearchTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(handleDismissSearchTap:)];
    [self.dismissSearchView addGestureRecognizer:dismissSearchTap];
    [self.backView addSubview:self.dismissSearchView];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.searchResultsArray = [[NSMutableArray alloc] init];
    self.searchResultsArray = [sharedDataManager.placesArray mutableCopy];
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.searchBarBackground.frame.origin.y + self.searchBarBackground.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    self.searchResultsTableView.hidden = YES;
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    [self.view addSubview:self.searchResultsTableView];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    [self.searchResultsTableView reloadData];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate  = self;
    self.userCoordinates = [[CLLocation alloc] init];
    
    [self locationSetup];
    
    self.leftPanelButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.topBar.frame.size.width / 4, self.topBar.frame.size.height)];
    [self.leftPanelButtonLarge addTarget:self action:@selector(btnMovePanelRight:) forControlEvents:UIControlEventTouchUpInside];
    self.leftPanelButtonLarge.tag = 1;
    [self.topBar addSubview:self.leftPanelButtonLarge];
    
    self.tethrLabel = [[UILabel alloc] init];
    UIFont *mission = [UIFont fontWithName:@"MissionGothic-BlackItalic" size:22];
    self.tethrLabel.font = mission;
    self.tethrLabel.text = @"tethr";
    [self.tethrLabel setTextColor:[UIColor whiteColor]];
    CGSize size = [self.tethrLabel.text sizeWithAttributes:@{NSFontAttributeName:mission}];
    self.tethrLabel.frame = CGRectMake((self.topBar.frame.size.width - size.width) / 2, (self.topBar.frame.size.height - size.height + STATUS_BAR_HEIGHT) / 2, size.width, size.height);
    self.tethrLabel.userInteractionEnabled = YES;
    self.refreshTapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(refreshTapped:)];
    [self.tethrLabel addGestureRecognizer:self.refreshTapGesture];
    [self.tethrLabel setHidden:YES];
    [self.topBar addSubview:self.tethrLabel];
    
    self.feedTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(feedClicked:)];
    self.nearbyTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popularClicked:)];
    
    // number of friends going out label setup
    self.numberButton = [[UIButton alloc] init];
    [self.numberButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.numberButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    UIFont *helveticaNeueLarge = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
    size = [self.numberButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeueLarge}];
    self.numberButton.frame = CGRectMake(PADDING, STATUS_BAR_HEIGHT + (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT - size.height) / 2.0, size.width, size.height);
    self.numberButton.titleLabel.font = helveticaNeueLarge;
    [self.numberButton addTarget:self action:@selector(btnMovePanelRight:) forControlEvents:UIControlEventTouchUpInside];
    self.numberButton.tag = 1;
    [self.topBar addSubview:self.numberButton];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:self.numberButton.frame];
    self.activityIndicatorView.color = UIColorFromRGB(0x8e0528);
    [self.view addSubview:self.activityIndicatorView];
    
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.triangleButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 38.5, 7.0, 11.0)];
    [self.triangleButton setImage:triangleImage forState:UIControlStateNormal];
    [self.view addSubview:self.triangleButton];
    self.triangleButton.tag = 1;
    [self.triangleButton addTarget:self action:@selector(btnMovePanelRight:) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.triangleButton];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.topBar.frame.size.width - SPINNER_SIZE) / 2.0, STATUS_BAR_HEIGHT + (self.topBar.frame.size.height - STATUS_BAR_HEIGHT - SPINNER_SIZE) / 2.0, SPINNER_SIZE, SPINNER_SIZE)];
    self.spinner.hidesWhenStopped = YES;
    [self.spinner startAnimating];
    [self.topBar addSubview:self.spinner];
    
    // list view search glass button setup
    self.listViewButton = [[TethrButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40.0, self.tethrLabel.frame.origin.y, 33.0, 28.0)];
    [self.listViewButton setNormalColor:[UIColor clearColor]];
    [self.listViewButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [self.listViewButton setImage:[UIImage imageNamed:@"LineNavigator"] forState:UIControlStateNormal];
    self.listViewButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.listViewButton addTarget:self action:@selector(showListView) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.listViewButton];
    
    self.listViewButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(self.topBar.frame.size.width - self.topBar.frame.size.width / 4.0, 0.0, self.topBar.frame.size.width / 4.0, self.topBar.frame.size.height)];
    [self.listViewButtonLarge addTarget:self action:@selector(showListView) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.listViewButtonLarge];
    
    // bottom nav bar setup
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT)];
    if ([UIApplication sharedApplication].statusBarFrame.size.height == 40.0) {
        self.bottomBar.frame = CGRectMake(0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT - STATUS_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT);
    }
    [self.bottomBar setBackgroundColor:[UIColor whiteColor]];
    [self.bottomBar setAlpha:0.85];
    
    self.separatorBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 1.0)];
    [self.separatorBar setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.separatorBar setHidden:YES];
    [self.bottomBar addSubview:self.separatorBar];
    
    // large background button to increase touch surface area
    self.settingsButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.bottomBar.frame.size.width / 4.0, self.bottomBar.frame.size.height)];
    [self.settingsButtonLarge addTarget:self action:@selector(settingsPressed:) forControlEvents:UIControlEventTouchDown];
    
    // notifications button to open right panel setup
    self.notificationsButton = [[TethrButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 37.0, (self.bottomBar.frame.size.height - 40.0) / 2.0, 30.0, 40.0)];
    [self.notificationsButton setNormalColor:[UIColor clearColor]];
    [self.notificationsButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [self.notificationsButton addTarget:self action:@selector(btnMovePanelLeft:) forControlEvents:UIControlEventTouchUpInside];
    [self.notificationsButton setImage:[UIImage imageNamed:@"Bell"] forState:UIControlStateNormal];
    [self.bottomBar addSubview:self.notificationsButton];
    
    self.notificationsButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(self.bottomBar.frame.size.width - self.bottomBar.frame.size.width / 4.0, 0.0, self.bottomBar.frame.size.width / 4.0, self.bottomBar.frame.size.height)];
    [self.notificationsButtonLarge addTarget:self action:@selector(btnMovePanelLeft:) forControlEvents:UIControlEventTouchUpInside];
    self.notificationsButtonLarge.tag = 1;
    [self.bottomBar addSubview:self.notificationsButtonLarge];

    self.notificationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 20.0, 8.0, 10.0, 10.0)];
    self.notificationsLabel.layer.cornerRadius = 5.0;
    [self.notificationsLabel setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.notificationsLabel setTextColor:[UIColor whiteColor]];
    [self.notificationsLabel setTextAlignment:NSTextAlignmentCenter];
    UIFont *montserratVerySmall = [UIFont fontWithName:@"Montserrat" size:8];
    self.notificationsLabel.font = montserratVerySmall;
    [self.notificationsLabel sizeThatFits:CGSizeMake(10.0, 10.0)];
    self.notificationsLabel.adjustsFontSizeToFitWidth = YES;
    [self.bottomBar addSubview:self.notificationsLabel];
    
    UIFont *montserratExtraSmall = [UIFont fontWithName:@"Montserrat" size:10];
    UIFont *montserratMedium = [UIFont fontWithName:@"Montserrat" size:16];
    
    self.cityButton = [[UIButton alloc] init];
    self.cityButton.titleLabel.font = montserratMedium;
    [self.cityButton setTitleColor: UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    [self.bottomBar addSubview:self.cityButton];
    
    self.placeButton = [[UIButton alloc] init];
    self.placeButton.titleLabel.font = montserratExtraSmall;
    [self.placeButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    self.placeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.placeButton addTarget:self action:@selector(commitmentClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.placeButton];
    
    self.placeNumberButton = [[UIButton alloc] init];
    [self.placeNumberButton.titleLabel setFont:montserratSmall];
    [self.placeNumberButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    [self.placeNumberButton addTarget:self action:@selector(commitmentClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.placeNumberButton];
    
    self.commitmentButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 4.0, 0.0, self.view.frame.size.width / 2.0, self.bottomBar.frame.size.height)];
    [self.commitmentButton addTarget:self action:@selector(commitmentClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.commitmentButton];
    
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cameraButton.frame = CGRectMake(225.0, (self.bottomBar.frame.size.height - 30.0) / 2.0, 30.0, 30.0);
    [cameraButton setImage:[UIImage imageNamed:@"Camera.png"] forState:UIControlStateNormal];
    [cameraButton addTarget:self action:@selector(photoCaptureButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:cameraButton];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(cameraButton.frame.origin.x + cameraButton.frame.size.width + 10.0, 5.0, 1.0, BOTTOM_BAR_HEIGHT - 10.0)];
    [separator setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.bottomBar addSubview:separator];
    
    [self.view addSubview:self.bottomBar];
    
    self.switchPicker = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RedPicker"]];
    self.switchPicker.frame = CGRectMake((self.view.frame.size.width - 11.0) / 2.0, self.switchBar.frame.origin.y + self.switchBar.frame.size.height - 1.0, 11.0, 5.0);
    [self.backView addSubview:self.switchPicker];
    
    self.feedSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake((self.view.frame.size.width - SEARCH_BAR_WIDTH) / 2.0, 0.0, SEARCH_BAR_WIDTH,SEARCH_BAR_HEIGHT)];
    self.feedSearchBar.delegate = self;
    [self.feedSearchBar setBackgroundImage:[UIImage new]];
    [self.feedSearchBar setTranslucent:YES];
    self.feedSearchBar.layer.cornerRadius = 5.0;
    self.feedSearchBar.placeholder = @"Where are you going?";
    
    self.popularSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake((self.view.frame.size.width - SEARCH_BAR_WIDTH) / 2.0, 0.0, SEARCH_BAR_WIDTH,SEARCH_BAR_HEIGHT)];
    self.popularSearchBar.delegate = self;
    [self.popularSearchBar setBackgroundImage:[UIImage new]];
    [self.popularSearchBar setTranslucent:YES];
    self.popularSearchBar.layer.cornerRadius = 5.0;
    self.popularSearchBar.placeholder = @"Where are you going?";
    
    self.coverView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.coverView setHidden:YES];
    [self.view addSubview:self.coverView];
    
    [self layoutCurrentCommitment];
    [self restartTimer];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)loadFollowingActivity {
    [self.feedSearchBar setHidden:YES];
    [self.followingActivityTableViewController.refreshControl beginRefreshing];
    [self.followingActivitytsTableView setContentOffset:CGPointMake(0, -self.followingActivityTableViewController.refreshControl.frame.size.height) animated:YES];
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [query whereKey:@"facebookId" containedIn:[userDetails objectForKey:@"tethrFriends"]];
    [query whereKey:@"facebookId" notContainedIn:[userDetails objectForKey:@"blockedList"]];
    [query whereKey:@"facebookId" notContainedIn:[userDetails objectForKey:@"blockedByList"]];
    [query includeKey:@"photo"];
    [query includeKey:@"user"];
    [query orderByDescending:@"updatedAt"];
    [query setLimit:100];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.followingActivityArray = [[NSMutableArray alloc] initWithArray:objects];
        [self.followingActivitytsTableView reloadData];
        [self.followingActivityTableViewController.refreshControl endRefreshing];
        if (self.followingActivitytsTableView.contentOffset.y == -self.followingActivityTableViewController.refreshControl.frame.size.height) {
            [self.followingActivitytsTableView setContentOffset:CGPointMake(0, 0) animated:YES];
            [self.feedSearchBar setHidden:NO];
        }
    }];
}

-(void)loadNearbyActivity {
    [self.popularSearchBar setHidden:YES];
    [self.nearbyActivityTableViewController.refreshControl beginRefreshing];
    [self.nearbyActivitytsTableView setContentOffset:CGPointMake(0, -self.nearbyActivityTableViewController.refreshControl.frame.size.height) animated:YES];
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"coordinate" nearGeoPoint:[PFGeoPoint geoPointWithLatitude:self.userCoordinates.coordinate.latitude
                                                                       longitude:self.userCoordinates.coordinate.longitude] withinKilometers:20.0];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [query whereKey:@"facebookId" notContainedIn:[standardUserDefaults objectForKey:@"blockedList"]];
    [query whereKey:@"facebookId" notContainedIn:[standardUserDefaults objectForKey:@"blockedByList"]];
    [query whereKey:@"private" notEqualTo:[NSNumber numberWithBool:YES]];
    [query whereKey:@"privatePlace" notEqualTo:[NSNumber numberWithBool:YES]];
    [query includeKey:@"photo"];
    [query includeKey:@"user"];
    [query orderByDescending:@"updatedAt"];
    [query whereKey:@"user" notEqualTo:[PFUser currentUser]];
    [query setLimit:100];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.nearbyActivityArray = [[NSMutableArray alloc] initWithArray:objects];
        if ([objects count]  > 0) {
            [self.nearbyActivitytsTableView reloadData];
            [self.nearbyActivityTableViewController.refreshControl endRefreshing];
            if (self.nearbyActivitytsTableView.contentOffset.y == -self.nearbyActivityTableViewController.refreshControl.frame.size.height) {
                [self.nearbyActivitytsTableView setContentOffset:CGPointMake(0, 0) animated:YES];
                [self.popularSearchBar setHidden:NO];
            }
        } else {
            [self loadGlobalPopularActivity];
        }
    }];
}

-(void)loadGlobalPopularActivity {
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"private" notEqualTo:[NSNumber numberWithBool:YES]];
    [query whereKey:@"privatePlace" notEqualTo:[NSNumber numberWithBool:YES]];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [query whereKey:@"facebookId" notContainedIn:[standardUserDefaults objectForKey:@"blockedList"]];
    [query whereKey:@"facebookId" notContainedIn:[standardUserDefaults objectForKey:@"blockedByList"]];
    [query includeKey:@"photo"];
    [query includeKey:@"user"];
    [query orderByDescending:@"updatedAt"];
    [query whereKey:@"user" notEqualTo:[PFUser currentUser]];
    [query setLimit:100];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.nearbyActivityArray = [[NSMutableArray alloc] initWithArray:objects];
        [self.nearbyActivitytsTableView reloadData];
        [self.nearbyActivityTableViewController.refreshControl endRefreshing];
        if (self.nearbyActivitytsTableView.contentOffset.y == -self.nearbyActivityTableViewController.refreshControl.frame.size.height) {
            [self.nearbyActivitytsTableView setContentOffset:CGPointMake(0, 0) animated:YES];
            [self.popularSearchBar setHidden:NO];
        }
    }];
}

- (void)photoCaptureButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(photoCapture)]) {
        [self.delegate photoCapture];
    }
}

-(void)setNeedsStatusBarAppearanceUpdate {
    self.topBar.frame = CGRectMake(0, 0.0, self.view.frame.size.width,TOP_BAR_HEIGHT);
    self.bottomBar.frame = CGRectMake(0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT);
    self.mv.frame = CGRectMake(0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height);
}

-(void)layoutNumberButton {
    UIFont *helveticaNeue = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
    CGSize size = [self.numberButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeue}];
    self.numberButton.frame = CGRectMake(PADDING, STATUS_BAR_HEIGHT + (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT - size.height) / 2.0, size.width, size.height);
    self.numberButton.tag = 1;
    [self.topBar addSubview:self.numberButton];
}

-(void)layoutCurrentCommitment {
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:14];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSDate *timeLastUpdated = [userDetails objectForKey:@"timeLastUpdated"];
    NSDate *startTime = [self getStartTime];
    
    if (sharedDataManager.currentCommitmentPlace && [startTime compare:timeLastUpdated] == NSOrderedAscending && [sharedDataManager.currentCommitmentPlace.friendsCommitted count] > 0) {
        self.cityButton.hidden = YES;
        self.commitmentButton.hidden = NO;
        self.placeButton.hidden = NO;
        self.placeNumberButton.hidden = NO;
        
        UIFont *montserratExtraSmall = [UIFont fontWithName:@"Montserrat" size:10];
        [self.placeButton setTitle:sharedDataManager.currentCommitmentPlace.name forState:UIControlStateNormal];
        [self.placeNumberButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)[sharedDataManager.currentCommitmentPlace.friendsCommitted count]] forState:UIControlStateNormal];
        
        CGSize size1 = [self.placeButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratExtraSmall}];
        CGSize size2 = [self.placeNumberButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratSmall}];
        
        self.placeButton.frame = CGRectMake(MAX(self.userProfilePictureView.frame.origin.x + self.userProfilePictureView.frame.size.width, (self.view.frame.size.width - size1.width) / 2), (self.bottomBar.frame.size.height - size1.height + size2.height) / 2.0, MIN(267.0, size1.width), size1.height);
        
        self.placeNumberButton.frame = CGRectMake((self.view.frame.size.width - size2.width) / 2, (self.bottomBar.frame.size.height - size1.height - size2.height) / 2.0, size2.width, size2.height);
    } else {
        self.cityButton.hidden = NO;
        self.commitmentButton.hidden = YES;
        self.placeButton.hidden = YES;
        self.placeNumberButton.hidden = YES;

        UIFont *montserratExtraSmall = [UIFont fontWithName:@"Montserrat" size:16];
        NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
        if ([userDetails objectForKey:@"city"]) {
            [self.cityButton setTitle:[NSString stringWithFormat:@"%@",[userDetails objectForKey:@"city"]] forState:UIControlStateNormal];
        } else if (![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            [self.cityButton setTitle:@"Enter your city" forState:UIControlStateNormal];
        }
        
        self.cityButton.titleLabel.font = montserratExtraSmall;
        
        CGSize size = [self.cityButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratExtraSmall}];
        self.cityButton.frame = CGRectMake((self.view.frame.size.width - size.width) / 2, (self.bottomBar.frame.size.height - size.height) / 2.0, MIN(300.0, size.width), size.height);
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

#pragma UIGestureRecognizers

- (void)refreshTapped:(UIGestureRecognizer*)recognizer {
    if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
        [self.delegate pollDatabase];
        [self.tethrLabel setHidden:YES];
        [self.spinner startAnimating];
        [self performSelector:@selector(refreshComplete) withObject:self.spinner afterDelay:1.0];
        [self updateLocation];
    }
    
    [Flurry logEvent:@"Refresh_clicked"];
}

-(void)refreshComplete {
    [self.tethrLabel setHidden:NO];
    [self.spinner stopAnimating];
}

-(void)refreshNotificationsNumber {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.notificationsLabel.text = [NSString stringWithFormat:@"%ld", (long)sharedDataManager.notifications];
    if (sharedDataManager.notifications == 0 || !sharedDataManager.notifications) {
        [self.notificationsLabel setHidden:YES];
    } else {
        [self.notificationsLabel setHidden:NO];
    }
}

-(void)locationSetup {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    
    if (([userDetails boolForKey:@"useCurrentLocation"] || ![userDetails objectForKey:@"city"] || ![userDetails objectForKey:@"state"]) && ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied)) {
        [self.locationManager startUpdatingLocation];
        if (![userDetails objectForKey:@"city"] || ![userDetails objectForKey:@"state"]) {
            [userDetails setBool:YES forKey:@"useCurrentLocation"];
            [userDetails synchronize];
        }
    } else {
        NSString *city = [userDetails objectForKey:@"city"];
        NSString *state = [userDetails objectForKey:@"state"];
        NSString *locationString = [NSString stringWithFormat:@"%@, %@", city, state];
        NSLog(@"%@", locationString);
        if (city != NULL && state != NULL) {
            [self setUserLocationToCity:locationString];
        } else if ((![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)){
            [userDetails setBool:NO forKey:@"useCurrentLocation"];
            [userDetails synchronize];
        }
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"User has not allowed location services %@", [error description]);
}

-(void)restartTimer {
    [self.finishLoadingTimer invalidate];
    self.finishLoadingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                               target:self
                                                             selector:@selector(mapLoadingIsFinished)
                                                             userInfo:nil
                                                              repeats:NO];
}

- (void)mapLoadingIsFinished
{
    NSLog(@"timer stopped");
    self.mapHasAdjusted = YES;
}


-(void)updateLocation {
    CLLocationCoordinate2D userCoord = CLLocationCoordinate2DMake(self.userCoordinates.coordinate.latitude , self.userCoordinates.coordinate.longitude);
    
    NSLog(@"Adjusting Map: %f, %f", self.userCoordinates.coordinate.latitude,
          self.userCoordinates.coordinate.longitude);
    
    MKCoordinateRegion adjustedRegion = [self.mv regionThatFits:MKCoordinateRegionMakeWithDistance(userCoord, 8000, 8000)];
    [self.mv setRegion:adjustedRegion animated:NO];
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    
    if (![userDetails boolForKey:@"useCurrentLocation"]) {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        sharedDataManager.userCoordinates = self.userCoordinates;
    }
    
    // change position of legal link
    UIView *legalView = nil;
    
    for (UIView *subview in self.mv.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            legalView = subview;
            break;
        }
    }
    legalView.frame = CGRectMake(0.0, self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT - legalView.frame.size.height
                                 , legalView.frame.size.width, legalView.frame.size.height);
}

-(void)setCityFromCLLocation:(CLLocation *)location
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (error)
         {
             NSLog(@"failed with error: %@", error);
             return;
         }
         if(placemarks.count > 0)
         {
             NSString *MyAddress = @"";
             NSString *city = @"";
             NSString *state = @"";
             
             CLPlacemark *myPlacemark = [placemarks objectAtIndex:0];
             
             if([myPlacemark.addressDictionary objectForKey:@"FormattedAddressLines"] != NULL)
                 MyAddress = [[myPlacemark.addressDictionary objectForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
             else
                 MyAddress = @"Address Not founded";
             
             if([myPlacemark.addressDictionary objectForKey:@"City"] != NULL)
                 city = [myPlacemark.addressDictionary objectForKey:@"City"];
             if (myPlacemark.administrativeArea != NULL) {
                 state = myPlacemark.administrativeArea;
             }
             
              NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
             if (![city isEqualToString:[userDetails objectForKey:@"city"]] || ![state isEqualToString:[userDetails objectForKey:@"state"]]) {
                 [userDetails setObject:city forKey:@"city"];
                 [userDetails setObject:state forKey:@"state"];
                 [userDetails synchronize];
             }
             
             if ([self.delegate respondsToSelector:@selector(saveCity:state:)]) {
                 if (![city isEqualToString:@""]) {
                     [self.delegate saveCity:city state:state];
                 }
             }
             
             NSString *locationString = [NSString stringWithFormat:@"%@, %@", city, state];
             [self setUserLocationToCity:locationString];
             
             if (self.resettingLocation) {
                 if ([self.delegate respondsToSelector:@selector(finishedResettingNewLocation)]) {
                     [self.delegate finishedResettingNewLocation];
                 }
             }
             self.resettingLocation = NO;
         }
     }];
}

-(void)setUserLocationToCity:(NSString*)city {
    CLGeocoder *geo = [[CLGeocoder alloc] init];
    [geo geocodeAddressString:city completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            if ([placemarks count] > 0) {
                CLPlacemark *placemark = [placemarks objectAtIndex:0];
                CLLocation *location = placemark.location;
                NSLog(@"setting user coordinates from city name to %f %f", location.coordinate.latitude, location.coordinate.longitude);
                self.userCoordinates = location;
                [self updateLocation];
                 self.mv.showsUserLocation = YES;
            }
        } else {
            NSLog(@"Error: %@", error);
        }
    }];
}

-(void)showListView {
    [self searchBarCancelButtonClicked:self.searchBar];
    if ([self.delegate respondsToSelector:@selector(showListView)]) {
        self.listViewOpen = YES;
        [self.delegate showListView];
    }
}

#pragma mark CLLocationManager

-(void)locationManager:(CLLocationManager *)manager
   didUpdateToLocation:(CLLocation *)newLoc
          fromLocation:(CLLocation *)oldLoc {
    NSLog(@"LOCATION MANAGER: Did update location manager: %f, %f", newLoc.coordinate.latitude,
          newLoc.coordinate.longitude);
    self.userCoordinates = newLoc;
    [self setCityFromCLLocation:newLoc];
    
    [self.locationManager stopUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    sharedDataManager.userCoordinates = newLoc;
    
    if (self.userCoordinates) {
        if (self.userCoordinates.coordinate.latitude != 0.0) {
            [Flurry setLatitude:self.userCoordinates.coordinate.latitude
                      longitude:self.userCoordinates.coordinate.longitude
             horizontalAccuracy:self.userCoordinates.horizontalAccuracy
               verticalAccuracy:self.userCoordinates.verticalAccuracy];
        }
    }
}

#pragma mark -
#pragma mark Button Actions

- (IBAction)popularClicked:(id)sender {
    if (self.nearbyActivitytsTableView.hidden == YES) {
        [self.followingActivitytsTableView setHidden:YES];
        [self.searchResultsTableView setHidden:YES];
        [self.nearbyActivitytsTableView setHidden:NO];
        [self.view endEditing:YES];
        self.bottomBar.alpha = 1.0;
        if ([self.nearbyActivityArray count] == 0) {
            [self loadNearbyActivity];
        }
        [self.separatorBar setHidden:NO];
        UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:14];
        UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:16];
         CGRect frame = self.switchPicker.frame;
        frame.origin.x = (self.view.frame.size.width) / 6.0 - 11.0 / 2.0;
        [UIView animateWithDuration:0.1
                         animations:^{
                             self.switchPicker.frame = frame;
                             self.mapSwitchButton.titleLabel.font = montserratSmall;
                             self.popularSwitchButton.titleLabel.font = montserratBold;
                             self.feedSwitchButton.titleLabel.font = montserratSmall;
                             [self.tethrLabel removeGestureRecognizer:self.feedTapGesture];
                             [self.tethrLabel addGestureRecognizer:self.nearbyTapGesture];
                             [self.tethrLabel removeGestureRecognizer:self.refreshTapGesture];
    } completion:^(BOOL finished) {
        
    }];
    } else {
        [self.nearbyActivitytsTableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0) animated:YES];
        [self.popularSearchBar setHidden:NO];
    }
}

- (IBAction)feedClicked:(id)sender {
    if (self.followingActivitytsTableView.hidden == YES) {
        [self.searchResultsTableView setHidden:YES];
        [self.nearbyActivitytsTableView setHidden:YES];
        [self.followingActivitytsTableView setHidden:NO];
        [self.view endEditing:YES];
        self.bottomBar.alpha = 1.0;
        if ([self.followingActivityArray count] == 0) {
             [self loadFollowingActivity];
        }
        [self.separatorBar setHidden:NO];
        UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:14];
        UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:16];
        CGRect frame = self.switchPicker.frame;
        frame.origin.x = (self.view.frame.size.width) / 6.0 *5.0 - 11.0 / 2.0;
        [UIView animateWithDuration:0.1
                         animations:^{
                             self.switchPicker.frame = frame;
                             self.mapSwitchButton.titleLabel.font = montserratSmall;
                             self.popularSwitchButton.titleLabel.font = montserratSmall;
                             self.feedSwitchButton.titleLabel.font = montserratBold;
                             [self.tethrLabel addGestureRecognizer:self.feedTapGesture];
                             [self.tethrLabel removeGestureRecognizer:self.nearbyTapGesture];
                             [self.tethrLabel removeGestureRecognizer:self.refreshTapGesture];
                         } completion:^(BOOL finished) {
                             
                         }];
    } else {
        [self.followingActivitytsTableView scrollRectToVisible:CGRectMake(0.0, 0.0, 1.0, 1.0) animated:YES];
        [self.feedSearchBar setHidden:NO];
    }
}

- (IBAction)mapClicked:(id)sender {
    self.bottomBar.alpha = 0.85;
    [self.nearbyActivitytsTableView setHidden:YES];
    [self.followingActivitytsTableView setHidden:YES];
    [self.searchResultsTableView setHidden:YES];
    [self.view endEditing:YES];
    [self.separatorBar setHidden:YES];
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:14];
    UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:16];
    CGRect frame = self.switchPicker.frame;
    frame.origin.x = (self.view.frame.size.width - 11.0) / 2.0;
    [UIView animateWithDuration:0.1
                     animations:^{
                         self.switchPicker.frame = frame;
                         self.mapSwitchButton.titleLabel.font = montserratBold;
                         self.popularSwitchButton.titleLabel.font = montserratSmall;
                         self.feedSwitchButton.titleLabel.font = montserratSmall;
                         [self.tethrLabel removeGestureRecognizer:self.feedTapGesture];
                        [self.tethrLabel removeGestureRecognizer:self.nearbyTapGesture];
                         [self.tethrLabel addGestureRecognizer:self.refreshTapGesture];
                     } completion:^(BOOL finished) {
                         
                     }];
}

- (IBAction)settingsPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(showYourProfileScrollToPost:)]) {
        [self.delegate showYourProfileScrollToPost:nil];
    }
}

- (IBAction)btnMovePanelRight:(id)sender
{
    if (!self.listViewOpen) {
        UIButton *button = sender;
        switch (button.tag) {
            case 0: {
                [_delegate movePanelToOriginalPosition];
                break;
            }
                
            case 1: {
                [_delegate movePanelRight];
                [self searchBarCancelButtonClicked:self.searchBar];
                break;
            }
                
            default:
                break;
        }
    }
}

- (IBAction)btnMovePanelLeft:(id)sender
{
    if (!self.listViewOpen) {
        UIButton *button = sender;
        switch (button.tag) {
            case 0: {
                [_delegate movePanelToOriginalPosition];
                break;
            }
                
            case 1: {
                [_delegate movePanelLeft];
                [self searchBarCancelButtonClicked:self.searchBar];
                break;
            }
                
            default:
                break;
        }
    }
}

- (void)movePanelLeft:(UIGestureRecognizer*)recognizer {
    if (!self.listViewOpen) {
        UIView *view = recognizer.view;
        switch (view.tag) {
            case 0: {
                [_delegate movePanelToOriginalPosition];
                break;
            }
                
            case 1: {
                [_delegate movePanelLeft];
                [self searchBarCancelButtonClicked:self.searchBar];
                break;
            }
                
            default:
                break;
        }
    }
}

-(IBAction)commitmentClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    TetherAnnotationView * annotationView = [self.placeToAnnotationViewDictionary objectForKey:sharedDataManager.currentCommitmentPlace.placeId];
    
    if (annotationView.tag == 1) {
        [self.mv selectAnnotation:((MKAnnotationView*)annotationView).annotation animated:YES];
        annotationView.placeTouchView.userInteractionEnabled = YES;
        annotationView.tag = 0;
    } else {
        [self.mv deselectAnnotation:((MKAnnotationView*)annotationView).annotation animated:YES];
        annotationView.placeTouchView.userInteractionEnabled = NO;
        annotationView.tag = 1;
    }
}

- (void)handleDismissSearchTap:(UITapGestureRecognizer *)recognizer {
    [self searchBarCancelButtonClicked:self.searchBar];
}

#pragma mark ActivityCell delegate

-(void)openPlace:(Place*)place {
    if ([self.delegate respondsToSelector:@selector(openPageForPlaceWithId:)]) {
        [self.delegate openPageForPlaceWithId:place.placeId];
    }
}

-(void)showLikes:(NSMutableSet*)friendIdSet {
    self.participantsListViewController = [[ParticipantsListViewController alloc] init];
    self.participantsListViewController.participantIds = [[friendIdSet allObjects] mutableCopy];
    self.participantsListViewController.topBarLabel = [[UILabel alloc] init];
    [self.participantsListViewController.topBarLabel setText:@"Likes"];
    self.participantsListViewController.delegate = self;
    [self.participantsListViewController didMoveToParentViewController:self];
    [self.participantsListViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.participantsListViewController.view];
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.participantsListViewController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)showComments:(PFObject *)activityObject {
    self.commentVC = [[CommentViewController alloc] init];
    self.commentVC.delegate = self;
    self.commentVC.activityObject = activityObject;
    [self.commentVC didMoveToParentViewController:self];
    [self.commentVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.commentVC.view];
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.commentVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)postSettingsClicked:(PFObject*)postObject {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Delete Post", nil];
    [actionSheet showInView:self.view];
    self.postToDelete = postObject;
}

#pragma mark CommentViewControllerDelegate

-(void)closeCommentView {
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.commentVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.commentVC.view removeFromSuperview];
                         [self.commentVC removeFromParentViewController];
                     }];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        if ([[self.postToDelete objectForKey:@"type"] isEqualToString:@"photo"]) {
            if ([self.delegate respondsToSelector:@selector(confirmPosting:)]) {
                [self.delegate confirmPosting:@"Deleting your photo"];
            }
            
            PFObject *photoObject = [self.postToDelete objectForKey:@"photo"];
            [photoObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [self.postToDelete deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        if ([self.delegate respondsToSelector:@selector(reloadActivity)]) {
                            [self.delegate reloadActivity];
                        }
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Could not delete your post, please try again" message:nil delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    }
                }];
            }];
        } else {
            if ([self.delegate respondsToSelector:@selector(confirmPosting:)]) {
                [self.delegate confirmPosting:@"Deleting your post"];
            }
            
            [self.postToDelete deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    if ([self.delegate respondsToSelector:@selector(reloadActivity)]) {
                        [self.delegate reloadActivity];
                    }
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Could not delete your post, please try again" message:nil delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
            }];
        }
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            if ([button.titleLabel.text isEqualToString:@"Delete Post"]) {
                [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            }
        }
    }
}

#pragma mark ParticipantsListViewControllerDelegate

-(void)closeParticipantsView {
    [UIView animateWithDuration:SLIDE_TIMING*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.participantsListViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.participantsListViewController.view removeFromSuperview];
                         [self.participantsListViewController removeFromParentViewController];
                     }];
}

-(void)showProfileOfFriend:(Friend*)user {
    if ([self.delegate respondsToSelector:@selector(showProfileOfFriend:)]) {
        [self.delegate showProfileOfFriend:user];
    }
}


#pragma mark MapView delegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, set no callout and return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        ((MKUserLocation *)annotation).title = @"";
        return nil;
    }
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[TetherAnnotation class]])
    {
        // Try to dequeue an existing pin view first.
        TetherAnnotationView *pinView = [[TetherAnnotationView alloc] init];
        pinView.userInteractionEnabled = YES;
        
        TetherAnnotation *annotationPoint = (TetherAnnotation*)annotation;
        Place *p = annotationPoint.place;
        
        pinView = [[TetherAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotationView"];
        pinView.canShowCallout = YES;
        UIImage *pinImage = [UIImage imageNamed:@"PinIcon"];
        pinView.tag = 1;
        pinView.image = NULL;
        pinView.frame = CGRectMake(0, 0, 40.0, 40.0);
        UIImageView *imageView = [[UIImageView alloc] initWithImage:pinImage];
        imageView.frame = CGRectMake(9.5, 1.0, 21.0, 38.0);
        
        // If an existing pin view was not available, create one.
        UILabel *numberLabel = [[UILabel alloc] init];
        UIFont *helveticaNeueSmall = [UIFont fontWithName:@"HelveticaNeue-Bold" size:10];
        numberLabel.font = helveticaNeueSmall;
        numberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[((TetherAnnotation*)annotation).place.friendsCommitted count]];
        CGSize size = [numberLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeueSmall}];
        numberLabel.frame = CGRectMake((pinView.frame.size.width - size.width) / 2.0, (pinView.frame.size.height - size.height) / 4.0, MIN(size.width, 20), MIN(size.height, 15.0));
        numberLabel.adjustsFontSizeToFitWidth = YES;
        
        UILabel* leftLabel = [[UILabel alloc] init];
        leftLabel.userInteractionEnabled = YES;
        [leftLabel setTextColor:[UIColor whiteColor]];
        UIFont *helveticaNeue = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
        [leftLabel setFont:helveticaNeue];
        [leftLabel setText:[NSString stringWithFormat:@"  %d",[((TetherAnnotation*)annotation).place.friendsCommitted count]]];
        size = [leftLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeue}];
        leftLabel.frame = CGRectMake(0, -2.0, size.width + 10.0, 45.0);
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width + 10.0, 45.0)];

        if ([p.friendsCommitted count] == 0) {
            UIImage *pinImage = [UIImage imageNamed:@"DarkGreyPin"];
            pinView.tag = 1;
            pinView.image = NULL;
            pinView.frame = CGRectMake(0, 0, 40.0, 40.0);
            UIImageView *imageView = [[UIImageView alloc] initWithImage:pinImage];
            imageView.frame = CGRectMake(9.5, 1.0, 21.0, 38.0);
            leftLabel.textColor = UIColorFromRGB(0x8e0528);
            numberLabel.textColor = UIColorFromRGB(0x8e0528);
            [pinView addSubview:imageView];
            [pinView addSubview:numberLabel];
            [backgroundView setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
        } else {
            numberLabel.textColor = [UIColor whiteColor];
            [pinView addSubview:imageView];
            [pinView addSubview:numberLabel];
            [backgroundView setBackgroundColor:UIColorFromRGB(0x8e0528)];
        }
    
        [backgroundView addSubview:leftLabel];
        pinView.leftCalloutAccessoryView = backgroundView;
    
        [self.annotationsArray addObject:p];
        
        int i = 0;

        for (id friendId in p.friendsCommitted) {
            if (i < MAX_FRIENDS_ON_PIN) {
                FBProfilePictureView *profileView = [[FBProfilePictureView alloc] initWithFrame:CGRectMake(-15.0, 0, 40.0, 40.0)];
                profileView.profileID = friendId;
                profileView.layer.cornerRadius = CORNER_RADIUS;
                profileView.clipsToBounds = YES;
                profileView.tag = 2;
                [pinView addSubview:profileView];
                profileView.alpha = 0.0;
                CGRect frame;
                switch (i) {
                    case 0:
                        frame = CGRectMake(-DISTANCE_FACE_TO_PIN, 0, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 1:
                        frame = CGRectMake(DISTANCE_FACE_TO_PIN + 5.0, 0, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 2:
                        if ([p.friendsCommitted count] == 3) {
                            frame = CGRectMake(0, DISTANCE_FACE_TO_PIN +5.0, FACE_SIZE, FACE_SIZE);
                            profileView.frame = frame;
                        } else {
                            frame = CGRectMake(DISTANCE_FACE_TO_PIN - 5.0, DISTANCE_FACE_TO_PIN +5.0, FACE_SIZE, FACE_SIZE);
                            profileView.frame = frame;
                        }
                        break;
                    case 3:
                         frame = CGRectMake(-DISTANCE_FACE_TO_PIN + 5.0, DISTANCE_FACE_TO_PIN + 5.0, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                        break;
                    case 4:
                        frame = CGRectMake(0.0, -DISTANCE_FACE_TO_PIN -5.0, FACE_SIZE, FACE_SIZE);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 5:
                        frame = CGRectMake(-DISTANCE_FACE_TO_PIN - FACE_SIZE / 2.0, FACE_SIZE / 2.0, FACE_SIZE*0.75, FACE_SIZE*0.75);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 6:
                        frame = CGRectMake(+DISTANCE_FACE_TO_PIN + FACE_SIZE / 2.0, FACE_SIZE / 2.0, FACE_SIZE*0.75, FACE_SIZE*0.75);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 7:
                        frame = CGRectMake(0.0, DISTANCE_FACE_TO_PIN + 5.0 + FACE_SIZE / 2.0, FACE_SIZE*0.75, FACE_SIZE*0.75);
                        profileView.frame = frame;
                        break;
                    case 8:
                        frame = CGRectMake(-DISTANCE_FACE_TO_PIN - FACE_SIZE / 4.0, -DISTANCE_FACE_TO_PIN - FACE_SIZE / 4.0, FACE_SIZE*0.75, FACE_SIZE*0.75);
                        profileView.frame = frame;
                        break;
                    case 9:
                        frame = CGRectMake(DISTANCE_FACE_TO_PIN + FACE_SIZE / 4.0, -DISTANCE_FACE_TO_PIN - FACE_SIZE / 4.0, FACE_SIZE*0.75, FACE_SIZE*0.75);
                        profileView.frame = frame;
                        break;
                    case 10:
                        frame = CGRectMake(-DISTANCE_FACE_TO_PIN - FACE_SIZE / 2.0, 0.0, 30.0, 30.0);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 11:
                        frame = CGRectMake(DISTANCE_FACE_TO_PIN + FACE_SIZE / 2.0 + 5.0, 0.0, 30.0, 30.0);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 12:
                        frame = CGRectMake(-DISTANCE_FACE_TO_PIN - FACE_SIZE / 4.0, DISTANCE_FACE_TO_PIN + FACE_SIZE / 2.0 + 5.0, 30.0, 30.0);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 13:
                        frame = CGRectMake(DISTANCE_FACE_TO_PIN + FACE_SIZE / 4.0, DISTANCE_FACE_TO_PIN + FACE_SIZE / 2.0 + 5.0, 30.0, 30.0);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    case 14:
                        frame = CGRectMake(0.0, DISTANCE_FACE_TO_PIN + FACE_SIZE, 30.0, 30.0);
                        profileView.frame = frame;
                        [pinView sendSubviewToBack:profileView];
                        break;
                    default:
                         break;
                }
            }
            i++;
        }
        [self addPlaceTouchViewForAnnotationView:pinView];
        pinView.placeTouchView.tag = [self.annotationsArray indexOfObject:p];
        
        [self.placeToAnnotationViewDictionary setObject:pinView forKey:p.placeId];
        return pinView;
    }
    return nil;
}

-(void)addPlaceTouchViewForAnnotationView:(TetherAnnotationView*)pinView {
    UIFont *systemFont = [UIFont systemFontOfSize:18.0];
    UIFont *subtitleSystemFont = [UIFont systemFontOfSize:14.0];
    CGSize titleSize = [((TetherAnnotation*)pinView.annotation).place.name sizeWithAttributes:@{NSFontAttributeName:systemFont}];
    CGSize subtitleSize = [((TetherAnnotation*)pinView.annotation).place.address sizeWithAttributes:@{NSFontAttributeName:subtitleSystemFont}];
    CGFloat width = MAX(titleSize.width,subtitleSize.width);
    
    pinView.placeTouchView = [[UIView alloc] initWithFrame:CGRectMake(- width / 2.0, -58.0, MIN(MAX(titleSize.width,subtitleSize.width), self.view.frame.size.width - 100.0), 45.0)];
    pinView.placeTouchView.userInteractionEnabled = NO;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPlacePage:)];
    [pinView.placeTouchView addGestureRecognizer:tap];
    
    [pinView addSubview:pinView.placeTouchView];
}

- (void)openPlacePage:(UIGestureRecognizer *) sender
{
    if (self.listViewOpen == NO) {
        UIView *view = sender.view;
        Place *p = [self.annotationsArray objectAtIndex:view.tag];
        if ([self.delegate respondsToSelector:@selector(openPageForPlaceWithId:)]) {
            self.listViewOpen = YES;
            [self.delegate openPageForPlaceWithId:p.placeId];
        }
    }
}

-(void) annotationClick:(UIGestureRecognizer *) sender {
    MKAnnotationView *view = (MKAnnotationView*)sender.view;
    [self.mv deselectAnnotation:view.annotation animated:YES];
    view.tag = 0;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(annotationClick:)];
    [view addGestureRecognizer:singleTap];
    
    if (view.tag == 1) {
        view.userInteractionEnabled = YES;
        for (UIView *subView in view.subviews) {
            if (subView.tag == 2) {
                CGRect frame = subView.frame;
                frame.size.width = 0;
                frame.size.height = 0;
                subView.frame = frame;
                subView.alpha = 1.0;
            }
        }
        
        __block int numFriends = 0;
        
        //show faces
        [UIView animateWithDuration:0.3f
                              delay:0.0
             usingSpringWithDamping:0.8
              initialSpringVelocity:5.0
                            options:0
                         animations:^{
                             for (UIView *subView in view.subviews) {
                                 if (subView.tag == 2) {
                                     CGRect frame = subView.frame;
                                     frame.size.width = FACE_SIZE;
                                     frame.size.height = FACE_SIZE;
                                     subView.frame = frame;
                                     numFriends += 1;
                                 }
                             }
                         }
                         completion:^(BOOL finished) {
                             if (numFriends == 0) {
                                 [self performSelector:@selector(layoutTouchEventForAnnotationView:) withObject:(TetherAnnotationView*)view afterDelay:0.2
                                  ];
                             } else {
                                 [self layoutTouchEventForAnnotationView:((TetherAnnotationView*)view)];
                             }
                         }];
        view.tag = 0;
    } else {
        [self.mv deselectAnnotation:view.annotation animated:YES];
        view.tag = 1;
    }
}

-(void)layoutTouchEventForAnnotationView:(TetherAnnotationView*)view {
     ((TetherAnnotationView*)view).placeTouchView.userInteractionEnabled = YES;

    UIFont *systemFont = [UIFont systemFontOfSize:18.0];
    UIFont *subtitleSystemFont = [UIFont systemFontOfSize:14.0];
    CGSize titleSize = [((TetherAnnotation*)view.annotation).place.name sizeWithAttributes:@{NSFontAttributeName:systemFont}];
    CGSize subtitleSize = [((TetherAnnotation*)view.annotation).place.address sizeWithAttributes:@{NSFontAttributeName:subtitleSystemFont}];
    CGFloat width = MAX(titleSize.width,subtitleSize.width) + 40.0;
    
    [view bringSubviewToFront:view.placeTouchView];
    if (view.frame.origin.x > self.view.frame.size.width / 2.0 ) {
        CGFloat originRight = view.frame.origin.x + width / 2.0 + ((TetherAnnotationView*)view).rightCalloutAccessoryView.frame.size.width + 40.0;
        if (originRight > self.view.frame.size.width) {
            CGFloat offset = originRight - self.view.frame.size.width;
            CGRect frame = view.placeTouchView.frame;
            frame.origin.x = - width / 2.0 - abs(offset) + 40.0;
            frame.size.width = width;
            view.placeTouchView.frame = frame;
            return;
        }
    } else {
        CGFloat originX = view.frame.origin.x - view.placeTouchView.frame.size.width / 2.0 - ((TetherAnnotationView*)view).leftCalloutAccessoryView.frame.size.width;
        if (originX < 0) {
            CGRect frame = view.placeTouchView.frame;
            frame.origin.x = - width / 2.0 + abs(originX) + 40.0;
            view.placeTouchView.frame = frame;
            return;
        }
    }
    CGRect frame = view.placeTouchView.frame;
    frame.origin.x = - width / 2.0 + 40.0;
    frame.size.width = width;
    view.placeTouchView.frame = frame;
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]) {
        return;
    }
    for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
        [view removeGestureRecognizer:recognizer];
    }
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         for (UIView *subView in view.subviews) {
                             if (subView.tag == 2) {
                                 subView.alpha = 0.0;
                             }
                         }                     }
                     completion:^(BOOL finished){
                          ((TetherAnnotationView*)view).placeTouchView.userInteractionEnabled = NO;
                         [((TetherAnnotationView*)view).placeTouchView setBackgroundColor:[UIColor clearColor]];
                     }];
    view.tag = 1;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    TetherAnnotationView *aV;
    for (aV in views) {
        CGRect endFrame = aV.frame;
        
        aV.frame = CGRectMake(aV.frame.origin.x, aV.frame.origin.y - 230.0, aV.frame.size.width, aV.frame.size.height);
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.45];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [aV setFrame:endFrame];
        [UIView commitAnimations];
        
    }
}

-(void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
    if (!self.mapHasAdjusted) {
        NSLog(@"Did finish loading map");
        [self updateLocation];
    }
}

-(void)openNewPlaceWithId:(NSString*)placeId {
    if ([self.delegate respondsToSelector:@selector(openNewPlaceWithId:)]) {
        [self.delegate openNewPlaceWithId:placeId];
    }
}

-(void)createPlace {
    [self searchBarCancelButtonClicked:self.searchBar];
    [self searchBarCancelButtonClicked:self.feedSearchBar];
    [self searchBarCancelButtonClicked:self.popularSearchBar];
    self.createVC = [[CreatePlaceViewController alloc] init];
    self.createVC.delegate = self;
    self.createVC.view.frame = CGRectMake(self.view.frame.size.width, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:self.createVC.view];
    [self addChildViewController:self.createVC];
    [self.createVC didMoveToParentViewController:self];
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.createVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                          [self searchBarCancelButtonClicked:self.searchBar];
                     }
                     completion:^(BOOL finished) {
                     }];
}

#pragma mark CreatePlaceViewControllerDelegate

-(void)closeCreatePlaceVC {
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.createVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.createVC.view removeFromSuperview];
                         [self.createVC removeFromParentViewController];
                         self.createVC = nil;
                     }];
}

#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
    [self.dismissSearchView setHidden:NO];
    self.searchResultsTableView.hidden = NO;
    
    
    if ([self.searchResultsArray count] == 0) {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        self.searchResultsArray = [[NSMutableArray alloc] init];
        self.searchResultsArray = [sharedDataManager.placesArray mutableCopy];
        [self.searchResultsTableView reloadData];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text=@"";
    
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    
    self.searchResultsArray = nil;
    [self.searchResultsTableView reloadData];
    self.searchResultsTableView.hidden = YES;
    [self.dismissSearchView setHidden:YES];
    self.hasSearched = NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.searchResultsTableView.hidden = NO;
    [self loadPlacesForSearch:searchBar.text];
    [self.dismissSearchView setHidden:YES];
    [Flurry logEvent:@"User_searches_from_main_page"];
    self.hasSearched = YES;
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchResultsTableView) {
        return SEARCH_RESULTS_CELL_HEIGHT;
    } else {
        if (indexPath.row == 0) {
            return SEARCH_BAR_HEIGHT;
        }
        PFObject *object;
        if (tableView == self.followingActivitytsTableView) {
            object = [self.followingActivityArray objectAtIndex:indexPath.row - 1];
        } else {
            object = [self.nearbyActivityArray objectAtIndex:indexPath.row - 1];
        }
        if ([[object objectForKey:@"type"] isEqualToString:@"photo"]) {
            NSString *userName = [[object objectForKey:@"user"] objectForKey:@"firstName"];
            NSString * placeName = [object objectForKey:@"placeName"];
            NSString *content = [object objectForKey:@"content"];
            NSString *contentString;
            if (content && ![content isEqualToString:@""]) {
               contentString = [NSString stringWithFormat:@"%@ posted a photo to %@: \n\"%@\"", userName, placeName, content];
            } else {
               contentString = [NSString stringWithFormat:@"%@ posted a photo to %@", userName, placeName];
            }
            UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
            CGRect textRect = [contentString boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 60.0, 1000.0)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName:montserrat}
                                                          context:nil];
            return self.view.frame.size.width + textRect.size.height + 70.0;
        } else if ([[object objectForKey:@"type"] isEqualToString:@"comment"]) {
            NSString *userName = [[object objectForKey:@"user"] objectForKey:@"firstName"];
            NSString * placeName = [object objectForKey:@"placeName"];
            NSString *content = [object objectForKey:@"content"];
            NSString *contentString = [NSString stringWithFormat:@"%@ commented on %@: \n\n\"%@\"", userName, placeName, content];
            UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
            CGRect textRect = [contentString boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 60.0, 1000.0)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName:montserrat}
                                                          context:nil];
            return textRect.size.height + 70.0;
        } else {
            NSString *userName = [[object objectForKey:@"user"] objectForKey:@"firstName"];
            NSString * placeName = [object objectForKey:@"placeName"];
            NSString *contentString = [NSString stringWithFormat:@"%@ tethred to %@", userName, placeName];
            UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
            CGRect textRect = [contentString boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 60.0, 1000.0)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName:montserrat}
                                                          context:nil];
            return textRect.size.height + 70.0;
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchResultsTableView) {
        return [self.searchResultsArray count] + 1;
    } else if (tableView == self.followingActivitytsTableView){
        return [self.followingActivityArray count] + 1;
    } else {
        return [self.nearbyActivityArray count] + 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchResultsTableView) {
        if (!self.hasSearched) {
            if (indexPath.row == 0) {
                UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:18];
                UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 60.0)];
                [button setTitle:@"Create a location" forState:UIControlStateNormal];
                [button setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
                button.titleLabel.font = montserrat;
                [button addTarget:self action:@selector(createPlace) forControlEvents:UIControlEventTouchUpInside];
                UIImageView *pinImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PinIcon"]];
                pinImageView.frame = CGRectMake(self.view.frame.size.width - 80.0 + 10.0, 10.0, 21, 38);
                UITableViewCell *cell = [[UITableViewCell alloc] init];
                [cell addSubview:button];
                [cell addSubview:pinImageView];
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
    } else {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, SEARCH_BAR_HEIGHT)];
            
            UIView *searchBarBackground = [[UIView alloc] initWithFrame:cell.frame];
            [searchBarBackground setBackgroundColor:[UIColor whiteColor]];
            [searchBarBackground setAlpha:0.95];
            [cell addSubview:searchBarBackground];
            if (tableView == self.followingActivitytsTableView) {
                [searchBarBackground addSubview:self.feedSearchBar];
            } else {
                [searchBarBackground addSubview:self.popularSearchBar];
            }
            return cell;
        } else {
            if (tableView == self.followingActivitytsTableView) {
                ActivityCell *cell = [[ActivityCell alloc] init];
                cell.delegate = self;
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                [cell setActivityObject:[self.followingActivityArray objectAtIndex:indexPath.row - 1]];
                return cell;
            } else {
                ActivityCell *cell = [[ActivityCell alloc] init];
                cell.delegate = self;
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                [cell setActivityObject:[self.nearbyActivityArray objectAtIndex:indexPath.row - 1]];
                return cell;
            }
        }
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (scrollView == self.followingActivitytsTableView || scrollView == self.nearbyActivitytsTableView) {
        if (scrollView.contentOffset.y > 0) {
            if (self.lastContentOffset < scrollView.contentOffset.y) {
                self.difference = 0.0;
                if (self.backView.frame.origin.y == 0.0) {
                    [UIView animateWithDuration:0.2
                                     animations:^{
                                         self.backView.frame = CGRectMake(0.0, -82.0, self.view.frame.size.width, self.view.frame.size.height + 20.0);
                                     }];
                }
                self.lastContentOffset = scrollView.contentOffset.y;
            } else if (self.lastContentOffset > scrollView.contentOffset.y) {
                if (self.backView.frame.origin.y == -82.0) {
                    self.difference += (self.lastContentOffset - scrollView.contentOffset.y);
                    CGFloat offset = 0.0;
                    if (!self.followingActivitytsTableView.hidden) {
                        offset = self.followingActivitytsTableView.contentOffset.y;
                    } else {
                        offset = self.nearbyActivitytsTableView.contentOffset.y;
                    }
                    
                    if (self.difference > 200.0 || offset < 40.0) {
                        [UIView animateWithDuration:0.2
                                         animations:^{
                                             self.backView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
                                             self.difference = 0.0;
                                         }];
                    }
                }
                self.lastContentOffset = scrollView.contentOffset.y;
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchResultsTableView ) {
        [self.view endEditing:YES];
        if (!self.hasSearched && indexPath.row == 0) {
            [self createPlace];
            return;
        }
        
        if (indexPath.row >= [self.searchResultsArray count]) {
            return;
        }
        SearchResultCell *cell = (SearchResultCell*)[tableView cellForRowAtIndexPath:indexPath];
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if (![sharedDataManager.foursquarePlacesDictionary objectForKey:cell.place.placeId]) {
            [sharedDataManager.foursquarePlacesDictionary setObject:cell.place forKey:cell.place.placeId];
            if ([self.delegate respondsToSelector:@selector(newPlaceAdded)]) {
                [self.delegate newPlaceAdded];
            }
        }

        if ([self.delegate respondsToSelector:@selector(openPageForPlaceWithId:)]) {
            [self.delegate openPageForPlaceWithId:cell.place.placeId];
          [Flurry logEvent:@"User_opens_place_page_from_main_search"];
        }
        self.hasSearched = NO;
        [self searchBarCancelButtonClicked:self.searchBar];
        [self searchBarCancelButtonClicked:self.feedSearchBar];
        [self searchBarCancelButtonClicked:self.popularSearchBar];
    }
}

// Search foursquare data call
- (void)loadPlacesForSearch:(NSString*)search {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    NSString *today = [formatter stringFromDate:[NSDate date]];
    
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
        [self processSearchResults:jsonDict forSearch:search];
        [Flurry logEvent:@"Foursquare_User_Search"];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure");
        [self localSearchWithSearch:search];
    }];
    [operation start];
}

- (void)processSearchResults:(NSDictionary *)json forSearch:(NSString*)search{
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSDictionary *response = [json objectForKey:@"response"];
    self.searchResultsArray = [[NSMutableArray alloc] init];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    for (id key in sharedDataManager.tethrPlacesDictionary) {
        Place *place = [sharedDataManager.tethrPlacesDictionary objectForKey:key];
        if ([[place.name lowercaseString] rangeOfString:[search lowercaseString]].location != NSNotFound) {
            [self.searchResultsArray addObject:place];
        }
    }
    
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
        
        [self.searchResultsArray addObject:newPlace];
    }
    [self.searchResultsTableView reloadData];
}

-(void)localSearchWithSearch:(NSString*)search {
    self.searchResultsArray = [[NSMutableArray alloc] init];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    for (Place *place in sharedDataManager.placesArray) {
        if (place.name ) {
            if ([[place.name lowercaseString] rangeOfString:[search lowercaseString]].location != NSNotFound) {
                [self.searchResultsArray addObject:place];
            }
        }
    }
    
    [self.searchResultsTableView reloadData];
}

@end
