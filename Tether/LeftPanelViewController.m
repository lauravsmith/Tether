//
//  LeftPanelViewController.m
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "FriendAtPlaceCell.h"
#import "FriendCell.h"
#import "FriendInviteViewController.h"
#import "LeftPanelViewController.h"

#define CELL_HEIGHT 65
#define HEADER_HEIGHT 40.0
#define MIN_CELLS 7
#define NAME_OFFSET_X 80.0
#define NAME_OFFSET_Y 20.0
#define PANEL_WIDTH 60
#define PADDING 10
#define PROFILE_PICTURE_BORDER_WIDTH 4.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define SEARCH_BAR_HEIGHT 65.0
#define SECOND_TABLE_OFFSET_Y 350.0
#define STATUS_BAR_HEIGHT 20.0
#define TABLE_HEIGHT 400.0

@interface LeftPanelViewController ()<UITableViewDelegate, UITableViewDataSource, FriendCellDelegate, UIScrollViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UITableView *friendsGoingOutTableView;
@property (nonatomic, strong) UITableViewController *friendsGoingOutTableViewController;
@property (retain, nonatomic) UIRefreshControl * refreshControl;
@property (retain, nonatomic) UISearchBar * searchBar;
@property (retain, nonatomic) NSMutableArray *searchResultsArray;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UITableViewController *searchResultsTableViewController;

@end

@implementation LeftPanelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - PANEL_WIDTH, SEARCH_BAR_HEIGHT)];
    
    //set up friends going out table view
    self.friendsGoingOutTableView = [[UITableView alloc] init];
    self.friendsGoingOutTableView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width - PANEL_WIDTH, self.view.frame.size.height);
    [self.friendsGoingOutTableView setSeparatorColor:UIColorFromRGB(0xc8c8c8)];
    [self.friendsGoingOutTableView setDataSource:self];
    [self.friendsGoingOutTableView setDelegate:self];
    self.friendsGoingOutTableView.showsVerticalScrollIndicator = NO;

    [self.view addSubview:self.friendsGoingOutTableView];
    
    self.friendsGoingOutTableViewController = [[UITableViewController alloc] init];
    self.friendsGoingOutTableViewController.tableView = self.friendsGoingOutTableView;
    [self.friendsGoingOutTableView reloadData];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = UIColorFromRGB(0x8e0528);
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    self.friendsGoingOutTableViewController.refreshControl = self.refreshControl;
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.searchBar.frame.size.height, self.view.frame.size.width - PANEL_WIDTH, self.view.frame.size.height - self.searchBar.frame.size.height)];
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    [self.searchResultsTableView setHidden:YES];
    [self.view addSubview:self.searchResultsTableView];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    [self.searchResultsTableView reloadData];
    
    [self hideSearchBar];
}

-(void)updateFriendsList {
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [sharedDataManager.tetherFriendsGoingOut sortUsingDescriptors:[NSArray arrayWithObjects:nameDescriptor, nil]];
    [sharedDataManager.tetherFriendsNotGoingOut sortUsingDescriptors:[NSArray arrayWithObjects:nameDescriptor, nil]];
    [sharedDataManager.tetherFriendsUndecided sortUsingDescriptors:[NSArray arrayWithObjects:nameDescriptor, nil]];
    
    [self.friendsGoingOutTableView reloadData];
}

- (void)searchFriends:(NSString*)search {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.searchResultsArray = [[NSMutableArray alloc] init];
    for (Friend *friend in sharedDataManager.tetherFriendsGoingOut) {
        if (friend.name ) {
            if ([[friend.name lowercaseString] rangeOfString:[search lowercaseString]].location != NSNotFound) {
                [self.searchResultsArray addObject:friend];
            }
        }
    }
    
    for (Friend *friend in sharedDataManager.tetherFriendsNotGoingOut) {
        if (friend.name ) {
            if ([[friend.name lowercaseString] rangeOfString:[search lowercaseString]].location != NSNotFound) {
                [self.searchResultsArray addObject:friend];
            }
        }
    }
    
    for (Friend *friend in sharedDataManager.tetherFriendsUndecided) {
        if (friend.name ) {
            if ([[friend.name lowercaseString] rangeOfString:[search lowercaseString]].location != NSNotFound) {
                [self.searchResultsArray addObject:friend];
            }
        }
    }
    [self.searchResultsTableView reloadData];
}

