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
#import "FriendsListViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#define BORDER_WIDTH 4.0
#define BOTTOM_BAR_HEIGHT 60.0
#define CELL_HEIGHT 60.0
#define NAME_LABEL_OFFSET_X 70.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 50.0

@interface FriendsListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) UITableView * friendsTableView;
@property (retain, nonatomic) UITableViewController * friendsTableViewController;
@property (retain, nonatomic) NSMutableArray * friendsOfFriendsArray;
@property (retain, nonatomic) UIView * bottomBar;
@property (retain, nonatomic) UIButton *bottomLeftButton;
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
	// Do any additional setup after loading the view.
    
    //set up friends going out table view
    self.friendsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.friendsTableView setSeparatorColor:[UIColor whiteColor]];
    [self.friendsTableView setBackgroundColor:UIColorFromRGB(0xD6D6D6)];
    [self.friendsTableView setDataSource:self];
    [self.friendsTableView setDelegate:self];
    self.friendsTableView.showsVerticalScrollIndicator = NO;
    
    [self.view addSubview:self.friendsTableView];
    
    self.friendsTableViewController = [[UITableViewController alloc] init];
    self.friendsTableViewController.tableView = self.friendsTableView;
    
    self.friendsOfFriendsArray = [[NSMutableArray alloc] init];
    [self loadFriendsOfFriends];
    
    // bottom nav bar setup
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width, BOTTOM_BAR_HEIGHT)];
    [self.bottomBar setBackgroundColor:[UIColor whiteColor]];
    
    // left panel view button setup
    UIImage *leftPanelButtonImage = [UIImage imageNamed:@"chevron-left"];
    self.bottomLeftButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 10, 30, 30)];
    [self.bottomLeftButton setImage:leftPanelButtonImage forState:UIControlStateNormal];
    [self.bottomBar addSubview:self.bottomLeftButton];
    self.bottomLeftButton.tag = 1;
    [self.bottomLeftButton addTarget:self action:@selector(closeFriendsView) forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview:self.bottomBar];
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
                    for (PFUser *user in userObjects) {
                        Friend *friend;
                        friend = [[Friend alloc] init];
                        friend.friendID = user[@"facebookId"];
                        friend.name = user[@"displayName"];
                        friend.placeId = self.place.placeId;
                        friend.status = [user[@"status"] boolValue];
                        friend.statusMessage = user[@"statusMessage"];
                        
                        [self.friendsOfFriendsArray addObject:friend];
                    }
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
    return CELL_HEIGHT;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 80.0)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, tableView.frame.size.width, 20.0)];
    [label setFont:[UIFont boldSystemFontOfSize:18]];
    if(section == 0)
        [label setText:@"Friends Going"];
    else
        [label setText:@"Friends of Friends Going"];
    
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
        return @"Friends Going";
    else
        return @"Friends of Friends";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    if (indexPath.section == 0) {
        Friend *friend = [self.friendsArray objectAtIndex:indexPath.row];
        UILabel *friendNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(NAME_LABEL_OFFSET_X, 0, 300, 40)];
        friendNameLabel.text = friend.name;
        [cell addSubview:friendNameLabel];
        FBProfilePictureView *friendProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)friend.friendID pictureCropping:FBProfilePictureCroppingSquare];
        
        friendProfilePictureView.clipsToBounds = YES;
        friendProfilePictureView.frame = CGRectMake(PROFILE_PICTURE_OFFSET_X, (cell.frame.size.height - PROFILE_PICTURE_SIZE) / 2, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
        friendProfilePictureView.layer.cornerRadius = 24.0;
        friendProfilePictureView.clipsToBounds = YES;
        [friendProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
        [friendProfilePictureView.layer setBorderWidth:BORDER_WIDTH];
        [cell addSubview:friendProfilePictureView];
    } else {
        Friend *friend = [self.friendsOfFriendsArray objectAtIndex:indexPath.row];
        UILabel *friendNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(NAME_LABEL_OFFSET_X, 0, 300, 40)];
        friendNameLabel.text = friend.name;
        [cell addSubview:friendNameLabel];
        FBProfilePictureView *friendProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)friend.friendID pictureCropping:FBProfilePictureCroppingSquare];
        
        friendProfilePictureView.clipsToBounds = YES;
        friendProfilePictureView.frame = CGRectMake(PROFILE_PICTURE_OFFSET_X, (cell.frame.size.height - PROFILE_PICTURE_SIZE) / 2, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
        friendProfilePictureView.layer.cornerRadius = 24.0;
        friendProfilePictureView.clipsToBounds = YES;
        [friendProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
        [friendProfilePictureView.layer setBorderWidth:BORDER_WIDTH];
        [cell addSubview:friendProfilePictureView];
    }

    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
