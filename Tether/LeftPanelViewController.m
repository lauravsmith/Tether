//
//  LeftPanelViewController.m
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Constants.h"
#import "Datastore.h"
#import "FriendAtPlaceCell.h"
#import "FriendCell.h"
#import "Flurry.h"
#import "LeftPanelViewController.h"

#define CELL_HEIGHT 65
#define HEADER_HEIGHT 30.0
#define MIN_CELLS 7
#define NAME_OFFSET_X 80.0
#define NAME_OFFSET_Y 20.0
#define PANEL_WIDTH 45.0
#define PADDING 10
#define PROFILE_PICTURE_BORDER_WIDTH 4.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define SEARCH_BAR_HEIGHT 55.0
#define SEARCH_BAR_WIDTH 270.0
#define SECOND_TABLE_OFFSET_Y 350.0
#define STATUS_BAR_HEIGHT 15.0
#define TABLE_HEIGHT 400.0
#define TUTORIAL_HEADER_HEIGHT 50.0

@interface LeftPanelViewController ()<UIAlertViewDelegate ,UITableViewDelegate, UITableViewDataSource, FriendCellDelegate, UIScrollViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UITableView *friendsGoingOutTableView;
@property (nonatomic, strong) UITableViewController *friendsGoingOutTableViewController;
@property (retain, nonatomic) UIRefreshControl * refreshControl;
@property (retain, nonatomic) UISearchBar * searchBar;
@property (retain, nonatomic) NSMutableArray *searchResultsArray;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UITableViewController *searchResultsTableViewController;
@property (nonatomic, strong) UIView *tutorialView;

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
    
    self.view.layer.backgroundColor = [UIColor clearColor].CGColor;
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, SEARCH_BAR_WIDTH, SEARCH_BAR_HEIGHT)];
    
    //set up friends going out table view
    self.friendsGoingOutTableView = [[UITableView alloc] init];
    self.friendsGoingOutTableView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
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

-(void)addTutorialView {
    if  (![[self.view subviews] containsObject:self.tutorialView]) {
        NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
        if (![userDetails boolForKey:kUserDefaultsHasSeenFriendInviteTutorialKey]) {
            self.tutorialView = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - TUTORIAL_HEADER_HEIGHT, self.view.frame.size.width, TUTORIAL_HEADER_HEIGHT)];
            [self.tutorialView setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
            UILabel *tutorialLabel = [[UILabel alloc] init];
            tutorialLabel.text = @"Tap         to invite a friend to a location";
            UIFont *montserratLabelFont = [UIFont fontWithName:@"Montserrat" size:13];
            tutorialLabel.font = montserratLabelFont;
            [tutorialLabel setTextColor:UIColorFromRGB(0x8e0528)];
            CGSize size = [tutorialLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLabelFont}];
            tutorialLabel.frame = CGRectMake((self.view.frame.size.width - size.width  - PANEL_WIDTH) / 2.0, (TUTORIAL_HEADER_HEIGHT - size.height) / 2.0, size.width, size.height);
            [self.tutorialView addSubview:tutorialLabel];
            
            UIImageView *inviteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(tutorialLabel.frame.origin.x + 30.0, tutorialLabel.frame.origin.y - 2.0, 20.0, 20.0)];
            [inviteImageView setImage:[UIImage imageNamed:@"InviteIcon"]];
            [inviteImageView setBackgroundColor:[UIColor whiteColor]];
            inviteImageView.layer.cornerRadius = 6.0;
            [self.tutorialView addSubview:inviteImageView];
            
            self.tutorialView.userInteractionEnabled = YES;
            UITapGestureRecognizer *tutorialTapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tutorialTapped:)];
            [self.tutorialView addGestureRecognizer:tutorialTapGesture];
            [self.view addSubview:self.tutorialView];
        }
    }
}

- (void)tutorialTapped:(UIGestureRecognizer*)recognizer {
        [self closeTutorial];
}

