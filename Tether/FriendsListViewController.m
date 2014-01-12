//
//  FriendsListViewController.m
//  Tether
//
//  Created by Laura Smith on 12/11/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "Friend.h"
#import "FriendAtPlaceCell.h"
#import "FriendsListViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#define BORDER_WIDTH 4.0
#define BOTTOM_BAR_HEIGHT 60.0
#define CELL_HEIGHT 60.0
#define HEADER_HEIGHT 30.0
#define NAME_LABEL_OFFSET_X 70.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 50.0
#define STATUS_BAR_HEIGHT 20.0

@interface FriendsListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) UITableView * friendsTableView;
@property (retain, nonatomic) UITableViewController * friendsTableViewController;
@property (retain, nonatomic) NSMutableArray * friendsOfFriendsArray;
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UIButton * backButton;
@property (retain, nonatomic) UIButton *backButtonLarge;
@end

@implementation FriendsListViewController

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
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50.0)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    UILabel *placeLabel = [[UILabel alloc] initWithFrame:CGRectMake(30.0, 10.0, self.view.frame.size.width, 40.0)];
    placeLabel.text = self.place.name;
    [placeLabel setTextColor:[UIColor whiteColor]];
    UIFont *champagneBold = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:24];
    placeLabel.font = champagneBold;
    [self.topBar addSubview:placeLabel];
    [self.view addSubview:self.topBar];
    
    // left panel view button setup
    UIImage *leftPanelButtonImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(10.0,  (self.topBar.frame.size.height) / 2.0, 10.0, 10.0)];
    [self.backButton setImage:leftPanelButtonImage forState:UIControlStateNormal];
    [self.view addSubview:self.backButton];
    [self.backButton addTarget:self action:@selector(closeFriendsView) forControlEvents:UIControlEventTouchDown];
    
    self.backButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, (self.view.frame.size.width) / 4.0, 50.0)];
    [self.backButtonLarge addTarget:self action:@selector(closeFriendsView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButtonLarge];
    
    //set up friends going out table view
    self.friendsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.topBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    [self.friendsTableView setSeparatorColor:UIColorFromRGB(0xD6D6D6)];
    [self.friendsTableView setDataSource:self];
    [self.friendsTableView setDelegate:self];
    self.friendsTableView.showsVerticalScrollIndicator = NO;
    
    [self.view addSubview:self.friendsTableView];
    
    self.friendsTableViewController = [[UITableViewController alloc] init];
    self.friendsTableViewController.tableView = self.friendsTableView;
    
    self.friendsOfFriendsArray = [[NSMutableArray alloc] init];
    [self loadFriendsOfFriends];
}

-(void)closeFriendsView {
    if ([self.delegate respondsToSelector:@selector(closeFriendsView)]) {
        [self.delegate closeFriendsView];
    }
}

-(void)loadFriendsOfFriends {
    NSMutableArray *allFriendsOfFriends = [[NSMutableArray alloc] init];
    NSMutableArray *closeFriendsAtPlace = [[NSMutableArray alloc] init];
    for (Friend *friend in self.friendsArray) {
        [closeFriendsAtPlace addObject:friend.friendID];
        [allFriendsOfFriends addObjectsFromArray:friend.friendsArray];
    }
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [closeFriendsAtPlace addObject:sharedDataManager.facebookId];

    PFQuery *query = [PFQuery queryWithClassName:@"Commitment"];
    [query whereKey:@"facebookId" containedIn:allFriendsOfFriends];
    [query whereKey:@"facebookId" notContainedIn:closeFriendsAtPlace];
    [query whereKey:@"placeId" equalTo:self.place.placeId];
    NSDate *startTime = [self getStartTime];
    [query whereKey:@"dateCommitted" greaterThan:startTime];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *friendsOfFriendsIdsArray = [[NSMutableArray alloc] init];
            for (PFObject * object in objects) {
                [friendsOfFriendsIdsArray addObject:object[@"facebookId"]];
            }
            
            PFQuery *facebookFriendsQuery = [PFUser query];
            [facebookFriendsQuery whereKey:@"facebookId" containedIn:friendsOfFriendsIdsArray];
            
            [facebookFriendsQuery findObjectsInBackgroundWithBlock:^(NSArray *userObjects, NSError *error) {
                if (!error) {
                    NSMutableDictionary* friendsOfFriendsDictionary = [[NSMutableDictionary alloc] init];
                    for (PFUser *user in userObjects) {
                        Friend *friend;
                        friend = [[Friend alloc] init];
                        if ([friendsOfFriendsDictionary objectForKey:user[@"facebookId"]]) {
                            friend = [friendsOfFriendsDictionary objectForKey:user[@"facebookId"]];
                            friend.mutualFriends += 1;
                        } else {
                            friend.friendID = user[@"facebookId"];
                            friend.name = user[@"displayName"];
                            friend.placeId = self.place.placeId;
                            friend.status = [user[@"status"] boolValue];
                            friend.statusMessage = user[@"statusMessage"];
                            friend.mutualFriends = 1;
                        }
                        
                        [friendsOfFriendsDictionary setObject:friend forKey:friend.friendID];
                    }
                    for (id key in friendsOfFriendsDictionary) {
                        [self.friendsOfFriendsArray addObject:[friendsOfFriendsDictionary objectForKey:key]];
                    }
                    NSSortDescriptor *mutualFriendsDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"mutualFriends" ascending:NO];
                    [self.friendsOfFriendsArray sortUsingDescriptors:[NSArray arrayWithObjects:mutualFriendsDescriptor, nil]];
                    
                    [self.friendsTableView reloadData];
                }
            }];
        }
    }];
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

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return HEADER_HEIGHT;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, HEADER_HEIGHT)];
    [view setBackgroundColor:UIColorFromRGB(0x8e0528)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 5.0, tableView.frame.size.width, HEADER_HEIGHT - 5.0)];
    [label setTextColor:UIColorFromRGB(0xD6D6D6)];
    UIFont *champagne = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:16.0];
    [label setFont:champagne];
    if(section == 0) {
        NSString *headerString = [NSString stringWithFormat:@"Friends Going Here (%lu)", (unsigned long)[self.friendsArray count]];
        [label setText:headerString];
    } else {
        NSString *headerString = [NSString stringWithFormat:@"Friends of Friends Going Here (%lu)", (unsigned long)[self.friendsOfFriendsArray count]];
        [label setText:headerString];
    }
    [view addSubview:label];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [self.friendsArray count];
    } else {
        return [self.friendsOfFriendsArray count];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
        return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FriendAtPlaceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[FriendAtPlaceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    if (indexPath.section == 0) {
       [cell setFriend:[self.friendsArray objectAtIndex:indexPath.row]];
    } else {
        [cell setFriend:[self.friendsOfFriendsArray objectAtIndex:indexPath.row]];
    }

    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
