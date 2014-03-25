//
//  InviteViewController.m
//  Tether
//
//  Created by Laura Smith on 12/19/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Constants.h"
#import "Datastore.h"
#import "Flurry.h"
#import "Friend.h"
#import "FriendAtPlaceCell.h"
#import "FriendLabel.h"
#import "InviteViewController.h"
#import "SearchResultCell.h"
#import "TethrButton.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <AddressBook/AddressBook.h>
#import <MessageUI/MessageUI.h>

#define CELL_HEIGHT 60.0
#define LABEL_HEIGHT 40.0
#define LEFT_PADDING 35.0
#define MAX_MESSAGE_FIELD_HEIGHT 165.0
#define SEARCH_BAR_HEIGHT 50.0
#define SEARCH_BAR_WIDTH 270.0
#define SEARCH_RESULTS_CELL_HEIGHT 60.0
#define SPINNER_SIZE 30.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0
#define PADDING 10.0
#define PLUS_ICON_SIZE 23.0

@interface InviteViewController () <UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextViewDelegate, MFMessageComposeViewControllerDelegate>
@property (retain, nonatomic) NSMutableArray *friendSearchResultsArray;
@property (nonatomic, strong) UITableView *friendSearchResultsTableView;
@property (nonatomic, strong) UITableViewController *friendSearchResultsTableViewController;
@property (retain, nonatomic) UIScrollView *friendsInvitedScrollView;
@property (retain, nonatomic) NSMutableDictionary *friendsLabelsDictionary;
@property (retain, nonatomic) NSMutableDictionary *removeLabelButtonsDictionary;
@property (retain, nonatomic) UITextView *messageTextView;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UIButton *backButtonLarge;
@property (assign, nonatomic) NSInteger friendsInvitedViewHeight;
@property (assign, nonatomic) NSInteger friendsInvitedViewWidth;
@property (retain, nonatomic) UIView *confirmationView;
@property (retain, nonatomic) UILabel *confirmationLabel;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (retain, nonatomic) NSMutableArray *placeSearchResultsArray;
@property (nonatomic, strong) UITableView *placeSearchResultsTableView;
@property (nonatomic, strong) UITableViewController *placeSearchResultsTableViewController;
@property (retain, nonatomic) TethrButton *plusButton;
@end

