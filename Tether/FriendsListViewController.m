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
#import "EditPlaceViewController.h"
#import "Flurry.h"
#import "Friend.h"
#import "FriendAtPlaceCell.h"
#import "FriendsListViewController.h"
#import "InviteViewController.h"
#import "PlacesViewController.h"
#import "TethrButton.h"

#import <FacebookSDK/FacebookSDK.h>
#import <AddressBookUI/AddressBookUI.h>

#define degreesToRadian(x) (M_PI * (x) / 180.0)

#define BORDER_WIDTH 4.0
#define BOTTOM_BAR_HEIGHT 60.0
#define CELL_HEIGHT 60.0
#define HEADER_HEIGHT 30.0
#define LEFT_PADDING 40.0
#define NAME_LABEL_OFFSET_X 70.0
#define PADDING 1.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 50.0
#define SLIDE_TIMING 0.6
#define STATUS_BAR_HEIGHT 20.0
#define SUB_BAR_HEIGHT 65.0
#define TOP_BAR_HEIGHT 70.0
#define MEMO_HEIGHT 15.0
#define TUTORIAL_HEADER_HEIGHT 50.0

@interface FriendsListViewController () <InviteViewControllerDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) UITableView * friendsTableView;
@property (retain, nonatomic) UITableViewController * friendsTableViewController;
@property (retain, nonatomic) NSMutableArray * friendsOfFriendsArray;
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UIView * subBar;
@property (nonatomic, strong) UILabel *placeLabel;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UILabel *memoLabel;
@property (retain, nonatomic) TethrButton * commitButton;
@property (nonatomic, strong) TethrButton *inviteButton;
@property (retain, nonatomic) TethrButton * mapButton;
@property (nonatomic, strong) UILabel *plusIconLabel;
@property (retain, nonatomic) UIButton * backButton;
@property (retain, nonatomic) UIButton *backButtonLarge;
@property (retain, nonatomic) UIButton *numberButton;
@property (retain, nonatomic) UIView *tutorialView;
@property (retain, nonatomic) UIButton *moreInfoButton;
@property (retain, nonatomic) InviteViewController *inviteViewController;
@property (retain, nonatomic) UIImageView *inviteImageView;
@property (retain, nonatomic) UIImageView *pinImageView;
@property (retain, nonatomic) UIImageView *mapImageView;
@property (retain, nonatomic) EditPlaceViewController *editViewController;
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
    
    CGFloat topBarHeight = TOP_BAR_HEIGHT;
    
    if (self.place.memo) {
        topBarHeight += MEMO_HEIGHT;
    }
    
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, topBarHeight)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    
    self.subBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, topBarHeight, self.view.frame.size.width, SUB_BAR_HEIGHT)];
    [self.subBar setBackgroundColor:[UIColor whiteColor]];
    UIView *subBarLine = [[UIView alloc] initWithFrame:CGRectMake(15.0, SUB_BAR_HEIGHT - 1.0, self.view.frame.size.width - 15.0, 1.0)];
    [subBarLine setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [subBarLine setAlpha:0.5];
    [self.subBar addSubview:subBarLine];
    [self.view addSubview:self.subBar];
    
    self.placeLabel = [[UILabel alloc] init];
    self.placeLabel.text = self.place.name;
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    [self.placeLabel setTextColor:[UIColor whiteColor]];
    self.placeLabel.font = montserrat;
    self.placeLabel.adjustsFontSizeToFitWidth = YES;
    [self.topBar addSubview:self.placeLabel];
    [self.view addSubview:self.topBar];
    
    self.addressLabel = [[UILabel alloc] init];
    UIFont *montserratTiny = [UIFont fontWithName:@"Montserrat" size:10.0f];
    [self.addressLabel setText:self.place.address];
    [self.addressLabel setFont:montserratTiny];
    [self.addressLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
    [self.topBar addSubview:self.addressLabel];
    
    CGSize size = [self.placeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    CGSize addressLabelSize = [self.addressLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratTiny}];
    self.placeLabel.frame = CGRectMake(MAX(LEFT_PADDING, (self.view.frame.size.width - size.width) / 2.0), STATUS_BAR_HEIGHT + (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT - size.height - addressLabelSize.height) / 2.0, MIN(self.view.frame.size.width - LEFT_PADDING*2, size.width), size.height);
    self.addressLabel.frame = CGRectMake(MAX(LEFT_PADDING, (self.view.frame.size.width - addressLabelSize.width) / 2.0), STATUS_BAR_HEIGHT + (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT + size.height - addressLabelSize.height) / 2.0, addressLabelSize.width, addressLabelSize.height);
    
    if (self.place.memo && ![self.place.memo isEqualToString:@""]) {
        self.memoLabel = [[UILabel alloc] init];
        self.memoLabel.text = [NSString stringWithFormat:@"\"%@\"", self.place.memo];
        [self.memoLabel setTextColor:[UIColor whiteColor]];
        self.memoLabel.font = montserrat;
        self.memoLabel.adjustsFontSizeToFitWidth = YES;
        [self.topBar addSubview:self.memoLabel];
        size = [self.memoLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
        self.memoLabel.frame = CGRectMake(MAX(LEFT_PADDING, (self.view.frame.size.width - size.width) / 2.0), self.addressLabel.frame.origin.y + self.addressLabel.frame.size.height + PADDING*2, size.width, size.height);
    }
    
    // left panel view button setup
    UIImage *leftPanelButtonImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, (STATUS_BAR_HEIGHT + 57.0) / 2.0, 7.0, 11.0)];
    [self.backButton setImage:leftPanelButtonImage forState:UIControlStateNormal];
    [self.view addSubview:self.backButton];
    [self.backButton addTarget:self action:@selector(closeFriendsView) forControlEvents:UIControlEventTouchDown];
    
    UIFont *helveticaNeueLarge = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
    self.numberButton = [[UIButton alloc] init];
    [self.numberButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)[self.place.friendsCommitted count]] forState:UIControlStateNormal];
    self.numberButton.titleLabel.font = helveticaNeueLarge;
    size = [self.numberButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:helveticaNeueLarge}];
    self.numberButton.frame = CGRectMake(self.backButton.frame.origin.x + self.backButton.frame.size.width + 5.0, (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT - size.height) / 2 + STATUS_BAR_HEIGHT, MIN(60.0,size.width), size.height);
    [self.topBar addSubview:self.numberButton];
    
    self.backButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, (self.view.frame.size.width) / 4.0, TOP_BAR_HEIGHT)];
    [self.backButtonLarge addTarget:self action:@selector(closeFriendsView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButtonLarge];

    UIFont *missionGothic = [UIFont fontWithName:@"MissionGothic-BoldItalic" size:14.0f];
    
    self.inviteButton = [[TethrButton alloc] initWithFrame:CGRectMake(0.0, 0.0, (self.view.frame.size.width - PADDING * 2) / 3.0, SUB_BAR_HEIGHT - PADDING)];
    [self.inviteButton setNormalColor:[UIColor whiteColor]];
    [self.inviteButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [self.inviteButton setTitle:@"invite" forState:UIControlStateNormal];
    [self.inviteButton setTitleEdgeInsets:UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)];
    [self.inviteButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    self.inviteButton.titleLabel.font = missionGothic;
    [self.inviteButton setBackgroundColor:[UIColor whiteColor]];
    self.inviteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width - PADDING * 2) / 3.0 - 20.0) / 2.0, 10.0, 20.0, 20.0)];
    self.inviteImageView.image = [UIImage imageNamed:@"PlusSign"];
    [self.inviteButton addSubview:self.inviteImageView];
    [self.inviteButton addTarget:self
                          action:@selector(inviteClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    [self.subBar addSubview:self.inviteButton];

    self.pinImageView = [[UIImageView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width - PADDING * 2) / 3.0 - 25.0) / 2.0, 8.0, 25.0, 25.0)];
    self.pinImageView.image = [UIImage imageNamed:@"GreyPinIcon"];
    self.pinImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.commitButton = [[TethrButton alloc] initWithFrame:CGRectMake(self.inviteButton.frame.origin.x + self.inviteButton.frame.size.width + PADDING, 0.0, (self.view.frame.size.width - PADDING * 2) / 3.0, SUB_BAR_HEIGHT - PADDING)];
    [self.commitButton setNormalColor:[UIColor whiteColor]];
    [self.commitButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [self.commitButton setBackgroundColor:[UIColor whiteColor]];
    self.commitButton.titleLabel.font = missionGothic;
    [self.commitButton addTarget:self
                          action:@selector(commitClicked:)
                forControlEvents:UIControlEventTouchUpInside];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.currentCommitmentPlace) {
        if ([self.place.placeId isEqualToString:sharedDataManager.currentCommitmentPlace.placeId]) {
            [self.commitButton setTitle:@"tethred" forState:UIControlStateNormal];
            self.commitButton.tag = 2;
            self.pinImageView.image = [UIImage imageNamed:@"PinIcon"];
        } else {
            [self.commitButton setTitle:@"tethr" forState:UIControlStateNormal];
            self.commitButton.tag = 1;
        }
    } else {
        [self.commitButton setTitle:@"tethr" forState:UIControlStateNormal];
        self.commitButton.tag = 1;
    }
    
    [self.commitButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    [self.commitButton setTitleEdgeInsets:UIEdgeInsetsMake(20.0, 0, 0, 0)];
    [self.commitButton addSubview:self.pinImageView];
    
    [self.subBar addSubview:self.commitButton];
    
    self.mapButton = [[TethrButton alloc] initWithFrame:CGRectMake(self.commitButton.frame.origin.x + self.commitButton.frame.size.width + PADDING, 0.0, (self.view.frame.size.width  - PADDING * 2) / 3.0, SUB_BAR_HEIGHT - PADDING)];
    [self.mapButton setNormalColor:[UIColor whiteColor]];
    [self.mapButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [self.mapButton setBackgroundColor:[UIColor whiteColor]];
    [self.mapButton setTitle:@"map" forState:UIControlStateNormal];
    [self.mapButton setTitleEdgeInsets:UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)];
    [self.mapButton setTitleColor:UIColorFromRGB(0x8e0528)  forState:UIControlStateNormal];
    self.mapButton.titleLabel.font = missionGothic;
    [self.mapButton addTarget:self
                            action:@selector(showMapViewAnnotation:)
     
                  forControlEvents:UIControlEventTouchUpInside];
    [self.subBar addSubview:self.mapButton];
    
    self.mapImageView = [[UIImageView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width - PADDING * 2) / 3.0 - 25.0) / 2.0, 8.0, 25.0, 25.0)];
    self.mapImageView.image = [UIImage imageNamed:@"LocationSpotter"];
    [self.mapButton addSubview:self.mapImageView];
    
    UIView *verticalDivider1 = [[UIView alloc] initWithFrame:CGRectMake(self.inviteButton.frame.size.width, (SUB_BAR_HEIGHT - 45.0) / 2.0, 1.0, 45.0)];
    [verticalDivider1 setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [verticalDivider1 setAlpha:0.5];
    [self.subBar addSubview:verticalDivider1];
    
    UIView *verticalDivider2 = [[UIView alloc] initWithFrame:CGRectMake(self.commitButton.frame.origin.x + self.commitButton.frame.size.width, (SUB_BAR_HEIGHT - 45.0) / 2.0, 1.0, 45.0)];
    [verticalDivider2 setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [verticalDivider2 setAlpha:0.5];
    [self.subBar addSubview:verticalDivider2];
    
    //set up friends going out table view
    self.friendsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.subBar.frame.origin.y + self.subBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT - SUB_BAR_HEIGHT)];
    [self.friendsTableView setSeparatorColor:UIColorFromRGB(0xc8c8c8)];
    [self.friendsTableView setDataSource:self];
    [self.friendsTableView setDelegate:self];
    self.friendsTableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.friendsTableView];
    
    self.friendsTableViewController = [[UITableViewController alloc] init];
    self.friendsTableViewController.tableView = self.friendsTableView;
    
    self.friendsOfFriendsArray = [[NSMutableArray alloc] init];

    self.moreInfoButton = [[UIButton alloc] init];
    
    if (!self.place.owner) {
        self.moreInfoButton.frame = CGRectMake(self.view.frame.size.width - 40.0, (self.topBar.frame.size.height - 25.0 + STATUS_BAR_HEIGHT) / 2.0, 25.0, 25.0);
        [self.moreInfoButton setImage:[UIImage imageNamed:@"InfoPinGrey"] forState:UIControlStateNormal];
        [self.moreInfoButton addTarget:self action:@selector(moreInfoClicked:) forControlEvents:UIControlEventTouchUpInside];
    } else if ([self.place.owner isEqualToString:sharedDataManager.facebookId]) {
        self.moreInfoButton.frame = CGRectMake(self.view.frame.size.width - 50.0, (TOP_BAR_HEIGHT - 25.0 + STATUS_BAR_HEIGHT) / 2.0, 34.0, 32.0);
        [self.moreInfoButton setImage:[UIImage imageNamed:@"Edit"] forState:UIControlStateNormal];
        [self.moreInfoButton addTarget:self action:@selector(editClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.topBar addSubview:self.moreInfoButton];
    
    [Flurry logEvent:@"User_views_place_specific_page"];
}

-(void)closeFriendsView {
    if ([self.delegate respondsToSelector:@selector(closeFriendsView)]) {
        [self.delegate closeFriendsView];
        NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
        if (![userDetails boolForKey:kUserDefaultsHasSeenPlaceInviteTutorialKey] || ![userDetails boolForKey:kUserDefaultsHasSeenPlaceTethrTutorialKey]) {
            [userDetails setBool:YES forKey:kUserDefaultsHasSeenPlaceInviteTutorialKey];
            [userDetails setBool:YES forKey:kUserDefaultsHasSeenPlaceTethrTutorialKey];
            [userDetails synchronize];
        }
    }
}

-(void)loadFriendsOfFriends {
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [self.friendsArray sortUsingDescriptors:[NSArray arrayWithObjects:nameDescriptor, nil]];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    NSMutableArray *allFriendsOfFriends = [[NSMutableArray alloc] init];
    
    for (Friend *friend in self.friendsArray) {
        if (![friend.friendID isEqualToString:sharedDataManager.facebookId]) {
            [allFriendsOfFriends addObjectsFromArray:friend.friendsArray];   
        }
    }
    
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

-(void) layoutCommitButton {
    if (self.commitButton.tag == 1) {
        [self.commitButton setTitle:@"tethr" forState:UIControlStateNormal];
        self.pinImageView.image = [UIImage imageNamed:@"GreyPinIcon"];
    } else {
        [self.commitButton setTitle:@"tethred" forState:UIControlStateNormal];
        self.pinImageView.image = [UIImage imageNamed:@"PinIcon"];
    }
}

-(void)inviteToPlace:(Place *)place {
    self.inviteViewController = [[InviteViewController alloc] init];
    self.inviteViewController.delegate = self;
    self.inviteViewController.place = place;
    [self.inviteViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.inviteViewController.view];
    [self addChildViewController:self.inviteViewController];
    [self.inviteViewController didMoveToParentViewController:self];
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:SLIDE_TIMING
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.inviteViewController.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         [Flurry logEvent:@"User_views_invite_page_from_place_specific_page"];
                     }
                     completion:^(BOOL finished) {
                     }];
}

