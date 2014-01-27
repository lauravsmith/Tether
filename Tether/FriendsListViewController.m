//
//  FriendsListViewController.m
//  Tether
//
//  Created by Laura Smith on 12/11/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Constants.h"
#import "Datastore.h"
#import "Friend.h"
#import "FriendAtPlaceCell.h"
#import "FriendsListViewController.h"
#import "InviteViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#define BORDER_WIDTH 4.0
#define BOTTOM_BAR_HEIGHT 60.0
#define CELL_HEIGHT 60.0
#define HEADER_HEIGHT 30.0
#define LEFT_PADDING 40.0
#define NAME_LABEL_OFFSET_X 70.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 50.0
#define SLIDE_TIMING 0.6
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

@interface FriendsListViewController () <InviteViewControllerDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) UITableView * friendsTableView;
@property (retain, nonatomic) UITableViewController * friendsTableViewController;
@property (retain, nonatomic) NSMutableArray * friendsOfFriendsArray;
@property (retain, nonatomic) UIView * topBar;
@property (nonatomic, strong) UILabel *placeLabel;
@property (retain, nonatomic) UIButton * commitButton;
@property (nonatomic, strong) UIButton *inviteButton;
@property (nonatomic, strong) UILabel *plusIconLabel;
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
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBack:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];
    
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    
    self.placeLabel = [[UILabel alloc] init];
    self.placeLabel.text = self.place.name;
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    CGSize size = [self.placeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.placeLabel.frame = CGRectMake(LEFT_PADDING, STATUS_BAR_HEIGHT, MIN(self.view.frame.size.width - LEFT_PADDING, size.width), size.height);
    [self.placeLabel setTextColor:[UIColor whiteColor]];
    self.placeLabel.font = montserrat;
    self.placeLabel.adjustsFontSizeToFitWidth = YES;
    [self.topBar addSubview:self.placeLabel];
    [self.view addSubview:self.topBar];
    
    // left panel view button setup
    UIImage *leftPanelButtonImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, (STATUS_BAR_HEIGHT + 57.0) / 2.0, 10.0, 10.0)];
    [self.backButton setImage:leftPanelButtonImage forState:UIControlStateNormal];
    [self.view addSubview:self.backButton];
    [self.backButton addTarget:self action:@selector(closeFriendsView) forControlEvents:UIControlEventTouchDown];
    
    self.backButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, (self.view.frame.size.width) / 4.0, TOP_BAR_HEIGHT)];
    [self.backButtonLarge addTarget:self action:@selector(closeFriendsView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButtonLarge];

    self.commitButton = [[UIButton alloc] init];
    [self.commitButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    self.commitButton.titleLabel.font = montserrat;
    [self.commitButton addTarget:self
                          action:@selector(commitClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentPlace) {
        if ([self.place.placeId isEqualToString:sharedDataManager.currentCommitmentPlace.placeId]) {
            [self.commitButton setTitle:@"Tethred" forState:UIControlStateNormal];
            [self.commitButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
            self.commitButton.tag = 2;
        } else {
            [self.commitButton setTitle:@"Tethr" forState:UIControlStateNormal];
            [self.commitButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
            self.commitButton.tag = 1;
        }
    } else {
        [self.commitButton setTitle:@"Tethr" forState:UIControlStateNormal];
        [self.commitButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
        self.commitButton.tag = 1;
    }

    size = [self.commitButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.commitButton.frame = CGRectMake(LEFT_PADDING, self.placeLabel.frame.origin.y + self.placeLabel.frame.size.height + 5.0, size.width, size.height);
    [self.topBar addSubview:self.commitButton];
    
    self.inviteButton = [[UIButton alloc] init];
    self.inviteButton.frame = CGRectMake(self.commitButton.frame.origin.x + self.commitButton.frame.size.width + 30.0, self.placeLabel.frame.origin.y + self.placeLabel.frame.size.height - 4.0, 30.0, 40.0);
    [self.inviteButton setImage:[UIImage imageNamed:@"FriendIcon"] forState:UIControlStateNormal];
    [self.inviteButton addTarget:self
                          action:@selector(inviteClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.inviteButton];
    
    self.plusIconLabel = [[UILabel alloc] init];
    self.plusIconLabel.frame = CGRectMake(self.inviteButton.frame.origin.x + 6.0, self.inviteButton.frame.origin.y + 8.0, 10.0, 10.0);
    [self.plusIconLabel setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.plusIconLabel setTextColor:[UIColor whiteColor]];
    self.plusIconLabel.layer.borderWidth = 0.5;
    self.plusIconLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    UIFont *montserratExtraSmall = [UIFont fontWithName:@"Montserrat" size:8];
    self.plusIconLabel.font = montserratExtraSmall;
    self.plusIconLabel.text = @"+";
    self.plusIconLabel.textAlignment = NSTextAlignmentCenter;
    self.plusIconLabel.layer.cornerRadius = 5.0;
    [self.topBar addSubview:self.plusIconLabel];
    
    UIView *lineBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.topBar.frame.size.height, self.view.frame.size.width, 1.0)];
    [lineBar setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.view addSubview:lineBar];
    
    //set up friends going out table view
    self.friendsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.topBar.frame.size.height + 1.0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.friendsTableView setSeparatorColor:UIColorFromRGB(0xD6D6D6)];
    [self.friendsTableView setDataSource:self];
    [self.friendsTableView setDelegate:self];
    self.friendsTableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.friendsTableView];
    
    self.friendsTableViewController = [[UITableViewController alloc] init];
    self.friendsTableViewController.tableView = self.friendsTableView;
    
    self.friendsOfFriendsArray = [[NSMutableArray alloc] init];
}

-(void)closeFriendsView {
    if ([self.delegate respondsToSelector:@selector(closeFriendsView)]) {
        [self.delegate closeFriendsView];
    }
}

-(void)loadFriendsOfFriends {
    NSMutableArray *allFriendsOfFriends = [[NSMutableArray alloc] init];
    
    for (Friend *friend in self.friendsArray) {
        [allFriendsOfFriends addObjectsFromArray:friend.friendsArray];
    }
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    NSMutableArray *facebookFriendsArray = [sharedDataManager.facebookFriends mutableCopy];
    [facebookFriendsArray addObject:sharedDataManager.facebookId];
    
    NSMutableSet *friendsOfFriendsSet = [[NSMutableSet alloc] initWithArray:allFriendsOfFriends];
    NSMutableSet *myFriendsSet = [[NSMutableSet alloc] initWithArray:facebookFriendsArray];
    NSMutableSet *blockedListSet = [[NSMutableSet alloc] initWithArray:sharedDataManager.blockedList];
    [friendsOfFriendsSet minusSet:myFriendsSet];
    [friendsOfFriendsSet minusSet:blockedListSet];

    allFriendsOfFriends = [[friendsOfFriendsSet allObjects] mutableCopy];
    
    PFQuery *query = [PFQuery queryWithClassName:kCommitmentClassKey];
    [query whereKey:kUserFacebookIDKey containedIn:allFriendsOfFriends];
    [query whereKey:kUserFacebookIDKey notContainedIn:facebookFriendsArray];
    [query whereKey:kUserFacebookIDKey notContainedIn:sharedDataManager.blockedList];
    [query whereKey:kCommitmentPlaceIDKey equalTo:self.place.placeId];
    NSDate *startTime = [self getStartTime];
    [query whereKey:kCommitmentDateKey greaterThan:startTime];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *friendsOfFriendsIdsArray = [[NSMutableArray alloc] init];
            for (PFObject * object in objects) {
                [friendsOfFriendsIdsArray addObject:object[kUserFacebookIDKey]];
            }
            
            PFQuery *facebookFriendsQuery = [PFUser query];
            [facebookFriendsQuery whereKey:kUserFacebookIDKey containedIn:friendsOfFriendsIdsArray];
            
            [facebookFriendsQuery findObjectsInBackgroundWithBlock:^(NSArray *userObjects, NSError *error) {
                if (!error) {
                    NSMutableDictionary* friendsOfFriendsDictionary = [[NSMutableDictionary alloc] init];
                    for (PFUser *user in userObjects) {
                        Friend *friend;
                        friend = [[Friend alloc] init];
                        if ([friendsOfFriendsDictionary objectForKey:user[kUserFacebookIDKey]]) {
                            friend = [friendsOfFriendsDictionary objectForKey:user[kUserFacebookIDKey]];
                            friend.mutualFriendsCount += 1;
                        } else {
                            friend.friendID = user[kUserFacebookIDKey];
                            friend.name = user[kUserDisplayNameKey];
                            friend.placeId = self.place.placeId;
                            friend.status = [user[kUserStatusKey] boolValue];
                            friend.statusMessage = user[kUserStatusMessageKey];
                            friend.mutualFriendsCount = 1;
                        }
                        
                        [friendsOfFriendsDictionary setObject:friend forKey:friend.friendID];
                    }
                    for (id key in friendsOfFriendsDictionary) {
                        [self.friendsOfFriendsArray addObject:[friendsOfFriendsDictionary objectForKey:key]];
                    }
                    NSSortDescriptor *mutualFriendsDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"mutualFriendsCount" ascending:NO];
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

-(void) layoutCommitButton {
    if (self.commitButton.tag == 1) {
        [self.commitButton setTitle:@"Tethr" forState:UIControlStateNormal];
    } else {
        [self.commitButton setTitle:@"Tethred" forState:UIControlStateNormal];
    }
    
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:16.0f];
    CGSize size = [self.commitButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratSmall}];
    self.commitButton.frame = CGRectMake(LEFT_PADDING, self.placeLabel.frame.origin.y + self.placeLabel.frame.size.height + 5.0, size.width, size.height);
}

-(void)inviteToPlace:(Place *)place {
    InviteViewController *inviteViewController = [[InviteViewController alloc] init];
    inviteViewController.delegate = self;
    inviteViewController.place = place;
    [inviteViewController.view setBackgroundColor:[UIColor blackColor]];
    [inviteViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:inviteViewController.view];
    [self addChildViewController:inviteViewController];
    [inviteViewController didMoveToParentViewController:self];
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:SLIDE_TIMING
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [inviteViewController.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

#pragma mark gesture handlers

-(void)moveBack:(id)sender {
    [[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];
    
    CGPoint velocity = [(UIPanGestureRecognizer*)sender velocityInView:[sender view]];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if(velocity.x > 0) {
            [self closeFriendsView];
        }
    }
}

#pragma mark UIButton action methods

-(IBAction)commitClicked:(id)sender {
    if (self.commitButton.tag == 1) {
        if([self.delegate respondsToSelector:@selector(commitToPlace:)]) {
            NSLog(@"CONTENT VIEW: commiting to %@", self.place.name);
            [self.delegate commitToPlace:self.place];
            self.commitButton.tag = 2;
            [self layoutCommitButton];
        }
    } else {
        if([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
            [self.delegate removePreviousCommitment];
        }
        if ([self.delegate respondsToSelector:@selector(removeCommitmentFromDatabase)]) {
            [self.delegate removeCommitmentFromDatabase];
        }
        
        self.commitButton.tag = 1;
        [self layoutCommitButton];
    }
}

-(IBAction)inviteClicked:(id)sender {
    [self inviteToPlace:self.place];
}

#pragma mark InviteViewControllerDelegate

-(void)closeInviteView {
    for (UIViewController *childViewController in self.childViewControllers) {
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [childViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [childViewController.view removeFromSuperview];
                             [childViewController removeFromParentViewController];
                         }];
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
    UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:14.0];
    [label setFont:montserratBold];
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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
