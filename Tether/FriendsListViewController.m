//
//  FriendsListViewController.m
//  Tether
//
//  Created by Laura Smith on 12/11/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "ActivityCell.h"
#import "CenterViewController.h"
#import "CommentViewController.h"
#import "Constants.h"
#import "Datastore.h"
#import "EditPlaceViewController.h"
#import "Flurry.h"
#import "Friend.h"
#import "FriendAtPlaceCell.h"
#import "FriendsListViewController.h"
#import "InviteViewController.h"
#import "ParticipantsListViewController.h"
#import "PhotoEditViewController.h"
#import "PlaceCommentViewController.h"
#import "PlacesViewController.h"
#import "TethrButton.h"

#import <AddressBookUI/AddressBookUI.h>
#import <FacebookSDK/FacebookSDK.h>
#import <MobileCoreServices/MobileCoreServices.h>

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
#define SPINNER_SIZE 30.0
#define STATUS_BAR_HEIGHT 20.0
#define SUB_BAR_HEIGHT 65.0
#define TOP_BAR_HEIGHT 70.0
#define MEMO_HEIGHT 15.0
#define TUTORIAL_HEADER_HEIGHT 50.0

@interface FriendsListViewController () <InviteViewControllerDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, ActivityCellDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, PhotoEditViewControllerDelegate, PartcipantsListViewControllerDelegate, PlaceCommentViewControllerDelegate, CommentViewControllerDelegate>
@property (retain, nonatomic) UITableView * friendsTableView;
@property (retain, nonatomic) UITableViewController * friendsTableViewController;
@property (retain, nonatomic) NSMutableArray * friendsOfFriendsArray;
@property (retain, nonatomic) NSMutableArray * activityArray;
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UIView * subBar;
@property (nonatomic, strong) UILabel *placeLabel;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UILabel *memoLabel;
@property (retain, nonatomic) TethrButton * commitButton;
@property (nonatomic, strong) TethrButton *inviteButton;
@property (retain, nonatomic) TethrButton * postButton;
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
@property (retain, nonatomic) UIImageView *postImageView;
@property (retain, nonatomic) UIImageView *mapImageView;
@property (retain, nonatomic) EditPlaceViewController *editViewController;
@property (retain, nonatomic) UIView *greyView;
@property (retain, nonatomic) UIView *postView;
@property (retain, nonatomic) UIView *switchView;
@property (retain, nonatomic) UIView *sliderView;
@property (assign, nonatomic) BOOL sliderOn;
@property (nonatomic, strong) UILabel *friendsLabel;
@property (nonatomic, strong) UILabel *newsLabel;
@property (retain, nonatomic) PhotoEditViewController *photoEditVC;
@property (retain, nonatomic) ParticipantsListViewController * participantsListViewController;
@property (retain, nonatomic) PFObject * postToDelete;
@property (retain, nonatomic) UIActionSheet * postActionSheet;
@property (retain, nonatomic) PlaceCommentViewController * placeCommentViewController;
@property (retain, nonatomic) CommentViewController * commentVC;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (retain, nonatomic) UIView *confirmationView;
@property (retain, nonatomic) UIActivityIndicatorView *confirmActivityIndicatorView;
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
    
    [self.view setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBack:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];
    
    CGFloat topBarHeight = TOP_BAR_HEIGHT;
    
    if (![self.place.memo isEqualToString:@""]) {
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
    
    self.switchView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 184.0) / 2.0, self.subBar.frame.origin.y + self.subBar.frame.size.height + (40.0 - 30.0) / 2.0, 180.0, 30.0)];
    [self.switchView setBackgroundColor:UIColorFromRGB(0x8e0528)];
    self.switchView.layer.cornerRadius = 5.0;
    [self.view addSubview:self.switchView];
    
    self.sliderView = [[UIView alloc] initWithFrame:CGRectMake(2.0, 2.0, 90.0, 30.0 - 4.0)];
    [self.sliderView setBackgroundColor:[UIColor whiteColor]];
    self.sliderView.layer.cornerRadius = 5.0;
    [self.switchView addSubview:self.sliderView];

    UIButton *friendsButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 90.0, 30.0)];
    [friendsButton addTarget:self action:@selector(friendsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchView addSubview:friendsButton];
    
    UIButton *newsButton = [[UIButton alloc] initWithFrame:CGRectMake(90.0, 0.0, 90.0, 30.0)];
    [newsButton addTarget:self action:@selector(newsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchView addSubview:newsButton];
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    
    self.friendsLabel = [[UILabel alloc] init];
    self.friendsLabel.text = @"status";
    self.friendsLabel.font = montserrat;
    CGSize size = [self.friendsLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.friendsLabel.textColor = UIColorFromRGB(0x1d1d1d);
    self.friendsLabel.frame = CGRectMake((90.0 - size.width) / 2.0, (30.0 - size.height) / 2.0, size.width, size.height);
    [self.switchView addSubview:self.friendsLabel];
    
    self.newsLabel = [[UILabel alloc] init];
    self.newsLabel.text = @"news";
    self.newsLabel.font = montserrat;
    size = [self.newsLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.newsLabel.textColor = [UIColor whiteColor];
    self.newsLabel.frame = CGRectMake(90.0 + (90.0 - size.width) / 2.0, (30.0 - size.height) / 2.0, size.width, size.height);
    [self.switchView addSubview:self.newsLabel];
    
    self.placeLabel = [[UILabel alloc] init];
    self.placeLabel.text = self.place.name;
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
    
    size = [self.placeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
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
    if ([self.friendsArray count] == 0) {
        [self.numberButton setHidden:YES];
    } else {
        [self.numberButton setHidden:NO];
    }
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
    
    self.postButton = [[TethrButton alloc] initWithFrame:CGRectMake(self.commitButton.frame.origin.x + self.commitButton.frame.size.width + PADDING, 0.0, (self.view.frame.size.width  - PADDING * 2) / 3.0, SUB_BAR_HEIGHT - PADDING)];
    [self.postButton setNormalColor:[UIColor whiteColor]];
    [self.postButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [self.postButton setTitle:@"post" forState:UIControlStateNormal];
    [self.postButton setTitleEdgeInsets:UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)];
    [self.postButton setTitleColor:UIColorFromRGB(0x8e0528)  forState:UIControlStateNormal];
    self.postButton.titleLabel.font = missionGothic;
    [self.postButton addTarget:self action:@selector(postClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.subBar addSubview:self.postButton];
    
    self.postImageView = [[UIImageView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width - PADDING * 2) / 3.0 - 30.0) / 2.0, 5.0, 30.0, 30.0)];
    self.postImageView.image = [UIImage imageNamed:@"Post"];
    [self.postButton addSubview:self.postImageView];
    
    UIView *verticalDivider1 = [[UIView alloc] initWithFrame:CGRectMake(self.inviteButton.frame.size.width, (SUB_BAR_HEIGHT - 45.0) / 2.0, 1.0, 45.0)];
    [verticalDivider1 setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [verticalDivider1 setAlpha:0.5];
    [self.subBar addSubview:verticalDivider1];
    
    UIView *verticalDivider2 = [[UIView alloc] initWithFrame:CGRectMake(self.commitButton.frame.origin.x + self.commitButton.frame.size.width, (SUB_BAR_HEIGHT - 45.0) / 2.0, 1.0, 45.0)];
    [verticalDivider2 setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [verticalDivider2 setAlpha:0.5];
    [self.subBar addSubview:verticalDivider2];
    
    //set up friends going out table view
    self.friendsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.subBar.frame.origin.y + self.subBar.frame.size.height + 40.0, self.view.frame.size.width, self.view.frame.size.height - self.topBar.frame.size.height - SUB_BAR_HEIGHT - 40.0)];
    [self.friendsTableView setSeparatorColor:UIColorFromRGB(0xc8c8c8)];
    [self.friendsTableView setDataSource:self];
    [self.friendsTableView setDelegate:self];
    self.friendsTableView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.friendsTableView];
    
    self.friendsTableViewController = [[UITableViewController alloc] init];
    self.friendsTableViewController.tableView = self.friendsTableView;
    
    self.friendsOfFriendsArray = [[NSMutableArray alloc] init];
    
    if ([self.place.friendsCommitted count] == 0) {
        self.sliderOn = YES;
        [self setupSlider];
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - SPINNER_SIZE) / 2.0, self.topBar.frame.size.height +SUB_BAR_HEIGHT + self.switchView.frame.size.height + 20.0, SPINNER_SIZE, SPINNER_SIZE)];
        self.activityIndicatorView.color = UIColorFromRGB(0x8e0528);
        [self.view addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
    }

    self.moreInfoButton = [[UIButton alloc] init];
    
    if (!self.place.owner && [self.place.friendsCommitted count] == 0) {
        self.moreInfoButton.frame = CGRectMake(self.view.frame.size.width - 40.0, self.placeLabel.frame.origin.y, 25.0, 25.0);
        [self.moreInfoButton setImage:[UIImage imageNamed:@"InfoPinGrey"] forState:UIControlStateNormal];
        [self.moreInfoButton addTarget:self action:@selector(moreInfoClicked:) forControlEvents:UIControlEventTouchUpInside];
    } else if (!self.place.owner || ![self.place.owner isEqualToString:sharedDataManager.facebookId]) {
        self.moreInfoButton.frame = CGRectMake(self.view.frame.size.width / 3.0 *2, 0.0, (self.view.frame.size.width  - PADDING * 2) / 3.0, TOP_BAR_HEIGHT);
        [self.moreInfoButton setImage:[UIImage imageNamed:@"LocationSpotter"] forState:UIControlStateNormal];
        [self.moreInfoButton setImageEdgeInsets:UIEdgeInsetsMake(20.0, 50.0, 0.0, 0.0)];
        [self.moreInfoButton addTarget:self
                           action:@selector(showMapViewAnnotation:)
                 forControlEvents:UIControlEventTouchUpInside];
    } else if ([self.place.owner isEqualToString:sharedDataManager.facebookId]) {
        self.moreInfoButton.frame = CGRectMake(self.view.frame.size.width - 50.0, self.placeLabel.frame.origin.y, 34.0, 32.0);
        [self.moreInfoButton setImage:[UIImage imageNamed:@"Edit"] forState:UIControlStateNormal];
        [self.moreInfoButton addTarget:self action:@selector(editClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.topBar addSubview:self.moreInfoButton];
    
    [Flurry logEvent:@"User_views_place_specific_page"];
    
    [self loadActivity];
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

-(void)setupSlider {
    CGRect frame;
    UIColor *friendsLabelColor;
    UIColor *newsLabelColor;
    if (self.sliderOn) {
        frame = CGRectMake(88.0, 2.0, 90.0, 30.0 - 4.0);
        friendsLabelColor = [UIColor whiteColor];
        newsLabelColor = [UIColor blackColor];
    } else {
        frame = CGRectMake(2.0, 2.0, 90.0, 30.0 - 4.0);
        friendsLabelColor  = [UIColor blackColor];
        newsLabelColor = [UIColor whiteColor];
    }
    [self.friendsTableView reloadData];
    [UIView animateWithDuration:SLIDE_TIMING*0.5
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.sliderView.frame = frame;
                         self.friendsLabel.textColor = friendsLabelColor;
                         self.newsLabel.textColor = newsLabelColor;
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)closeFriendsView {
    if ([self.delegate respondsToSelector:@selector(closeFriendsView:)]) {
        [self.delegate closeFriendsView:self];
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
    
    if (sharedDataManager.friendsOfFriends) {
        allFriendsOfFriends = [[sharedDataManager.friendsOfFriends allObjects] mutableCopy];
    } else {
        for (Friend *friend in self.friendsArray) {
            if (![friend.friendID isEqualToString:sharedDataManager.facebookId]) {
                [allFriendsOfFriends addObjectsFromArray:friend.friendsArray];
            }
        }
    }
    
    NSMutableArray *facebookFriendsArray = [sharedDataManager.tetherFriends mutableCopy];
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
                        if (![[user objectForKey:@"facebookId"] isEqualToString:sharedDataManager.facebookId]) {
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

-(void)loadActivity {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    PFQuery *friendsQuery = [PFQuery queryWithClassName:@"Activity"];
    [friendsQuery whereKey:@"placeId" equalTo:self.place.placeId];
    [friendsQuery whereKey:@"facebookId" containedIn:sharedDataManager.tetherFriends];
    
    PFQuery *othersQuery = [PFQuery queryWithClassName:@"Activity"];
    [othersQuery whereKey:@"facebookId" notContainedIn:sharedDataManager.tetherFriends];
    [othersQuery whereKey:@"placeId" equalTo:self.place.placeId];
    [othersQuery whereKey:@"private" notEqualTo:[NSNumber numberWithBool:YES]];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[friendsQuery, othersQuery]];
    [query includeKey:@"photo"];
    [query includeKey:@"user"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.activityArray = [[NSMutableArray alloc] initWithArray:objects];
        NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        [self.activityArray sortUsingDescriptors:[NSArray arrayWithObjects:dateDescriptor, nil]];
        [self.friendsTableView reloadData];
        [self.activityIndicatorView stopAnimating];
    }];
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

-(IBAction)friendsTapped:(id)sender {
    self.sliderOn = NO;
    [self setupSlider];
}

-(IBAction)newsTapped:(id)sender {
    self.sliderOn = YES;
    [self setupSlider];
}

-(IBAction)postClicked:(id)sender {
    self.greyView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.greyView setBackgroundColor:[UIColor blackColor]];
    self.greyView.alpha = 0.2;
    [self.view addSubview:self.greyView];
    
    self.postView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 250.0) / 2.0, 200.0, 250.0, 150.0)];
    [self.postView setBackgroundColor:[UIColor whiteColor]];
    self.postView.layer.cornerRadius = 5.0;
    self.postView.layer.masksToBounds = YES;
    [self.view addSubview:self.postView];
    
    TethrButton *cameraButton = [[TethrButton alloc] initWithFrame:CGRectMake(0.0, 0.0, self.postView.frame.size.width / 2.0, self.postView.frame.size.height - 50.0)];
    [cameraButton addTarget:self action:@selector(photoClicked:) forControlEvents:UIControlEventTouchUpInside];
    [cameraButton setNormalColor:[UIColor whiteColor]];
    [cameraButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    UIFont *missionGothic = [UIFont fontWithName:@"MissionGothic-BoldItalic" size:16.0f];
    cameraButton.titleLabel.font = missionGothic;
    [cameraButton setTitle:@"Photo" forState:UIControlStateNormal];
    [cameraButton setTitleEdgeInsets:UIEdgeInsetsMake(30.0, 0.0, 0.0, 0.0)];
    [cameraButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    
    UIImageView *cameraImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Camera.png"]];
    cameraImage.frame = CGRectMake((cameraButton.frame.size.width - 30.0) / 2.0, 15.0, 30.0, 30.0);
    [cameraButton addSubview:cameraImage];
    [self.postView addSubview:cameraButton];
    
    TethrButton *commentButton = [[TethrButton alloc] initWithFrame:CGRectMake(self.postView.frame.size.width / 2.0, 0.0, self.postView.frame.size.width / 2.0, self.postView.frame.size.height - 50.0)];
    [commentButton addTarget:self action:@selector(showPlaceCommentViewController) forControlEvents:UIControlEventTouchUpInside];
    [commentButton setNormalColor:[UIColor whiteColor]];
    [commentButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    commentButton.titleLabel.font = missionGothic;
    [commentButton setTitle:@"Comment" forState:UIControlStateNormal];
    [commentButton setTitleEdgeInsets:UIEdgeInsetsMake(30.0, 0.0, 0.0, 0.0)];
    [commentButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    [self.postView addSubview:commentButton];
    
    UIImageView *commentImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Comment.png"]];
    commentImage.frame = CGRectMake((cameraButton.frame.size.width - 30.0) / 2.0, 15.0, 30.0, 30.0);
    [commentButton addSubview:commentImage];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 100.0, self.postView.frame.size.width, 1.0)];
    [separator setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.postView addSubview:separator];
    
    TethrButton *cancelButton = [[TethrButton alloc] initWithFrame:CGRectMake(0.0, separator.frame.origin.y + 1.0, self.postView.frame.size.width, 50.0)];
    [cancelButton addTarget:self action:@selector(cancelClicked:) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setNormalColor:[UIColor whiteColor]];
    [cancelButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    UIFont *monsterrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    cancelButton.titleLabel.font = monsterrat;
    [self.postView addSubview:cancelButton];
}

-(IBAction)photoClicked:(id)sender {
    [self.postView removeFromSuperview];
    [self.greyView removeFromSuperview];
    [self photoCapture];
}

-(void)photoCapture {
    BOOL cameraDeviceAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    BOOL photoLibraryAvailable = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
    
    if (cameraDeviceAvailable && photoLibraryAvailable) {
        self.postActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose Photo", nil];
        [self.postActionSheet showInView:self.view];
    } else {
        BOOL presentedPhotoCaptureController = [self shouldStartCameraController];
        
        if (!presentedPhotoCaptureController) {
            presentedPhotoCaptureController = [self shouldStartPhotoLibraryPickerController];
        }
    }
}

-(void)showPlaceCommentViewController {
    [self.postView removeFromSuperview];
    [self.greyView removeFromSuperview];
    self.placeCommentViewController = [[PlaceCommentViewController alloc] init];
    self.placeCommentViewController.delegate = self;
    self.placeCommentViewController.place = self.place;
    [self.placeCommentViewController didMoveToParentViewController:self];
    [self.placeCommentViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.placeCommentViewController.view];
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.placeCommentViewController.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

#pragma mark - PlaceCommentViewControllerDelegate

-(void)closePlaceCommentView {
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.placeCommentViewController.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.placeCommentViewController.view removeFromSuperview];
                         [self.placeCommentViewController removeFromParentViewController];
                         self.placeCommentViewController = nil;
                     }];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.postActionSheet) {
        if (buttonIndex == 0) {
            [self shouldStartCameraController];
        } else if (buttonIndex == 1) {
            [self shouldStartPhotoLibraryPickerController];
        }
    } else {
        if (buttonIndex == 0) {
            if ([[self.postToDelete objectForKey:@"type"] isEqualToString:@"photo"]) {
                PFObject *photoObject = [self.postToDelete objectForKey:@"photo"];
                [photoObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [self.postToDelete deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            [self loadActivity];
                        } else {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Could not delete your post, please try again" message:nil delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [alert show];
                        }
                    }];
                }];
            } else {
                [self.postToDelete deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (succeeded) {
                        [self loadActivity];
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Could not delete your post, please try again" message:nil delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    }
                }];
            }
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

- (BOOL)shouldStartCameraController {
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && [[UIImagePickerController availableMediaTypesForSourceType:
             UIImagePickerControllerSourceTypeCamera] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        } else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            cameraUI.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        
    } else {
        return NO;
    }
    
    cameraUI.allowsEditing = YES;
    cameraUI.showsCameraControls = YES;
    cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return YES;
}


- (BOOL)shouldStartPhotoLibraryPickerController {
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO
         && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)) {
        return NO;
    }
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]
        && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]
               && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum] containsObject:(NSString *)kUTTypeImage]) {
        
        cameraUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
        
    } else {
        return NO;
    }
    
    cameraUI.allowsEditing = YES;
    cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
    
    return YES;
}

