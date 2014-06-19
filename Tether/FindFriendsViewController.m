//
//  FindFriendsViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-06-17.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Constants.h"
#import "Datastore.h"
#import "FindFriendCell.h"
#import "FindFriendsViewController.h"

#import <QuartzCore/QuartzCore.h>

#define CELL_HEIGHT 60.0
#define SPINNER_SIZE 30.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

@interface FindFriendsViewController () <FindFriendCellDelegate, UITableViewDelegate, UITableViewDataSource>
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UILabel * topBarLabel;
@property (nonatomic, strong) UITableView *findFriendsTableView;
@property (nonatomic, strong) UITableViewController *findFriendsTableViewController;
@property (strong, nonatomic) NSMutableDictionary *friendsToFollowDictionary;
@property (strong, nonatomic) UIButton *doneButton;
@property (retain, nonatomic) UIView *confirmationView;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (assign, nonatomic) BOOL checkboxOn;
@property (retain, nonatomic) TethrButton *checkBox;
@end

@implementation FindFriendsViewController

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

    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:self.topBar];
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.topBarLabel = [[UILabel alloc] init];
    [self.topBarLabel setTextColor:[UIColor whiteColor]];
    self.topBarLabel.font = montserrat;
    self.topBarLabel.text = @"Find Friends";
    CGSize size = [self.topBarLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.topBarLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, (TOP_BAR_HEIGHT - size.height + STATUS_BAR_HEIGHT) / 2.0, size.width, size.height);
    self.topBarLabel.userInteractionEnabled = YES;
    [self.topBar addSubview:self.topBarLabel];
    
    self.doneButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80.0, STATUS_BAR_HEIGHT, 80.0, TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT)];
    self.doneButton.titleLabel.font = montserrat;
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(doneClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.doneButton];
    
    self.findFriendsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, self.topBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.topBar.frame.size.height)];
    [self.findFriendsTableView setDataSource:self];
    [self.findFriendsTableView setDelegate:self];
    [self.view addSubview:self.findFriendsTableView];
    
    self.findFriendsTableViewController = [[UITableViewController alloc] init];
    self.findFriendsTableViewController.tableView = self.findFriendsTableView;
    
    [self loadFriends];
    
    self.friendsToFollowDictionary = [[NSMutableDictionary alloc] init];
}

-(void)loadFriends {
    PFQuery *userQuery = [PFUser query];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.friendIdsArray = [[NSMutableArray alloc] init];
    self.friendIdsArray = [sharedDataManager.facebookFriends mutableCopy];
    [userQuery whereKey:@"facebookId" containedIn:self.friendIdsArray];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [userQuery whereKey:@"facebookId" notContainedIn:[standardUserDefaults objectForKey:@"blockedByList"]];
    [userQuery whereKey:@"facebookId" notEqualTo:[standardUserDefaults objectForKey:@"facebookId"]];
    
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.findFriendsArray = [[NSMutableArray alloc] init];
        for (PFObject *object in objects) {
            Friend *friend = [[Friend alloc] init];
            friend.friendID = object[kUserFacebookIDKey];
            friend.name = object[kUserDisplayNameKey];
            friend.firstName = object[@"firstName"];
            friend.friendsArray = object[@"tethrFriends"];
            friend.followersArray = object[@"followers"];
            friend.object = (PFUser*)object;
            friend.city = object[@"cityLocation"];
            friend.timeLastUpdated = object[kUserTimeLastUpdatedKey];
            friend.status = [object[kUserStatusKey] boolValue];
            friend.statusMessage = object[kUserStatusMessageKey];
            friend.isPrivate = [object[@"private"] boolValue];
            friend.placeId = @"";
            [self.findFriendsArray addObject:friend];
        }
        [self.findFriendsTableView reloadData];
    }];
}

-(IBAction)doneClicked:(id)sender {
    [self confirm];
    [self followerUserFriends];
}