@implementation InviteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.friendsInvitedDictionary = [[NSMutableDictionary alloc] init];
        self.friendsLabelsDictionary = [[NSMutableDictionary alloc] init];
        self.removeLabelButtonsDictionary = [[NSMutableDictionary alloc] init];
        self.friendsInvitedViewHeight = 0;
        self.friendsInvitedViewWidth = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBack:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];
    
    self.topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, TOP_BAR_HEIGHT)];
    [self.topBarView setBackgroundColor:UIColorFromRGB(0x8e0528)];

    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.placeLabel = [[UILabel alloc] init];
    self.placeLabel.text = [NSString stringWithFormat:@"Invite to %@",self. place.name];
    [self.placeLabel setTextColor:[UIColor whiteColor]];
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.placeLabel.font = montserratLarge;
    CGSize size = [self.placeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratLarge}];
    self.placeLabel.frame = CGRectMake(MAX(LEFT_PADDING, (self.view.frame.size.width - size.width) / 2.0), STATUS_BAR_HEIGHT + PADDING + 4.0, MIN(self.view.frame.size.width - LEFT_PADDING, size.width), size.height);
    self.placeLabel.adjustsFontSizeToFitWidth = YES;
    [self.topBarView addSubview:self.placeLabel];
    [self.view addSubview:self.topBarView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(placeLabelTapped:)];
    [self.placeLabel addGestureRecognizer:tap];
    self.placeLabel.userInteractionEnabled = YES;
    
    self.searchBarBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, self.view.frame.size.width, SEARCH_BAR_HEIGHT)];
    [self.searchBarBackgroundView setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.searchBarBackgroundView setHidden:YES];
    [self.view addSubview:self.searchBarBackgroundView];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake((self.topBarView.frame.size.width - SEARCH_BAR_WIDTH) / 2.0, STATUS_BAR_HEIGHT, SEARCH_BAR_WIDTH, SEARCH_BAR_HEIGHT)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search for friends...";
    [self.searchBar setBackgroundImage:[UIImage new]];
    [self.searchBar setTranslucent:YES];
    [self.searchBar setHidden:YES];
    [self.view addSubview:self.searchBar];
    
    self.friendsInvitedScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.topBarView.frame.size.height, self.view.frame.size.width, LABEL_HEIGHT + PADDING * 2)];
    self.friendsInvitedScrollView.showsVerticalScrollIndicator = YES;
    [self.view addSubview:self.friendsInvitedScrollView];
    
    UITapGestureRecognizer *tapFriendsInviteScrollView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(friendsInvitedScrollViewTapped)];
    [self.friendsInvitedScrollView addGestureRecognizer:tapFriendsInviteScrollView];
    
    self.plusButton = [[TethrButton alloc] initWithFrame:CGRectMake(0.0, 0.0, LABEL_HEIGHT + PADDING, LABEL_HEIGHT + PADDING*2)];
    [self.plusButton setNormalColor:[UIColor clearColor]];
    [self.plusButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [self.plusButton setImage:[UIImage imageNamed:@"PlusSign"] forState:UIControlStateNormal];
    
    double imageInsetX = (self.plusButton.frame.size.width - PLUS_ICON_SIZE) / 2.0;
    double imageInsetY = (self.plusButton.frame.size.height - PLUS_ICON_SIZE) / 2.0;
    self.plusButton.imageEdgeInsets = UIEdgeInsetsMake(imageInsetY, imageInsetX, imageInsetY, imageInsetX);
    [self.plusButton addTarget:self action:@selector(plusButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.friendsInvitedScrollView addSubview:self.plusButton];
    
    self.messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, self.friendsInvitedScrollView.frame.origin.y + self.friendsInvitedScrollView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.friendsInvitedScrollView.frame.origin.y - self.friendsInvitedScrollView.frame.size.height - 216.0)];
    self.messageTextView.delegate = self;
    self.messageTextView.tag = 0;
    [self.messageTextView setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
    [self.messageTextView setFont:montserratLarge];
    [self.messageTextView setEditable:YES];
    self.messageTextView.textColor = UIColorFromRGB(0xc8c8c8);
    self.messageTextView.text = @"Compose a message";
    [self.messageTextView setReturnKeyType:UIReturnKeyDone];
    
    self.messageTextView.layer.masksToBounds = NO;
    self.messageTextView.layer.shadowOffset = CGSizeMake(0.0, -1);
    self.messageTextView.layer.shadowRadius = 0.5f;
    self.messageTextView.layer.shadowOpacity = 0.2f;
    
    [self.view addSubview:self.messageTextView];
    
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80.0 - PADDING, self.view.frame.size.height - 220.0 - 40.0 - PADDING, 80.0, 40.0)];
    [self.sendButton addTarget:self action:@selector(sendButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:18.0];
    self.sendButton.titleLabel.font = montserrat;
    [self.sendButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateDisabled];
    [self.sendButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [self.sendButton addTarget:self action:@selector(buttonHighlight:) forControlEvents:UIControlEventTouchDown];
    [self.sendButton addTarget:self action:@selector(buttonTouchCancel:) forControlEvents:UIControlEventTouchDragExit];
    [self.sendButton setBackgroundColor:[UIColor whiteColor]];
    [self.sendButton setEnabled:NO];
    [self.view addSubview:self.sendButton];
    
    self.friendSearchResultsArray = [[NSMutableArray alloc] init];
    
    self.friendSearchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, self.topBarView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.searchBar.frame.size.height)];
    [self.friendSearchResultsTableView setDataSource:self];
    [self.friendSearchResultsTableView setDelegate:self];
    [self.friendSearchResultsTableView setHidden:YES];
    [self.view addSubview:self.friendSearchResultsTableView];
    
    self.friendSearchResultsTableViewController = [[UITableViewController alloc] init];
    self.friendSearchResultsTableViewController.tableView = self.friendSearchResultsTableView;
    [self.friendSearchResultsTableView reloadData];
    
    // left panel view button setup
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0,  (SEARCH_BAR_HEIGHT + STATUS_BAR_HEIGHT + 7.0) / 2.0, 7.0, 11.0)];
    [self.backButton setImage:triangleImage forState:UIControlStateNormal];
    [self.view addSubview:self.backButton];
    self.backButton.tag = 1;
    [self.backButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    
    self.backButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, (self.view.frame.size.width) / 4.0, 50.0)];
    [self.backButtonLarge addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButtonLarge];
    
    self.placeSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake((self.topBarView.frame.size.width - SEARCH_BAR_WIDTH) / 2.0, STATUS_BAR_HEIGHT, SEARCH_BAR_WIDTH, SEARCH_BAR_HEIGHT)];
    self.placeSearchBar.delegate = self;
    self.placeSearchBar.placeholder = @"Search places...";
    [self.placeSearchBar setBackgroundImage:[UIImage new]];
    [self.placeSearchBar setTranslucent:YES];
    [self.placeSearchBar setHidden:YES];
    [self.view addSubview:self.placeSearchBar];
    
    self.placeSearchResultsArray = [[NSMutableArray alloc] init];
    
    self.placeSearchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, self.topBarView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.placeSearchBar.frame.size.height)];
    self.placeSearchResultsTableView.hidden = YES;
    [self.placeSearchResultsTableView setDataSource:self];
    [self.placeSearchResultsTableView setDelegate:self];
    
    self.placeSearchResultsTableViewController = [[UITableViewController alloc] init];
    self.placeSearchResultsTableViewController.tableView = self.placeSearchResultsTableView;
    [self.placeSearchResultsTableView reloadData];
    
    [self.view addSubview:self.placeSearchResultsTableView];
}