-(IBAction)cancelClicked:(id)sender {
    [self.postView removeFromSuperview];
    [self.greyView removeFromSuperview];
}

-(IBAction)commitClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (self.commitButton.tag == 1 && ![sharedDataManager.currentCommitmentPlace.placeId isEqualToString:self.place.placeId]) {
        if([self.delegate respondsToSelector:@selector(commitToPlace:)]) {
            NSLog(@"CONTENT VIEW: commiting to %@", self.place.name);
            [self.delegate commitToPlace:self.place];
            
            self.sliderOn = NO;
            [self setupSlider];
            
            [self reloadActivity];
            
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
            [self.numberButton setHidden:YES];
        } else {
            [self.numberButton setHidden:NO];
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
    friend = [sharedDataManager.tetherFriendsDictionary objectForKey:sharedDataManager.facebookId];
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
                             if (self.inviteViewController.thread) {
                                 if ([self.delegate respondsToSelector:@selector(openMessageWithThreadId:)]) {
                                     [self.delegate openMessageWithThreadId:self.inviteViewController.thread.threadId];
                                 }
                             }
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

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:NO completion:nil];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    self.photoEditVC = [[PhotoEditViewController alloc] initWithImage:image];
    self.photoEditVC.delegate = self;
    self.photoEditVC.place = self.place;

    [self.photoEditVC setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    
    [self addChildViewController:self.photoEditVC];
    [self.photoEditVC didMoveToParentViewController:self];
    [self.photoEditVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0, self.view.frame.size.width, self.view.frame.size.height)]; //notice this is OFF screen!
    [self.view addSubview:self.photoEditVC.view];
    
    [UIView animateWithDuration:0.6*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.photoEditVC.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

#pragma mark - PhotoEditViewControllerDelegate

-(void)closePhotoEditView {
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.photoEditVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.photoEditVC.view removeFromSuperview];
                         [self.photoEditVC removeFromParentViewController];
                     }];
}