-(void)followerUserFriends {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSMutableArray *tethrFriends = [[NSMutableArray alloc] init];
    
    for (id key in self.friendsToFollowDictionary) {
        Friend *friend = [self.friendsToFollowDictionary objectForKey:key];
        
        if (![sharedDataManager.tetherFriendsDictionary objectForKey:friend.friendID]) {
            if (friend.isPrivate) {
                // create a request
                PFObject *personalNotificationObject = [PFObject objectWithClassName:@"Request"];
                [personalNotificationObject setObject:[PFUser currentUser] forKey:@"fromUser"];
                [personalNotificationObject setObject:friend.object forKey:@"toUser"];
                [personalNotificationObject saveInBackground];
                
                NSString *messageHeader = [NSString stringWithFormat:@"%@ would like to follow you", sharedDataManager.firstName];
                [self sendUserPush:friend.object withMessage:messageHeader];
                
                NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
                NSMutableArray *requestArray = [userDetails objectForKey:@"requests"];
                if (!requestArray) {
                    requestArray= [[NSMutableArray alloc] init];
                }
                [requestArray addObject:friend.friendID];
                [userDetails setObject:requestArray forKey:@"requests"];
            } else {
                NSMutableSet *followersSet = [NSMutableSet setWithArray:[[friend.object objectForKey:@"followers"] mutableCopy]];
                [followersSet addObject:sharedDataManager.facebookId];
                NSArray *followersArray = [followersSet allObjects];
                
                [PFCloud callFunctionInBackground:@"SetFollowers"
                                   withParameters:@{@"userId": friend.friendID, @"followers": followersArray}
                                            block:^(NSArray *results, NSError *error) {
                                                if (!error) {
                                                    // this is where you handle the results and change the UI.
                                                    
                                                    
                                                } else {
                                                    NSLog(@"%@", [error description]);
                                                }
                                            }];
                
                NSString *messageHeader = [NSString stringWithFormat:@"%@ started following you", sharedDataManager.firstName];
                PFObject *personalNotificationObject = [PFObject objectWithClassName:@"PersonalNotification"];
                [personalNotificationObject setObject:[PFUser currentUser] forKey:@"fromUser"];
                [personalNotificationObject setObject:friend.object forKey:@"toUser"];
                [personalNotificationObject setObject:messageHeader forKey:@"content"];
                [personalNotificationObject setObject:@"following" forKey:@"type"];
                [personalNotificationObject saveInBackground];
                
                friend.followersArray = followersArray;
                [sharedDataManager.tetherFriendsDictionary setObject:friend forKey:friend.friendID];
                
                [self sendUserPush:friend.object withMessage:messageHeader];
            }
        }
    }
    
    PFUser *user = [PFUser currentUser];
    [user setObject:tethrFriends forKey:@"tethrFriends"];
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
            [self.delegate pollDatabase];
        }
        [self dismissConfirmation];
    }];
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [userDetails setObject:tethrFriends forKey:@"tethrFriends"];
    [userDetails synchronize];

}

-(void)sendUserPush:(PFUser*)user withMessage:(NSString*)message {
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"owner" equalTo:user];
    
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          message, @"alert",
                          @"notification", @"type",
                          nil];
    
    // Send push notification to query
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery]; // Set our Installation query
    [push setData:data];
    [push sendPushInBackground];
}