-(void)hideSearchFriends {
     [self.searchBarBackgroundView setHidden:YES];
     [self.searchBar setHidden:YES];
     [self.plusButton setHidden:NO];
}

-(void)setSearchFriends {
     if (!self.place) {
        [self.placeSearchBar setHidden:YES];
     }
    [self.searchBarBackgroundView setHidden:NO];
    [self.searchBar setHidden:NO];
    [self.plusButton setHidden:YES];
    [self layoutFriendLabels];
    [self layoutFriendsInvitedView];
    [self searchBarTextDidBeginEditing:self.searchBar];
}

-(IBAction)plusButtonTapped:(id)sender {
    [self setSearchFriends];
}

-(void)friendsInvitedScrollViewTapped{
    [self setSearchFriends];
}

-(void)placeLabelTapped:(UIGestureRecognizer*)recognizer {
    [self setSearchPlaces];
}

-(void)setSearchPlaces {
    if (self.searchBar.isHidden) {
         [self.topBarView bringSubviewToFront:self.placeSearchBar];
        [self.placeLabel setHidden:YES];
        [self.placeSearchBar setHidden:NO];
        [self searchBarTextDidBeginEditing:self.placeSearchBar];
    }
}

-(void)hideSearchPlaces {
    [self.placeLabel setHidden:NO];
    [self.placeSearchBar setHidden:YES];
}

-(void)setDestination:(Place*)place {
    if ([self.friendsInvitedDictionary count] > 0) {
        [self.sendButton setEnabled:YES];
    }
    
    self.place = place;
    self.placeLabel.text = [NSString stringWithFormat:@"Invite to %@",place.name];
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.placeLabel.font = montserratLarge;
    CGSize size = [self.placeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratLarge}];
    self.placeLabel.frame = CGRectMake(MAX(LEFT_PADDING, (self.view.frame.size.width - size.width) / 2.0), STATUS_BAR_HEIGHT + PADDING + 4.0, MIN(self.view.frame.size.width - LEFT_PADDING, size.width), size.height);
    
    [self hideSearchPlaces];
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
    if ([self.delegate respondsToSelector:@selector(closeInviteView)]) {
        [self.delegate closeInviteView];
    }
}

-(void)layoutFriendsInvitedView {
    self.friendsInvitedScrollView.frame = CGRectMake(0, self.topBarView.frame.size.height, self.view.frame.size.width, MIN(MAX(PADDING*2 + LABEL_HEIGHT,self.friendsInvitedViewHeight), 100));
    self.friendsInvitedScrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.friendsInvitedViewHeight);
    self.friendsInvitedScrollView.contentOffset = CGPointMake(0, self.friendsInvitedViewHeight - self.friendsInvitedScrollView.frame.size.height);
    
    CGRect frame = self.messageTextView.frame;
    frame.origin.y = self.friendsInvitedScrollView.frame.origin.y + self.friendsInvitedScrollView.frame.size.height;
    frame.size.height = self.view.frame.size.height - self.friendsInvitedScrollView.frame.origin.y - self.friendsInvitedScrollView.frame.size.height - 216.0;
    self.messageTextView.frame = frame;
    
    self.sendButton.frame = CGRectMake(220.0, self.view.frame.size.height - 220.0 - 40.0 - PADDING, 80.0, 40.0);
}