-(void)confirmPosting:(NSString*)postType {
    self.confirmationView = [[UIView alloc] init];
    [self.confirmationView setBackgroundColor:[UIColor whiteColor]];
    self.confirmationView.alpha = 0.8;
    self.confirmationView.layer.cornerRadius = 10.0;
    
    UILabel *confirmationLabel = [[UILabel alloc] init];
    confirmationLabel.text = postType;
    confirmationLabel.textColor = UIColorFromRGB(0x8e0528);
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    confirmationLabel.font = montserrat;
    CGSize size = [confirmationLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.confirmationView.frame = CGRectMake((self.view.frame.size.width - MAX(200.0,size.width)) / 2.0, (self.view.frame.size.height - 100.0) / 2.0, MIN(self.view.frame.size.width,MAX(200.0,size.width)), 100.0);
    confirmationLabel.frame = CGRectMake((self.confirmationView.frame.size.width - size.width) / 2.0, (self.confirmationView.frame.size.height - size.height) / 2.0, MIN(size.width, self.view.frame.size.width), size.height);
    confirmationLabel.adjustsFontSizeToFitWidth = YES;
    [self.confirmationView addSubview:confirmationLabel];
    
    [self.view addSubview:self.confirmationView];
    
    self.confirmActivityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.confirmationView.frame.size.width - SPINNER_SIZE) / 2.0, confirmationLabel.frame.origin.y + confirmationLabel.frame.size.height + 2.0, SPINNER_SIZE, SPINNER_SIZE)];
    self.confirmActivityIndicatorView.color = UIColorFromRGB(0x8e0528);
    [self.confirmationView addSubview:self.confirmActivityIndicatorView];
    [self.confirmActivityIndicatorView startAnimating];
    
    self.view.userInteractionEnabled = NO;
}

