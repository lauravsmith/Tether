//
//  ManageFriendsViewController.m
//  Tether
//
//  Created by Laura Smith on 2/11/2014.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "ManageFriendCell.h"
#import "ManageFriendsViewController.h"

#define CELL_HEIGHT 65
#define SEARCH_BAR_HEIGHT 50.0
#define SEARCH_BAR_WIDTH 270.0
#define STATUS_BAR_HEIGHT 20.0

@interface ManageFriendsViewController () <ManageFriendCellDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (retain, nonatomic) UISearchBar * searchBar;
@property (retain, nonatomic) NSMutableArray *friendsArray;
@property (retain, nonatomic) NSMutableArray *friendsSearchArray;
@property (nonatomic, strong) UITableView *friendsTableView;
@property (nonatomic, strong) UITableViewController *friendsTableViewController;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UIButton *backButtonLarge;
@property (nonatomic, assign) BOOL searching;

@end

@implementation ManageFriendsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
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
        self.searchBar.placeholder = @"Search friends on tethr...";
        [self.view addSubview:self.searchBar];
        
        //set up friends going out table view
        self.friendsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, STATUS_BAR_HEIGHT + self.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.searchBar.frame.size.height - STATUS_BAR_HEIGHT)];
        [self.friendsTableView setSeparatorColor:UIColorFromRGB(0xc8c8c8)];
        [self.friendsTableView setDataSource:self];
        [self.friendsTableView setDelegate:self];
        self.friendsTableView.showsVerticalScrollIndicator = NO;
        self.friendsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:self.friendsTableView];
        
        self.friendsTableViewController = [[UITableViewController alloc] init];
        self.friendsTableViewController.tableView = self.friendsTableView;
        
        [self addFriendsToArray];
        
        [self.friendsTableView reloadData];
        
        UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
        self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, (SEARCH_BAR_HEIGHT + STATUS_BAR_HEIGHT + 7.0) / 2.0, 7.0, 11.0)];
        [self.backButton setImage:triangleImage forState:UIControlStateNormal];
        [self.backButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:self.backButton];
        
        self.backButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, (self.view.frame.size.width - SEARCH_BAR_WIDTH) / 2.0, STATUS_BAR_HEIGHT + 60.0)];
        [self.backButtonLarge addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
        [self.view addSubview:self.backButtonLarge];
    }
    return self;
}

-(void)addFriendsToArray {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.friendsArray = [[NSMutableArray alloc] init];
    self.friendsSearchArray = [[NSMutableArray alloc] init];
    
    for (id key in sharedDataManager.tetherFriendsDictionary) {
        Friend *friend = [sharedDataManager.tetherFriendsDictionary objectForKey:key];
        if (![friend.friendID isEqualToString:sharedDataManager.facebookId]) {
            [self.friendsArray addObject:friend];
            [self.friendsSearchArray addObject:friend];
        }
    }
    
    for (Friend *friend in sharedDataManager.blockedFriends) {
        [self.friendsArray addObject:friend];
        [self.friendsSearchArray addObject:friend];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

#pragma mark gesture handlers

-(void)moveBack:(id)sender {
    [[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];
    
    CGPoint velocity = [(UIPanGestureRecognizer*)sender velocityInView:[sender view]];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if(velocity.x > 0) {
            [self closeView];
        }
    }
}

-(void)closeView {
    if ([self.delegate respondsToSelector:@selector(closeManageFriendsView)]) {
        [self.delegate closeManageFriendsView];
    }
}

#pragma mark ManagerFriendCellDelegate

- (void)blockFriend:(Friend*)friend setBlocked:(BOOL)block {
    if ([self.delegate respondsToSelector:@selector(blockFriend:block:)]) {
        [self.delegate blockFriend:friend block:block];
    }
    
    if (self.searching) {
        [self searchBarCancelButtonClicked:self.searchBar];
    }
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   return [self.friendsSearchArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ManageFriendCell *cell = [[ManageFriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    cell.delegate = self;
    [cell setFriend:[self.friendsSearchArray objectAtIndex:indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // unblock friend
}

#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searching = YES;
    [self.searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searching = NO;
    searchBar.text=@"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar endEditing:YES];
    
    self.friendsSearchArray = [self.friendsArray mutableCopy];
    
    [self.friendsTableView reloadData];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self searchFriends:searchBar.text];
}

- (void)searchFriends:(NSString*)search {
    self.friendsSearchArray = [[NSMutableArray alloc] init];
    NSMutableArray *searchResults = [[NSMutableArray alloc] init];
    for (Friend *friend in self.friendsArray) {
        if (friend.name ) {
            if ([[friend.name lowercaseString] rangeOfString:[search lowercaseString]].location != NSNotFound) {
                [searchResults addObject:friend];
            }
        }
    }
    
    self.friendsSearchArray = searchResults;
    [self.friendsTableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