-(void)confirm {
    self.confirmationView = [[UIView alloc] init];
    [self.confirmationView setBackgroundColor:[UIColor whiteColor]];
    self.confirmationView.alpha = 0.8;
    self.confirmationView.layer.cornerRadius = 10.0;
    
    UILabel *confirmationLabel = [[UILabel alloc] init];
    confirmationLabel.text = @"Following friends";
    confirmationLabel.textColor = UIColorFromRGB(0x8e0528);
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    confirmationLabel.font = montserrat;
    CGSize size = [confirmationLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.confirmationView.frame = CGRectMake((self.view.frame.size.width - MAX(200.0,size.width)) / 2.0, (self.view.frame.size.height - 100.0) / 2.0, MIN(self.view.frame.size.width,MAX(200.0,size.width)), 100.0);
    confirmationLabel.frame = CGRectMake((self.confirmationView.frame.size.width - size.width) / 2.0, (self.confirmationView.frame.size.height - size.height) / 2.0, MIN(size.width, self.view.frame.size.width), size.height);
    confirmationLabel.adjustsFontSizeToFitWidth = YES;
    [self.confirmationView addSubview:confirmationLabel];
    
    [self.view addSubview:self.confirmationView];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.confirmationView.frame.size.width - SPINNER_SIZE) / 2.0, confirmationLabel.frame.origin.y + confirmationLabel.frame.size.height + 2.0, SPINNER_SIZE, SPINNER_SIZE)];
    self.activityIndicatorView.color = UIColorFromRGB(0x8e0528);
    [self.confirmationView addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
    
    self.view.userInteractionEnabled = NO;
}

-(void)dismissConfirmation {
    [UIView animateWithDuration:0.2
                          delay:0.5
                        options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                            self.confirmationView.alpha = 0.2;
                        } completion:^(BOOL finished) {
                            [self.activityIndicatorView stopAnimating];
                            [self.confirmationView removeFromSuperview];
                            self.view.userInteractionEnabled = YES;
                        }];
}

-(void)closeView {
    if ([self.delegate respondsToSelector:@selector(closeFindFriendsVC)]) {
        [self.delegate closeFindFriendsVC];
    }
}

-(IBAction)checkboxClicked:(id)sender {
    if (self.checkboxOn) {
        self.friendsToFollowDictionary = [[NSMutableDictionary alloc] init];
        self.checkboxOn = NO;
    } else {
        self.friendsToFollowDictionary = [[NSMutableDictionary alloc] init];
        for (Friend *friend in self.findFriendsArray) {
            [self.friendsToFollowDictionary setObject:friend forKey:friend.friendID];
        }
        self.checkboxOn = YES;
    }
    [self.findFriendsTableView reloadData];
}

#pragma mark FindFriendViewControllerDelegate

-(void)followFriend:(Friend *)user following:(BOOL)follow {
    if (follow) {
        [self.friendsToFollowDictionary setObject:user forKey:user.friendID];
    } else {
        [self.friendsToFollowDictionary setObject:nil forKey:user.friendID];
    }
}

#pragma mark UITableViewDelegate

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(20.0, 0.0, self.view.frame.size.width - 40.0, CELL_HEIGHT)];
    [header setBackgroundColor:[UIColor whiteColor]];
    UILabel *selectLabel = [[UILabel alloc] initWithFrame:header.frame];
    selectLabel.text = @"Select all";
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    selectLabel.font = montserrat;
    [header addSubview:selectLabel];
    self.checkBox = [[TethrButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 50.0, (CELL_HEIGHT - 20.0) / 2.0, 20.0, 20.0)];
    [self.checkBox addTarget:self action:@selector(checkboxClicked:) forControlEvents:UIControlEventTouchUpInside];
    if (self.checkboxOn) {
        [self.checkBox setNormalColor:UIColorFromRGB(0x8e0528)];
        [self.checkBox setHighlightedColor:UIColorFromRGB(0x8e0528)];
    } else {
        [self.checkBox setNormalColor:[UIColor whiteColor]];
        [self.checkBox setHighlightedColor:UIColorFromRGB(0x8e0528)];
    }
    self.checkBox.layer.borderColor = UIColorFromRGB(0x1d1d1d).CGColor;
    self.checkBox.layer.borderWidth = 1.0;
    [header addSubview:self.checkBox];
    return header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CELL_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.findFriendsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FindFriendCell *cell = [[FindFriendCell alloc] init];
    cell.delegate = self;
    [cell setFindFriendsDictionary:self.friendsToFollowDictionary];
    [cell setUser:[self.findFriendsArray objectAtIndex:indexPath.row]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