-(void)dismissConfirmation {
    [UIView animateWithDuration:0.2
                          delay:0.5
                        options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                            self.confirmationView.alpha = 0.2;
                        } completion:^(BOOL finished) {
                            [self.confirmActivityIndicatorView stopAnimating];
                            [self.confirmationView removeFromSuperview];
                            self.view.userInteractionEnabled = YES;
                        }];
}

-(void)reloadActivity {
    [self loadActivity];
    [self dismissConfirmation];
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
    
    if([self.delegate respondsToSelector:@selector(closeFriendsView:)]) {
        [self.delegate closeFriendsView:self];
    }
}

-(void)refreshPlaceDetails:(Place*)place {
    self.place = place;
}

#pragma mark ActivityCellDelegate

-(void)showProfileOfFriend:(Friend*)user {
    if ([self.delegate respondsToSelector:@selector(showProfileOfFriend:)]) {
        [self.delegate showProfileOfFriend:user];
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

-(void)postSettingsClicked:(PFObject*)postObject {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Delete Post", nil];
    [actionSheet showInView:self.view];
    self.postToDelete = postObject;
}

#pragma mark ParticpiantsListViewControllerDelegate

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

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.sliderOn) {
        return CELL_HEIGHT;
    } else {
        PFObject *object = [self.activityArray objectAtIndex:indexPath.row];
        if ([[object objectForKey:@"type"] isEqualToString:@"photo"] ) {
            NSString *content = [object objectForKey:@"content"];
            UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
            CGRect textRect = [content boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 60.0, 1000.0)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{NSFontAttributeName:montserrat}
                                                    context:nil];
            return self.view.frame.size.width + 87.0 + textRect.size.height;
        } else if ([[object objectForKey:@"type"] isEqualToString:@"comment"]) {
            NSString *userName = [[object objectForKey:@"user"] objectForKey:@"firstName"];
            NSString *content = [object objectForKey:@"content"];
            NSString *contentString = [NSString stringWithFormat:@"%@ commented: \n\"%@\"", userName, content];
            UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
            CGRect textRect = [contentString boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 60.0, 1000.0)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName:montserrat}
                                                          context:nil];
            return textRect.size.height + 65.0;
        } else {
            NSString *userName = [[object objectForKey:@"user"] objectForKey:@"firstName"];
            NSString *contentString = [NSString stringWithFormat:@"%@ tethred here", userName];
            UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
            CGRect textRect = [contentString boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 60.0, 1000.0)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName:montserrat}
                                                          context:nil];
            return textRect.size.height + 65.0;
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (!self.sliderOn) {
        return HEADER_HEIGHT;
    } else {
        return 0.0;
    }
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
    if (!self.sliderOn) {
        if (section == 0) {
            return [self.friendsArray count];
        } else {
            return [self.friendsOfFriendsArray count];
        }
    } else {
        return [self.activityArray count];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!self.sliderOn) {
        return 2;
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.sliderOn) {
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
    } else {
        ActivityCell *cell = [[ActivityCell alloc] init];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        cell.delegate = self;
        cell.feedType = @"place";
        [cell setActivityObject:[self.activityArray objectAtIndex:indexPath.row]];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.sliderOn) {
        Friend *friend;
        if (indexPath.section == 0) {
            friend = [self.friendsArray objectAtIndex:indexPath.row];
        } else if (indexPath.section == 1){
            friend = [self.friendsOfFriendsArray objectAtIndex:indexPath.row];
        }
        if ([self.delegate respondsToSelector:@selector(showProfileOfFriend:)]) {
            [self.delegate showProfileOfFriend:friend];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
