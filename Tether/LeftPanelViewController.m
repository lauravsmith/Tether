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
#import "LeftPanelViewController.h"

#define CELL_HEIGHT 65
#define HEADER_HEIGHT 50.0
#define NAME_OFFSET_X 80.0
#define NAME_OFFSET_Y 20.0
#define PANEL_WIDTH 60
#define PADDING 10
#define PROFILE_PICTURE_BORDER_WIDTH 4.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define SEARCH_BAR_HEIGHT 60.0
#define SECOND_TABLE_OFFSET_Y 350.0
#define TABLE_HEIGHT 400.0

@interface LeftPanelViewController ()<UITableViewDelegate, UITableViewDataSource, FriendCellDelegate, UIScrollViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UITableView *friendsGoingOutTableView;
@property (nonatomic, strong) UITableViewController *friendsGoingOutTableViewController;
@property (nonatomic, strong) UITableView *friendsNotGoingOutTableView;
@property (nonatomic, strong) UITableViewController *friendsNotGoingOutTableViewController;
@property (nonatomic, strong) UITableView *friendsUndecidedTableView;
@property (nonatomic, strong) UITableViewController *friendsUndecidedTableViewController;
@property (retain, nonatomic) UIScrollView * scrollView;
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
    
    self.scrollView=[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 60.0, self.view.frame.size.height)];
    self.scrollView.delegate = self;
    [self.scrollView setBackgroundColor:[UIColor whiteColor]];
    self.scrollView.scrollEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    
    [self.view addSubview:self.scrollView];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.scrollView addSubview:self.refreshControl];
    
    UIView *searchBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, SEARCH_BAR_HEIGHT)];
    [searchBarBackground setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.scrollView addSubview:searchBarBackground];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.scrollView.frame.size.width, SEARCH_BAR_HEIGHT)];
    self.searchBar.delegate = self;
    [self.searchBar setBackgroundImage:[UIImage new]];
    [self.searchBar setTranslucent:YES];
    self.searchBar.layer.cornerRadius = 5.0;
    
    [self.scrollView addSubview:self.searchBar];
    
    //set up friends going out table view
    self.friendsGoingOutTableView = [[UITableView alloc] init];
    self.friendsGoingOutTableView.frame = CGRectMake(0.0, self.searchBar.frame.origin.y + self.searchBar.frame.size.height, self.scrollView.frame.size.width, self.view.frame.size.height);
    [self.friendsGoingOutTableView setSeparatorColor:UIColorFromRGB(0xc8c8c8)];
    [self.friendsGoingOutTableView setDataSource:self];
    [self.friendsGoingOutTableView setDelegate:self];
    self.friendsGoingOutTableView.showsVerticalScrollIndicator = NO;

    [self.scrollView addSubview:self.friendsGoingOutTableView];
    
    self.friendsGoingOutTableViewController = [[UITableViewController alloc] init];
    self.friendsGoingOutTableViewController.tableView = self.friendsGoingOutTableView;
    [self.friendsGoingOutTableView reloadData];
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.searchBar.frame.size.height + self.friendsGoingOutTableView.frame.size.height);
    
    [self.scrollView setContentOffset:CGPointMake(0.0, SEARCH_BAR_HEIGHT) animated:YES];
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.searchBar.frame.size.height)];
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    [self.searchResultsTableView setHidden:YES];
    [self.view addSubview:self.searchResultsTableView];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    [self.searchResultsTableView reloadData];
}

-(void)updateFriendsList {
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [sharedDataManager.tetherFriendsGoingOut sortUsingDescriptors:[NSArray arrayWithObjects:nameDescriptor, nil]];
    [sharedDataManager.tetherFriendsNotGoingOut sortUsingDescriptors:[NSArray arrayWithObjects:nameDescriptor, nil]];
    [sharedDataManager.tetherFriendsUndecided sortUsingDescriptors:[NSArray arrayWithObjects:nameDescriptor, nil]];
    
    [self.friendsGoingOutTableView reloadData];
    [self.friendsNotGoingOutTableView reloadData];
    [self.friendsUndecidedTableView reloadData];
}

- (void)searchFriends:(NSString*)search {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.searchResultsArray = [[NSMutableArray alloc] init];
    for (Friend *friend in sharedDataManager.tetherFriendsGoingOut) {
        if (friend.name ) {
            if ([friend.name rangeOfString:search].location != NSNotFound) {
                [self.searchResultsArray addObject:friend];
            }
        }
    }
    
    for (Friend *friend in sharedDataManager.tetherFriendsNotGoingOut) {
        if (friend.name ) {
            if ([friend.name rangeOfString:search].location != NSNotFound) {
                [self.searchResultsArray addObject:friend];
            }
        }
    }
    
    for (Friend *friend in sharedDataManager.tetherFriendsUndecided) {
        if (friend.name ) {
            if ([friend.name rangeOfString:search].location != NSNotFound) {
                [self.searchResultsArray addObject:friend];
            }
        }
    }
    [self.searchResultsTableView reloadData];
}

-(void)hideSearchBar {
   [self.scrollView setContentOffset:CGPointMake(0.0, SEARCH_BAR_HEIGHT) animated:YES];
    CGRect frame = self.friendsGoingOutTableView.frame;
    frame.size.height = self.view.frame.size.height;
    self.friendsGoingOutTableView.frame = frame;
}