-(void)layoutFriendLabels {
    for (UIView *subview in self.friendsInvitedScrollView.subviews) {
        if (![subview isKindOfClass:[UIImageView class]]) {
            [subview removeFromSuperview];
        }
    }
    
    [self.friendsInvitedScrollView setBackgroundColor:[UIColor whiteColor]];
    self.friendsInvitedViewHeight = 0.0;
    self.friendsInvitedViewWidth = 0.0;
    
    for (id key in self.friendsLabelsDictionary) {
        FriendLabel *friendLabel = [self.friendsLabelsDictionary objectForKey:key];
        [self addLabel:friendLabel];
     }
}

-(void)addFriend:(Friend *)friend {
    if (self.place) {
        [self.sendButton setEnabled:YES];
    }
    FriendLabel *friendLabel = [[FriendLabel alloc] init];
    friendLabel.friend = friend;
    [friendLabel setTextColor:[UIColor blackColor]];
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14];
    friendLabel.font = montserrat;
    CGSize friendLabelSize = [friend.name sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    friendLabel.text = [NSString stringWithFormat:@"  %@", friend.name];
    [friendLabel setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
    friendLabel.layer.cornerRadius = 2.0;
    friendLabel.frame = CGRectMake(0, 0, friendLabelSize.width + 20.0, LABEL_HEIGHT);

    UIButton *xButton = [[UIButton alloc] init];
    [xButton setTitle:@"X" forState:UIControlStateNormal];
    xButton.titleLabel.font = [UIFont systemFontOfSize:10.0];
    [xButton.titleLabel setTextAlignment: NSTextAlignmentCenter];
    [xButton setBackgroundColor:UIColorFromRGB(0x8e0528)];
    xButton.layer.cornerRadius = 7.0;
    [xButton addTarget:self action:@selector(removeFriend:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.removeLabelButtonsDictionary setObject:xButton forKey:friend.friendID];
    [self.friendsInvitedDictionary setObject:friend forKey:friend.friendID];
    [self.friendsLabelsDictionary setObject:friendLabel forKey:[NSValue valueWithNonretainedObject:xButton]];
    
    [self addLabel:friendLabel];
    
    self.searchBar.text = @"";
    self.friendSearchResultsArray = nil;
    [self.friendSearchResultsTableView reloadData];
    [self.friendSearchResultsTableView setHidden:YES];
    
    [self layoutFriendsInvitedView];
}

-(void)addLabel:(FriendLabel*)friendLabel {
    if (self.friendsInvitedViewHeight == 0) {
        self.friendsInvitedViewHeight = LABEL_HEIGHT + PADDING*2;
    }
    
    if (self.friendsInvitedViewWidth + friendLabel.frame.size.width + PADDING*2 > self.view.frame.size.width) {
        self.friendsInvitedViewWidth = 0;
        self.friendsInvitedViewHeight += LABEL_HEIGHT + PADDING;
    }
    
    friendLabel.frame = CGRectMake(self.friendsInvitedViewWidth + 10.0, self.friendsInvitedViewHeight - (LABEL_HEIGHT + PADDING), friendLabel.frame.size.width, LABEL_HEIGHT);
    self.friendsInvitedViewWidth += friendLabel.frame.size.width + PADDING;
    [friendLabel setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
    [self.friendsInvitedScrollView addSubview:friendLabel];
    
    UIButton *xButton = [self.removeLabelButtonsDictionary objectForKey:friendLabel.friend.friendID];
    xButton.frame = CGRectMake(self.friendsInvitedViewWidth - PADDING, self.friendsInvitedViewHeight - LABEL_HEIGHT - 15.0, 15.0, 15.0);
    [self.friendsInvitedScrollView addSubview:xButton];
}

-(void)layoutPlusIcon {
    if (self.friendsInvitedViewHeight == 0) {
        self.friendsInvitedViewHeight = LABEL_HEIGHT + PADDING*2;
    }
    
    if (self.friendsInvitedViewWidth + PLUS_ICON_SIZE + PADDING*2 > self.view.frame.size.width) {
        self.friendsInvitedViewWidth = 0;
        self.friendsInvitedViewHeight += LABEL_HEIGHT + PADDING;
    }
    
    self.plusButton.frame = CGRectMake(self.friendsInvitedViewWidth, self.friendsInvitedViewHeight - LABEL_HEIGHT - PADDING*2, LABEL_HEIGHT + PADDING, LABEL_HEIGHT + PADDING*2);
    double imageInsetX = (self.plusButton.frame.size.width - PLUS_ICON_SIZE) / 2.0;
    double imageInsetY = (self.plusButton.frame.size.height - PLUS_ICON_SIZE) / 2.0;
    self.plusButton.imageEdgeInsets = UIEdgeInsetsMake(imageInsetY, imageInsetX, imageInsetY, imageInsetX);
    self.friendsInvitedViewWidth += PLUS_ICON_SIZE + PADDING;
    
    [self.plusButton setHidden:NO];
    [self.friendsInvitedScrollView addSubview:self.plusButton];
}

#pragma mark button action handlers

-(IBAction)buttonHighlight:(id)sender {
    [self.sendButton setBackgroundColor:UIColorFromRGB(0x8e0528)];
}

-(IBAction)buttonTouchCancel:(id)sender {
    [self.sendButton setBackgroundColor:[UIColor whiteColor]];
}

-(IBAction)sendButtonClicked:(id)sender {
    [self.sendButton setBackgroundColor:[UIColor whiteColor]];
    
    if (!self.place || [self.friendsInvitedDictionary count] < 1) {
        return;
    }
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    NSMutableArray *friendsInvited = [[NSMutableArray alloc] init];
    for (id key in self.friendsInvitedDictionary) {
        Friend *friend = [self.friendsInvitedDictionary objectForKey:key];
        [friendsInvited addObject:friend.friendID];
    }
    
    NSString * friendListString = @"";

    for (NSString *friendID in friendsInvited) {
        Friend *friend = [self.friendsInvitedDictionary objectForKey:friendID];
        if ([friendsInvited indexOfObject:friendID] == 0) {
            friendListString = [NSString stringWithFormat:@" %@", friend.name];
        } else if ([friendsInvited indexOfObject:friendID] == [friendsInvited count] - 1) {
            friendListString = [NSString stringWithFormat:@"%@ and %@", friendListString, friend.name];
        } else {
            friendListString = [NSString stringWithFormat:@"%@,%@", friendListString, friend.name];
        }
    }
    
    friendListString = [NSString stringWithFormat:@"You invited%@ to %@",friendListString, self.place.name];
    
    if([self.messageTextView.text isEqualToString:@"Compose a message"]) {
        self.messageTextView.text = @"";
    }
    
    // add notification to be seen in current users activity feed
    PFObject *receipt = [PFObject objectWithClassName:kNotificationClassKey];
    [receipt setObject:sharedDataManager.facebookId forKey:kNotificationSenderKey];
    [receipt setObject:self.place.name forKey:kNotificationPlaceNameKey];
    [receipt setObject:self.place.placeId forKey:kNotificationPlaceIdKey];
    [receipt setObject:friendListString forKey:kNotificationMessageHeaderKey];
    [receipt setObject:self.messageTextView.text forKey:kNotificationMessageContentKey];
    [receipt setObject:sharedDataManager.facebookId forKey:kNotificationRecipientKey];
    [receipt setObject:friendsInvited forKey:kNotificationAllRecipientsKey];
    [receipt setObject:@"receipt" forKey:kNotificationTypeKey];
    [receipt setObject:self.place.city forKey:kNotificationCityKey];
    [receipt saveInBackground];
    
    for (id key in self.friendsInvitedDictionary) {
        Friend *friend = [self.friendsInvitedDictionary objectForKey:key];
        PFQuery *friendQuery = [PFUser query];
        [friendQuery whereKey:kUserFacebookIDKey equalTo:friend.friendID];
        
        [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
            // Create our Installation query
            PFUser * user = [objects objectAtIndex:0];
            PFQuery *pushQuery = [PFInstallation query];
            [pushQuery whereKey:@"owner" equalTo:user]; //change this to use friends installation
            NSString *messageHeader = [NSString stringWithFormat:@"%@ invited you to %@", sharedDataManager.name, self.place.name];
            NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                  messageHeader, @"alert",
                                  @"Increment", @"badge",
                                  nil];
            
            // Send push notification to query
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:pushQuery]; // Set our Installation query
            [push setData:data];
            [push sendPushInBackground];
            
            PFObject *invitation = [PFObject objectWithClassName:kNotificationClassKey];
            [invitation setObject:sharedDataManager.facebookId forKey:kNotificationSenderKey];
            [invitation setObject:self.place.name forKey:kNotificationPlaceNameKey];
            [invitation setObject:self.place.placeId forKey:kNotificationPlaceIdKey];
            [invitation setObject:messageHeader forKey:kNotificationMessageHeaderKey];
            [invitation setObject:self.messageTextView.text forKey:kNotificationMessageContentKey];
            [invitation setObject:friend.friendID forKey:kNotificationRecipientKey];
            [invitation setObject:friendsInvited forKey:kNotificationAllRecipientsKey];
            [invitation setObject:@"invitation" forKey:kNotificationTypeKey];
            [invitation setObject:self.place.city forKey:kNotificationCityKey];
            [invitation saveInBackground];
            }
        }];
    }
    
    NSDictionary *inviteParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"NumberFriends", [NSString stringWithFormat:@"%lu",(unsigned long)[friendsInvited count]],
                                  @"Message", self.messageTextView.text,
                                  @"City", self.place.city,
                                  @"Place", self.place.name,
     nil];
    
    [Flurry logEvent:@"User_Sent_Invite" withParameters:inviteParams];
    [self confirmInvitationsSent];
}