#pragma mark gesture handlers

-(void)moveBack:(id)sender {
    [[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];
    
    CGPoint velocity = [(UIPanGestureRecognizer*)sender velocityInView:[sender view]];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if(velocity.x > 0 && !self.inviteViewController) {
            [self closeFriendsView];
        }
    }
}

#pragma mark UIButton action methods

-(IBAction)commitClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (self.commitButton.tag == 1) {
        if([self.delegate respondsToSelector:@selector(commitToPlace:)]) {
            NSLog(@"CONTENT VIEW: commiting to %@", self.place.name);
            [self.delegate commitToPlace:self.place];
            
            [self performSelector:@selector(showCommitment) withObject:self afterDelay:1.0];
            [Flurry logEvent:@"Tethrd_from_place_specific_page"];
        }
    } else {
        if ([self.delegate isKindOfClass:[PlacesViewController class]]) {
            if ([self.delegate respondsToSelector:@selector(commitToPlace:)]) {
                [self.delegate commitToPlace:self.place];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
                [self.delegate removePreviousCommitment];
            }
            if ([self.delegate respondsToSelector:@selector(removeCommitmentFromDatabase)]) {
                [self.delegate removeCommitmentFromDatabase];
            }
        }
        
        for (Friend *friend in self.friendsArray) {
            if ([friend.friendID isEqualToString:sharedDataManager.facebookId]) {
                [self.friendsArray removeObject:friend];
                break;
            }
        }
        
        self.commitButton.tag = 1;
        [self layoutCommitButton];
        
        [self.numberButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)[self.friendsArray count]] forState:UIControlStateNormal];
        
        if ([self.friendsArray count] == 0) {
            [self.mapButton removeFromSuperview];
            self.mapButton = nil;
        }
    }
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if ([userDetails boolForKey:kUserDefaultsHasSeenPlaceInviteTutorialKey] && ![userDetails boolForKey:kUserDefaultsHasSeenPlaceTethrTutorialKey]) {
        [self closeTutorial];
    }
    [self.friendsTableView reloadData];
}