-(void)showSearchBar {
   [self.scrollView setContentOffset:CGPointMake(0.0, 0.0) animated:YES];
    CGRect frame = self.friendsGoingOutTableView.frame;
    frame.size.height = self.view.frame.size.height - SEARCH_BAR_HEIGHT;
    self.friendsGoingOutTableView.frame = frame;
}

#pragma mark UITableViewDataSource Methods

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (tableView == self.friendsGoingOutTableView) {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HEADER_HEIGHT)];
        [header setBackgroundColor:UIColorFromRGB(0x8e0528)];
        UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:header.frame];
        [goingOutLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
        UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 0, 50.0, 30.0)];
        [countLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
        UIFont *champagneBold = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:16.0f];
        goingOutLabel.font = champagneBold;
        if (section == 0) {
            goingOutLabel.text = @"Tethrd";
            countLabel.text = [NSString stringWithFormat:@"(%lu)",(unsigned long)[sharedDataManager.tetherFriendsGoingOut count]];
        } else if (section == 1) {
            goingOutLabel.text = @"Going Out";
            countLabel.text = [NSString stringWithFormat:@"(%lu)",(unsigned long)[sharedDataManager.tetherFriendsNotGoingOut count]];
        } else {
            goingOutLabel.text = @"Undecided";
        }
        CGSize textLabelSize = [goingOutLabel.text sizeWithAttributes:@{NSFontAttributeName: champagneBold}];
        CGSize numberLabelSize = [countLabel.text sizeWithAttributes:@{NSFontAttributeName: champagneBold}];
        goingOutLabel.frame = CGRectMake(10.0, (header.frame.size.height - textLabelSize.height) / 2.0 , textLabelSize.width, textLabelSize.height);
        countLabel.frame = CGRectMake(goingOutLabel.frame.origin.x + goingOutLabel.frame.size.width + PADDING, goingOutLabel.frame.origin.y, numberLabelSize.width, numberLabelSize.height);
        [header addSubview:goingOutLabel];
        [header addSubview:countLabel];
        return header;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.friendsGoingOutTableView) {
       return HEADER_HEIGHT;
    } else {
        return 0.0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.friendsGoingOutTableView) {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if (section == 0) {
            return [sharedDataManager.tetherFriendsGoingOut count];
        } else if (section == 1) {
            return [sharedDataManager.tetherFriendsNotGoingOut count];
        } else {
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
        if (!cell) {
            cell = [[FriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
            cell.delegate = self;
        }
        
        if (indexPath.section == 0) {
            [cell setFriend:[sharedDataManager.tetherFriendsGoingOut objectAtIndex:indexPath.row]];
        } else if (indexPath.section == 1) {
            [cell setFriend:[sharedDataManager.tetherFriendsNotGoingOut objectAtIndex:indexPath.row]];
        } else {
            [cell setFriend:[sharedDataManager.tetherFriendsUndecided objectAtIndex:indexPath.row]];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
        return 3;
    } else {
        return 1;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.searchBar endEditing:YES];
    if (tableView == self.searchResultsTableView) {
        [self.searchResultsTableView setHidden:YES];
        Friend *friend = [self.searchResultsArray objectAtIndex:indexPath.row];
        

        [self.searchBar setShowsCancelButton:NO animated:YES];
        self.searchBar.text = @"";
        self.searchResultsArray = nil;
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        
        [self hideSearchBar];
        [self.friendsGoingOutTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                                             atScrollPosition:UITableViewScrollPositionTop animated:NO];
        
        if ([sharedDataManager.tetherFriendsGoingOut containsObject:friend]) {
            [self.friendsGoingOutTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[sharedDataManager.tetherFriendsGoingOut indexOfObject:friend] inSection:0]
                                                 atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else if ([sharedDataManager.tetherFriendsNotGoingOut containsObject:friend]) {
            [self.friendsGoingOutTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[sharedDataManager.tetherFriendsNotGoingOut indexOfObject:friend] inSection:1]
                                                 atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else if ([sharedDataManager.tetherFriendsUndecided containsObject:friend]) {
            [self.friendsGoingOutTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[sharedDataManager.tetherFriendsUndecided indexOfObject:friend] inSection:2]
                                                 atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }

    }
}

#pragma mark FriendCellDelegate methods

-(void)goToPlaceInListView:(id)placeId {
    if ([self.delegate respondsToSelector:@selector(goToPlaceInListView:)]) {
        [self.delegate goToPlaceInListView:placeId];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UIScrollView Delegate methods

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView == self.scrollView) {
        if (scrollView.contentOffset.y < SEARCH_BAR_HEIGHT / 4 && scrollView.contentOffset.y > 0) {
            [self showSearchBar];
        } else if (scrollView.contentOffset.y > SEARCH_BAR_HEIGHT / 4 && scrollView.contentOffset.y < SEARCH_BAR_HEIGHT) {
            [self hideSearchBar];
        }
        
        if (scrollView.contentOffset.y < - 100.0) {
            [self refresh];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.friendsGoingOutTableView) {
        if (scrollView.contentOffset.y <= 0) {
            scrollView.contentOffset = CGPointMake(0, 0);
        }
    }
}

-(void)refresh {
    [self.refreshControl beginRefreshing];
    [self performSelector:@selector(endRefresh:) withObject:self.refreshControl afterDelay:2.0f];
    if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
        [self.delegate pollDatabase];
    }
}

- (void)endRefresh:(UIRefreshControl *)refresh
{
    [refresh performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:NO];
    [self showSearchBar];
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

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchResultsTableView.hidden = NO;
    [self searchFriends:searchBar.text];
}

@end