-(IBAction)removeFriend:(id)sender {
    if (self.searchBar.isHidden) {
        UIButton *button = (UIButton *)sender;
        FriendLabel *label = [self.friendsLabelsDictionary objectForKey:[NSValue valueWithNonretainedObject:button]];
        [label removeFromSuperview];
        [self.friendsInvitedDictionary removeObjectForKey:label.friend.friendID];
        [self.friendsLabelsDictionary removeObjectForKey:[NSValue valueWithNonretainedObject:button]];
        [self layoutFriendLabels];
        [self layoutPlusIcon];
        [self layoutFriendsInvitedView];
        
        if ([self.friendsInvitedDictionary count] == 0) {
            [self.sendButton setEnabled:NO];
        }
    }
}

-(IBAction)openSMSDialog:(id)sender {
    [Flurry logEvent:@"User_Clicked_Share_SMS_Invite"];
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    NSString *message = [NSString stringWithFormat:@"Tethr to %@ with me! https://itunes.apple.com/app/tethr/id825917714?mt=8", self.place.name];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:nil];
    [messageController setBody:message];
    
    // Present message view controller on screen
    [self addChildViewController:messageController];
    [messageController didMoveToParentViewController:self];
    [messageController.view setFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:messageController.view];
    
    [UIView animateWithDuration:0.6
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [messageController.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

-(void)confirmInvitationsSent {
    self.confirmationView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 200.0) / 2.0, (self.view.frame.size.height - 100.0) / 2.0, 200.0, 100.0)];
    [self.confirmationView setBackgroundColor:[UIColor whiteColor]];
    self.confirmationView.alpha = 0.8;
    self.confirmationView.layer.cornerRadius = 10.0;
    
    self.confirmationLabel = [[UILabel alloc] init];
    if ([self.friendsInvitedDictionary count] > 1) {
        self.confirmationLabel.text = @"Sending invitations...";
    } else {
        self.confirmationLabel.text = @"Sending invitation...";
    }
    self.confirmationLabel.textColor = UIColorFromRGB(0x8e0528);
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.confirmationLabel.font = montserrat;
    CGSize size = [self.confirmationLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.confirmationLabel.frame = CGRectMake((self.confirmationView.frame.size.width - size.width) / 2.0, (self.confirmationView.frame.size.height - size.height) / 2.0, size.width, size.height);
    [self.confirmationView addSubview:self.confirmationLabel];
    
    [self.view addSubview:self.confirmationView];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.confirmationView.frame.size.width - SPINNER_SIZE) / 2.0, self.confirmationLabel.frame.origin.y + self.confirmationLabel.frame.size.height + 2.0, SPINNER_SIZE, SPINNER_SIZE)];
    self.activityIndicatorView.color = UIColorFromRGB(0x8e0528);
    [self.confirmationView addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
    
    [self performSelector:@selector(dismissConfirmation) withObject:Nil afterDelay:2.0];
}