-(void)showCommitment {
    self.commitButton.tag = 2;
    [self layoutCommitButton];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    Friend *friend = [[Friend alloc] init];
    friend = [[Friend alloc] init];
    friend.friendID = sharedDataManager.facebookId;
    friend.name = sharedDataManager.name;
    friend.statusMessage = sharedDataManager.statusMessage;
    [self.friendsArray addObject:friend];
    
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [self.friendsArray sortUsingDescriptors:[NSArray arrayWithObjects:nameDescriptor, nil]];
    
    [self.numberButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)[self.friendsArray count]] forState:UIControlStateNormal];
    
    [self.friendsTableView reloadData];
}

-(IBAction)inviteClicked:(id)sender {
    if (!self.inviteViewController) {
        [self inviteToPlace:self.place];   
    }
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if (![userDetails boolForKey:kUserDefaultsHasSeenPlaceInviteTutorialKey]) {
        [self closeTutorial];
    }
}

-(IBAction)moreInfoClicked:(id)sender {
    NSString *urlString = [NSString stringWithFormat:@"foursquare://venues/%@", self.place.placeId];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        urlString = [NSString stringWithFormat:@"http://foursquare.com/v/%@", self.place.placeId];
        url = [NSURL URLWithString:urlString];
        [[UIApplication sharedApplication] openURL:url];
    }
}