-(void)closeTutorial {
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.tutorialView.alpha = 0.0;
                     } completion:^(BOOL finished) {
                         [self.tutorialView removeFromSuperview];
                         NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
                        if (![userDetails boolForKey:kUserDefaultsHasSeenFriendInviteTutorialKey]) {
                           [userDetails setBool:YES forKey:kUserDefaultsHasSeenFriendInviteTutorialKey];
                        }
                     }];
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
        if (!self.searchResultsTableView.isHidden) {
            [self searchBarCancelButtonClicked:self.searchBar];
        }
       [self.friendsGoingOutTableView setContentOffset:CGPointMake(0.0, SEARCH_BAR_HEIGHT) animated:YES];
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
            UIView *searchBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - PANEL_WIDTH, SEARCH_BAR_HEIGHT)];
            [searchBarBackground setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
            self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, STATUS_BAR_HEIGHT, SEARCH_BAR_WIDTH, SEARCH_BAR_HEIGHT - STATUS_BAR_HEIGHT)];
            self.searchBar.delegate = self;
            [self.searchBar setBackgroundImage:[UIImage new]];
            [self.searchBar setTranslucent:YES];
            self.searchBar.layer.cornerRadius = 5.0;
            self.searchBar.barTintColor = [UIColor whiteColor];
            self.searchBar.placeholder = @"Search friends...";
            [searchBarBackground addSubview:self.searchBar];
            
            return searchBarBackground;
        } else if (section == 1) {
            UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, SEARCH_BAR_HEIGHT + STATUS_BAR_HEIGHT + HEADER_HEIGHT)];
            
            UIView *friendsViewBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, SEARCH_BAR_HEIGHT + STATUS_BAR_HEIGHT)];
            [friendsViewBackground setBackgroundColor:UIColorFromRGB(0x8e0528)];
            
            UILabel *friendsLabel = [[UILabel alloc] init];
            [friendsLabel setTextColor:[UIColor whiteColor]];
            UIFont *montserratBold = [UIFont fontWithName:@"Montserrat" size:14.0f];
            friendsLabel.font = montserratBold;
            NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
            friendsLabel.text = [NSString stringWithFormat:@"Friends in %@", [userDetails objectForKey:@"city"]];
            
            CGSize textLabelSize = [friendsLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratBold}];
            friendsLabel.frame = CGRectMake((self.view.frame.size.width - PANEL_WIDTH - textLabelSize.width) / 2.0, (SEARCH_BAR_HEIGHT - textLabelSize.height) / 2.0 + STATUS_BAR_HEIGHT, MIN(textLabelSize.width, self.view.frame.size.width - PANEL_WIDTH), textLabelSize.height);
            
            [friendsViewBackground addSubview:friendsLabel];
            
            [topBar addSubview:friendsViewBackground];
            
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, friendsViewBackground.frame.size.height, self.view.frame.size.width, HEADER_HEIGHT)];
            [header setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
            UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:header.frame];
            [goingOutLabel setTextColor:UIColorFromRGB(0x8e0528)];
            UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 0, 50.0, HEADER_HEIGHT)];
            [countLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
            goingOutLabel.font = montserratBold;
            countLabel.font = montserratBold;
            goingOutLabel.text = @"tethrd";
            countLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)[sharedDataManager.tetherFriendsGoingOut count]];
            textLabelSize = [goingOutLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratBold}];
            CGSize numberLabelSize = [countLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratBold}];
            goingOutLabel.frame = CGRectMake(10.0, (header.frame.size.height - textLabelSize.height) / 2.0 , textLabelSize.width, textLabelSize.height);
            countLabel.frame = CGRectMake(goingOutLabel.frame.origin.x + goingOutLabel.frame.size.width + PADDING, goingOutLabel.frame.origin.y, numberLabelSize.width, numberLabelSize.height);
            [header addSubview:goingOutLabel];
            [header addSubview:countLabel];
            
            [topBar addSubview:header];

            return topBar;
        } else {
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HEADER_HEIGHT)];
            [header setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
            UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:header.frame];
            [goingOutLabel setTextColor:UIColorFromRGB(0x8e0528)];
            UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 0, 50.0, HEADER_HEIGHT)];
            [countLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
            UIFont *montserratBold = [UIFont fontWithName:@"Montserrat" size:14.0f];
            goingOutLabel.font = montserratBold;
            countLabel.font = montserratBold;
            if (section == 2) {
                goingOutLabel.text = @"Going Out";
                countLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)[sharedDataManager.tetherFriendsNotGoingOut count]];
            } else {
                goingOutLabel.text = @"Not Going Out";
                countLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)[sharedDataManager.tetherFriendsUndecided count]];
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
        } else if (section == 1) {
            return SEARCH_BAR_HEIGHT + STATUS_BAR_HEIGHT + HEADER_HEIGHT;
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
    if ([self.delegate respondsToSelector:@selector(openPageForPlaceWithId:)]) {
        [self.delegate openPageForPlaceWithId:placeId];
    }
}

-(void)inviteFriend:(Friend *)friend {
    if ([self.delegate respondsToSelector:@selector(inviteFriend:)]) {
        [self.delegate inviteFriend:friend];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if (![userDefaults boolForKey:kUserDefaultsHasSeenFriendInviteTutorialKey]) {
            [self closeTutorial];
        }
    }
    
     [Flurry logEvent:@"User_views_invite_page_from_friend_list"];
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
    self.searchResultsTableView.hidden = NO;
    [self searchFriends:searchBar.text];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