-(void)dismissConfirmation {
    [self.activityIndicatorView stopAnimating];
    if ([self.friendsInvitedDictionary count] > 1) {
        self.confirmationLabel.text = @"Invitations sent";
    } else {
        self.confirmationLabel.text = @"Invitation sent";
    }
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    self.confirmationLabel.font = montserrat;
    CGSize size = [self.confirmationLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.confirmationLabel.frame = CGRectMake((self.confirmationView.frame.size.width - size.width) / 2.0, (self.confirmationView.frame.size.height - size.height) / 2.0, size.width, size.height);
    
    [UIView animateWithDuration:0.2
                          delay:0.5
                        options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                                self.confirmationView.alpha = 0.2;
                        } completion:^(BOOL finished) {
                                [self.confirmationView removeFromSuperview];
                                [self closeView];
    }];
}

#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (searchBar == self.placeSearchBar) {
        [self.placeSearchBar setShowsCancelButton:YES animated:YES];
    } else if (searchBar == self.searchBar) {
        [self.searchBar setShowsCancelButton:YES animated:YES];
        [self searchFriends:@""];
        self.friendSearchResultsTableView.hidden = NO;
    }
    [searchBar becomeFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text=@"";
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    
    if (searchBar == self.placeSearchBar) {
        self.placeSearchResultsArray = nil;
        [self.placeSearchResultsTableView reloadData];
        self.placeSearchResultsTableView.hidden = YES;
        if (self.place) {
         [self hideSearchPlaces];
        }
    } if (searchBar == self.searchBar) {
        self.friendSearchResultsArray = nil;
        [self.friendSearchResultsTableView reloadData];
        self.friendSearchResultsTableView.hidden = YES;
        [self hideSearchFriends];
        if (!self.place) {
            [self.placeSearchBar setHidden:NO];
        }
        [self layoutPlusIcon];
        [self layoutFriendsInvitedView];
    }
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchBar == self.placeSearchBar) {
        self.placeSearchResultsTableView.hidden = NO;
    } else if (searchBar == self.searchBar) {
        self.friendSearchResultsTableView.hidden = NO;
        [self searchFriends:searchBar.text];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self loadPlacesForSearch:searchBar.text];
}