-(IBAction)editClicked:(id)sender {
    self.editViewController = [[EditPlaceViewController alloc] init];
    self.editViewController.delegate = self;
    self.editViewController.place = self.place;
    [self.editViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.editViewController.view];
    [self addChildViewController:self.editViewController];
    [self.editViewController didMoveToParentViewController:self];
    
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:SLIDE_TIMING
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.editViewController.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         [Flurry logEvent:@"User_views_edit_page_from_place_specific_page"];
                     }
                     completion:^(BOOL finished) {
                     }];
    
}

-(IBAction)showMapViewAnnotation:(id)sender {
    if ([self.delegate respondsToSelector:@selector(selectAnnotationForPlace:)]) {
        [self.delegate selectAnnotationForPlace:self.place];
        [self closeFriendsView];
    }
}

#pragma mark InviteViewControllerDelegate

-(void)closeInviteView {
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.inviteViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [self.inviteViewController.view removeFromSuperview];
                             [self.inviteViewController removeFromParentViewController];
                             self.inviteViewController = nil;
                         }];
}

-(void)setupTutorialView {
    self.tutorialView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 50.0)];
    [self.tutorialView setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    UILabel *headerLabel = [[UILabel alloc] init];
    UIFont *montserratLabelFont = [UIFont fontWithName:@"Montserrat" size:13];
    headerLabel.font = montserratLabelFont;
    [headerLabel setTextColor:UIColorFromRGB(0x8e0528)];
    
    UIImage *arrowImage = [UIImage imageNamed:@"RedTriangle"];
    UIImageView *arrow = [[UIImageView alloc] initWithFrame: CGRectMake((self.view.frame.size.width - 7.0) / 2.0, 2.0, 7.0, 11.0)];
    [arrow setImage:arrowImage];
    arrow.transform = CGAffineTransformMakeRotation(degreesToRadian(90));
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if ([userDetails boolForKey:kUserDefaultsHasSeenPlaceInviteTutorialKey]) {
        self.tutorialView.tag = 1;
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if ([sharedDataManager.currentCommitmentPlace.placeId  isEqualToString:self.place.placeId]) {
             headerLabel.text = @"Tap to un-tethr here";
        } else {
             headerLabel.text = @"Tap to tethr here";
        }
        arrow.frame = CGRectMake((self.view.frame.size.width - 7.0) / 2.0, 2.0, 11.0, 7.0);
        CGSize size = [headerLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLabelFont}];
        headerLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, (50.0 - size.height) / 2.0 + 1.0, size.width, size.height);
    } else {
        self.tutorialView.tag = 0;
        headerLabel.text = @"Tap to invite a friend here";
        arrow.frame = CGRectMake((self.view.frame.size.width) / 6.0 - 5.0, 2.0, 11.0, 7.0);
        CGSize size = [headerLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLabelFont}];
        headerLabel.frame = CGRectMake(10.0, (50.0 - size.height) / 2.0 + 1.0, size.width, size.height);
    }

    [self.tutorialView addSubview:headerLabel];
    
    self.tutorialView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tutorialTapGesture =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tutorialTapped:)];
    [self.tutorialView addGestureRecognizer:tutorialTapGesture];
    
    [self.tutorialView addSubview:arrow];
}