-(void)hideSearchBar {
    if ([self.searchBar.text isEqualToString:@""]) {
       [self.friendsGoingOutTableView setContentOffset:CGPointMake(0.0, SEARCH_BAR_HEIGHT - 15.0) animated:YES];
    }
}

-(void)showSearchBar {
   [self.friendsGoingOutTableView setContentOffset:CGPointMake(0.0, 0.0) animated:YES];
}

-(void)refresh {
    [self.refreshControl beginRefreshing];
    [self performSelector:@selector(endRefresh:) withObject:self.refreshControl afterDelay:1.0f];
    if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
        [self.delegate pollDatabase];
    }
}

- (void)endRefresh:(UIRefreshControl *)refresh
{
    [refresh performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:NO];
    [self showSearchBar];
}

#pragma mark UITableViewDataSource Methods

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.friendsGoingOutTableView) {
        if (section == 0) {
            UIView *searchBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - PANEL_WIDTH, HEADER_HEIGHT)];
            [searchBarBackground setBackgroundColor:UIColorFromRGB(0x8e0528)];
            self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - PANEL_WIDTH, SEARCH_BAR_HEIGHT)];
            self.searchBar.delegate = self;
            [self.searchBar setBackgroundImage:[UIImage new]];
            [self.searchBar setTranslucent:YES];
            self.searchBar.layer.cornerRadius = 5.0;
            self.searchBar.barTintColor = [UIColor whiteColor];
            self.searchBar.placeholder = @"Search friends...";
            [searchBarBackground addSubview:self.searchBar];
            
            return searchBarBackground;
        } else {
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HEADER_HEIGHT)];
            [header setBackgroundColor:UIColorFromRGB(0x8e0528)];
            UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:header.frame];
            [goingOutLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
            UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 0, 50.0, 30.0)];
            [countLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
            UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:16.0f];
            goingOutLabel.font = montserratBold;
            countLabel.font = montserratBold;
            if (section == 1) {
                goingOutLabel.text = @"Tethrd";
                countLabel.text = [NSString stringWithFormat:@"(%lu)",(unsigned long)[sharedDataManager.tetherFriendsGoingOut count]];
            } else if (section == 2) {
                goingOutLabel.text = @"Going Out";
                countLabel.text = [NSString stringWithFormat:@"(%lu)",(unsigned long)[sharedDataManager.tetherFriendsNotGoingOut count]];
            } else {
                goingOutLabel.text = @"Not Going Out";
            }
            CGSize textLabelSize = [goingOutLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratBold}];
            CGSize numberLabelSize = [countLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratBold}];
            goingOutLabel.frame = CGRectMake(10.0, (header.frame.size.height - textLabelSize.height) / 2.0 , textLabelSize.width, textLabelSize.height);
            countLabel.frame = CGRectMake(goingOutLabel.frame.origin.x + goingOutLabel.frame.size.width + PADDING, goingOutLabel.frame.origin.y, numberLabelSize.width, numberLabelSize.height);
            [header addSubview:goingOutLabel];
            [header addSubview:countLabel];
            return header;
        }
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.friendsGoingOutTableView) {
        if (section == 0) {
            return SEARCH_BAR_HEIGHT;
        }
       return HEADER_HEIGHT;
    } else {
        return 0.0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.friendsGoingOutTableView) {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if (section == 0) {
            return 0;
        } else if (section == 1) {
            return [sharedDataManager.tetherFriendsGoingOut count];
        } else if (section == 2) {
            return [sharedDataManager.tetherFriendsNotGoingOut count];
        } else {
            NSInteger count = [sharedDataManager.tetherFriendsNearbyDictionary count];
            if (count < MIN_CELLS) {
                NSInteger difference = MIN_CELLS - [sharedDataManager.tetherFriendsGoingOut count] - [sharedDataManager.tetherFriendsNotGoingOut count];
                return difference;
            }
            return [sharedDataManager.tetherFriendsUndecided count];
        }
    } else {
        return [self.searchResultsArray count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.friendsGoingOutTableView) {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        FriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        cell = [[FriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.delegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (indexPath.section == 1) {
            [cell setFriend:[sharedDataManager.tetherFriendsGoingOut objectAtIndex:indexPath.row]];
        } else if (indexPath.section == 2) {
            [cell setFriend:[sharedDataManager.tetherFriendsNotGoingOut objectAtIndex:indexPath.row]];
        } else if (indexPath.section == 3) {
            if (indexPath.row >= [sharedDataManager.tetherFriendsUndecided count]) {
                [cell setFriend:NULL];
                return  cell;
            }
            [cell setFriend:[sharedDataManager.tetherFriendsUndecided objectAtIndex:indexPath.row]];
        }
        [cell layoutSubviews];
        
        return cell;
    } else {
        FriendAtPlaceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (!cell) {
            cell = [[FriendAtPlaceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        }
        [cell setFriend:[self.searchResultsArray objectAtIndex:indexPath.row]];
        
        return cell;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.friendsGoingOutTableView) {
        return 4;
    } else {
        return 1;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.searchResultsTableView) {
        self.searchBar.delegate = nil;
        [self.searchResultsTableView setHidden:YES];
        Friend *friend = [self.searchResultsArray objectAtIndex:indexPath.row];
        self.friendsGoingOutTableView.scrollEnabled = YES;

        [self hideSearchBar];
        [self.friendsGoingOutTableView scrollsToTop];
        
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        
        if ([sharedDataManager.tetherFriendsGoingOut containsObject:friend]) {
            [self.friendsGoingOutTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[sharedDataManager.tetherFriendsGoingOut indexOfObject:friend] inSection:1]
                                                 atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else if ([sharedDataManager.tetherFriendsNotGoingOut containsObject:friend]) {
            [self.friendsGoingOutTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[sharedDataManager.tetherFriendsNotGoingOut indexOfObject:friend] inSection:2]
                                                 atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else if ([sharedDataManager.tetherFriendsUndecided containsObject:friend]) {
            [self.friendsGoingOutTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[sharedDataManager.tetherFriendsUndecided indexOfObject:friend] inSection:3]
                                                 atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        [self searchBarCancelButtonClicked:self.searchBar];

    }
}

#pragma mark FriendCellDelegate methods

-(void)goToPlaceInListView:(id)placeId {
    if ([self.delegate respondsToSelector:@selector(goToPlaceInListView:)]) {
        [self.delegate goToPlaceInListView:placeId];
    }
}

-(void)inviteFriend:(Friend *)friend {
    if ([self.delegate respondsToSelector:@selector(inviteFriend:)]) {
        [self.delegate inviteFriend:friend];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIScrollView Delegate methods

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
        if (scrollView.contentOffset.y < SEARCH_BAR_HEIGHT / 8 && scrollView.contentOffset.y > 0) {
            [self showSearchBar];
        } else if (scrollView.contentOffset.y > SEARCH_BAR_HEIGHT / 8 && scrollView.contentOffset.y < SEARCH_BAR_HEIGHT) {
            [self hideSearchBar];
        }
}

#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:YES animated:YES];
    [self showSearchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text=@"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar endEditing:YES];
    
    self.searchResultsArray = nil;
    [self.searchResultsTableView reloadData];
    self.searchResultsTableView.hidden = YES;
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.friendsGoingOutTableView.scrollEnabled = NO;
    self.searchResultsTableView.hidden = NO;
    [self searchFriends:searchBar.text];
}

@end