-(void)searchFriends:(NSString*)searchText {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.friendSearchResultsArray = [[NSMutableArray alloc] init];
    
    if ([searchText isEqualToString:@""]) {
        for(id key in sharedDataManager.tetherFriendsDictionary) {
            [self.friendSearchResultsArray addObject:[sharedDataManager.tetherFriendsDictionary objectForKey:key]];
        }
    } else {
        searchText = [searchText lowercaseString];
        for(id key in sharedDataManager.tetherFriendsDictionary) {
            Friend *friend = [sharedDataManager.tetherFriendsDictionary objectForKey:key];
            if (!friend.blocked && ![friend.friendID isEqualToString:sharedDataManager.facebookId] && ![self.friendsInvitedDictionary objectForKey:friend.friendID]) {
                NSString *name = [friend.name lowercaseString];
                if ([name rangeOfString:searchText].location != NSNotFound) {
                    [self.friendSearchResultsArray addObject:friend];
                }
            }
        }
    }
    [self.friendSearchResultsTableView reloadData];
}

// Search foursquare data call
- (void)loadPlacesForSearch:(NSString*)search {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    NSString *today = [formatter stringFromDate:[NSDate date]];
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSString *urlString1 = @"https://api.foursquare.com/v2/venues/search?near=";
    NSString *urlString2 = @"&query=";
    NSString *urlString3 = @"&limit=50&client_id=VLMUFMIAUWTTEVXXFQEQNKFDMCOFYEHTZU1U53IPQCI1PONX&client_secret=RH1CZUW0WWVM5LIEGZNFLU133YZX1ZMESAJ4PWNSDDSFMGYS&v=";
    NSString *joinString=[NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",urlString1,[userDetails objectForKey:@"city"] ,@"%20",[userDetails objectForKey:@"state"],urlString2, search, urlString3, today];
    joinString = [joinString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:joinString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        [self processSearchResults:jsonDict];
        [Flurry logEvent:@"Foursquare_User_Search_Invite"];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure");
    }];
    [operation start];
}

- (void)processSearchResults:(NSDictionary *)json {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSDictionary *response = [json objectForKey:@"response"];
    self.placeSearchResultsArray = [[NSMutableArray alloc] init];
    NSArray *venues = [response objectForKey:@"venues"];
    for (NSDictionary *venue in venues) {
        Place *newPlace = [[Place alloc] init];
        newPlace.placeId = [venue objectForKey:@"id"];
        newPlace.name = [venue objectForKey:@"name"];
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake([(NSString*)[[venue objectForKey:@"location"] objectForKey:@"lat"] doubleValue], [[[venue objectForKey:@"location"] objectForKey:@"lng"] doubleValue]);
        newPlace.coord = location;
        newPlace.city = [userDetails objectForKey:@"city"];
        newPlace.state = [userDetails objectForKey:@"state"];
        NSDictionary *locationDetails = [venue objectForKey:@"location"];
        newPlace.address = [locationDetails objectForKey:@"address"];
        
        [self.placeSearchResultsArray addObject:newPlace];
    }
    [self.placeSearchResultsTableView reloadData];
}