- (void)tutorialTapped:(UIGestureRecognizer*)recognizer {
    [self closeTutorial];
}

-(void)closeTutorial {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    if (self.tutorialView.tag == 0) {
        [userDetails setBool:YES forKey:kUserDefaultsHasSeenPlaceInviteTutorialKey];
        [userDetails synchronize];
        [self.friendsTableView reloadData];
    } else {
        [userDetails setBool:YES forKey:kUserDefaultsHasSeenPlaceTethrTutorialKey];
        [userDetails synchronize];
        [self.friendsTableView reloadData];
    }
}

#pragma mark CreatePlaceViewControllerDelegate

-(void)closeCreatePlaceVC {
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.editViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.editViewController.view removeFromSuperview];
                         [self.editViewController removeFromParentViewController];
                         self.editViewController = nil;
                         [self viewDidLoad];
                         if ([self.delegate respondsToSelector:@selector(refreshList)]) {
                            [self.delegate refreshList];
                         }
                     }];
}

-(void)refreshListAfterDelete {
    [self closeCreatePlaceVC];
    
    if([self.delegate respondsToSelector:@selector(refreshList)]) {
        [self.delegate refreshList];
    }
    
    if([self.delegate respondsToSelector:@selector(closeFriendsView)]) {
        [self.delegate closeFriendsView];
    }
}

-(void)refreshPlaceDetails:(Place*)place {
    self.place = place;
//    [self viewDidLoad];
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
    [view setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
    
    UILabel *label = [[UILabel alloc] init];
    [label setTextColor:UIColorFromRGB(0x8e0528)];
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    [label setFont:montserrat];
    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 0, 50.0, HEADER_HEIGHT)];
    if(section == 0) {
        NSString *headerString = @"friends tethred here ";
        [label setText:headerString];
        countLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)[self.friendsArray count]];
    } else {
        NSString *headerString = @"friends of friends tethred here ";
        [label setText:headerString];
        countLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)[self.friendsOfFriendsArray count]];
    }
    CGSize size = [label.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    label.frame = CGRectMake(10.0, (view.frame.size.height - size.height) / 2.0, size.width, size.height);
    [view addSubview:label];
    
    [countLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
    countLabel.font = montserrat;
    CGSize numberLabelSize = [countLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    countLabel.frame = CGRectMake(label.frame.origin.x + label.frame.size.width + PADDING, label.frame.origin.y, numberLabelSize.width, numberLabelSize.height);
    [view addSubview:countLabel];
    
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