#pragma mark UITableViewDataSource Methods

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, CELL_HEIGHT)];
    TethrButton *button = [[TethrButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, CELL_HEIGHT)];
    [button setNormalColor:[UIColor whiteColor]];
    [button setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [button setTitle:@"Invite more friends..." forState:UIControlStateNormal];
    
    [button addTarget:self action:@selector(openSMSDialog:) forControlEvents:UIControlEventTouchUpInside];
    
    UIFont *montserratBold = [UIFont fontWithName:@"Montserrat" size:14.0f];
    button.titleLabel.font = montserratBold;
    [button setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    
    [header addSubview:button];
    return header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CELL_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.placeSearchResultsTableView) {
        return SEARCH_RESULTS_CELL_HEIGHT;
    } else {
        return CELL_HEIGHT;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.placeSearchResultsTableView) {
        return [self.placeSearchResultsArray count] + 1;
    } else {
        return [self.friendSearchResultsArray count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.placeSearchResultsTableView) {
        if (indexPath.row == [self.placeSearchResultsArray count]) {
            UIImageView *foursquareImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"poweredByFoursquare"]];
            foursquareImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, SEARCH_RESULTS_CELL_HEIGHT);
            foursquareImageView.contentMode = UIViewContentModeScaleAspectFit;
            UITableViewCell *cell = [[UITableViewCell alloc] init];
            [cell addSubview:foursquareImageView];
            return cell;
        }
        SearchResultCell *cell = [[SearchResultCell alloc] init];
        Place *p = [self.placeSearchResultsArray objectAtIndex:indexPath.row];
        cell.place = p;
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:18];
        UIFont *montserratSubLabelFont = [UIFont fontWithName:@"Montserrat" size:12];
        UILabel *placeNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20.0)];
        placeNameLabel.text = p.name;
        placeNameLabel.font = montserrat;
        [cell addSubview:placeNameLabel];
        UILabel *placeAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30.0, self.view.frame.size.width, 15.0)];
        placeAddressLabel.text = p.address;
        placeAddressLabel.font = montserratSubLabelFont;
        [cell addSubview:placeAddressLabel];
        
        return cell;
    } else {
        FriendAtPlaceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (!cell) {
            cell = [[FriendAtPlaceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        }
        [cell setFriend:[self.friendSearchResultsArray objectAtIndex:indexPath.row]];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView ==  self.placeSearchResultsTableView) {
        SearchResultCell *cell = (SearchResultCell*)[tableView cellForRowAtIndexPath:indexPath];
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        if (![sharedDataManager.foursquarePlacesDictionary objectForKey:cell.place.placeId]) {
            [sharedDataManager.foursquarePlacesDictionary setObject:cell.place forKey:cell.place.placeId];
        }
        [self searchBarCancelButtonClicked:self.placeSearchBar];
        [self setDestination:cell.place];
    } else {
        Friend *friend = [self.friendSearchResultsArray objectAtIndex:indexPath.row];
        [self searchBarCancelButtonClicked:self.searchBar];
        [self addFriend:friend];
        [self layoutFriendLabels];
        [self layoutPlusIcon];
        [self layoutFriendsInvitedView];
    }
}

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    if (self.messageTextView.tag == 0) {
        self.messageTextView.text = @"";
        self.messageTextView.textColor = [UIColor blackColor];
        self.messageTextView.tag = 1;
    }
    
    return YES;
}

#pragma mark TextViewDelegate

-(void) textViewDidChange:(UITextView *)textView
{
    if(self.messageTextView.text.length == 0){
        self.messageTextView.textColor = UIColorFromRGB(0xc8c8c8);
        self.messageTextView.text = @"Compose a message";
        [self.messageTextView resignFirstResponder];
        self.messageTextView.tag = 0;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        if(self.messageTextView.text.length == 0){
            self.messageTextView.textColor = UIColorFromRGB(0xc8c8c8);
            self.messageTextView.text = @"Compose a message";
            [self.messageTextView resignFirstResponder];
            self.messageTextView.tag = 0;
        }
        return NO;
    }
    
    return YES;
}

#pragma mark MessageComposeViewController

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            [Flurry logEvent:@"User_Sent_SMS"];
            break;
            
        default:
            break;
    }
    
    [UIView animateWithDuration:0.6*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [controller.view setFrame:CGRectMake(0.0f, self.view.frame.size.height + 40.0, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [controller.view removeFromSuperview];
                         [controller removeFromParentViewController];
                     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
