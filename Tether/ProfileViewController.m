//
//  ProfileViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-05-26.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "ActivityCell.h"
#import "CenterViewController.h"
#import "CommentViewController.h"
#import "Constants.h"
#import "Datastore.h"
#import "EditProfileViewController.h"
#import "FollowRequestCell.h"
#import "NotificationCell.h"
#import "ParticipantsListViewController.h"
#import "ProfileViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#define LEFT_PADDING 40.0
#define PADDING 15.0
#define PROFILE_IMAGE_VIEW_SIZE 80.0
#define SLIDE_TIMING 0.6
#define STATUS_BAR_HEIGHT 20.0
#define STATUS_MESSAGE_LENGTH 35.0
#define SPINNER_SIZE 30.0
#define TOP_BAR_HEIGHT 70.0

@interface ProfileViewController () <UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, ActivityCellDelegate, PartcipantsListViewControllerDelegate, EditProfileViewControllerDelegate, UIActionSheetDelegate, CommentViewControllerDelegate, NotificationCellDelegate, FollowRequestCellDelegate>

@property (retain, nonatomic) UIView * topBar;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) TethrButton *tethrsButton;
@property (nonatomic, strong) TethrButton *followersButton;
@property (retain, nonatomic) UILabel * followersLabel;
@property (nonatomic, strong) TethrButton *followingButton;
@property (retain, nonatomic) UILabel * followingLabel;
@property (nonatomic, strong) FBProfilePictureView *userProfilePictureView;
@property (retain, nonatomic) TethrButton * messageButton;
@property (retain, nonatomic) TethrButton * followButton;
@property (nonatomic, strong) UITableView *activityTableView;
@property (nonatomic, strong) UITableViewController *activityTableViewController;
@property (retain, nonatomic) NSMutableArray * activityArray;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) ParticipantsListViewController * participantsListViewController;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (assign, nonatomic) int isCurrentUser;
@property (retain, nonatomic) UIButton * settingsButton;
@property (retain, nonatomic) UILabel * goingOutLabel;
@property (retain, nonatomic) UISwitch * goingOutSwitch;
@property (retain, nonatomic) UILabel * cityLabel;
@property (retain, nonatomic) EditProfileViewController * editProfileVC;
@property (nonatomic, strong) NSMutableDictionary *activityObjectsDictionary;
@property (retain, nonatomic) PFObject * postToDelete;
@property (retain, nonatomic) CommentViewController * commentVC;
@property (retain, nonatomic) UIImageView * followImageView;
@property (retain, nonatomic) UIImageView * messageImageView;
@property (assign, nonatomic) BOOL isFriend;
@property (assign, nonatomic) BOOL isPrivate;
@property (nonatomic, strong) UITableView *notificationTableView;
@property (nonatomic, strong) UITableViewController *notificationsTableViewController;
@property (retain, nonatomic) NSMutableArray * notificationsArray;
@property (retain, nonatomic) NSMutableArray * requestsArray;
@property (retain, nonatomic) UIButton *feedButton;
@property (retain, nonatomic) UIButton *bellButton;

@end

@implementation ProfileViewController

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
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    if ([self.user.friendID isEqualToString:sharedDataManager.facebookId]) {
        self.isCurrentUser = YES;
    } else if (![sharedDataManager.tetherFriends containsObject:self.user.friendID] && self.user.isPrivate) {
        self.isPrivate = YES;
    }
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBack:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:self.topBar];
    
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, TOP_BAR_HEIGHT)];
    [self.backButton setImage:triangleImage forState:UIControlStateNormal];
    [self.backButton setImageEdgeInsets:UIEdgeInsetsMake(17.0, 0.0, 0.0, 32.0)];
    [self.backButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButton];
    
    self.nameLabel = [[UILabel alloc] init];
    if ([sharedDataManager.tetherFriends containsObject:self.user.friendID]) {
        self.isFriend = YES;
    }
    if (!self.isFriend) {
        self.nameLabel.text = self.user.firstName;
    } else {
        self.nameLabel.text = self.user.name;
    }
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    [self.nameLabel setTextColor:[UIColor whiteColor]];
    self.nameLabel.font = montserrat;
    self.nameLabel.adjustsFontSizeToFitWidth = YES;
    CGSize size = [self.nameLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.nameLabel.frame = CGRectMake(MAX(LEFT_PADDING, (self.view.frame.size.width - size.width) / 2.0), STATUS_BAR_HEIGHT + (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT - size.height) / 2.0, MIN(self.view.frame.size.width - LEFT_PADDING*2, size.width), size.height);
    [self.topBar addSubview:self.nameLabel];
    
    if (self.isCurrentUser) {
        self.settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 50.0, STATUS_BAR_HEIGHT, 50.0, 50.0)];
        [self.settingsButton setImage:[UIImage imageNamed:@"Gear.png"] forState:UIControlStateNormal];
        [self.settingsButton addTarget:self action:@selector(openEditProfileView) forControlEvents:UIControlEventTouchUpInside];
        [self.topBar addSubview:self.settingsButton];
    } else {
        self.settingsButton = [[UIButton alloc] init];
        [self.settingsButton addTarget:self action:@selector(friendSettingsClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.settingsButton setTitle:@"..." forState:UIControlStateNormal];
        [self.settingsButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
        [self.settingsButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 8.0, 0.0)];
        self.settingsButton.frame= CGRectMake(self.view.frame.size.width - 50.0, (TOP_BAR_HEIGHT + STATUS_BAR_HEIGHT - 17.0) / 2.0, 30.0, 17.0);
        self.settingsButton.layer.borderWidth = 1.0;
        self.settingsButton.layer.borderColor = UIColorFromRGB(0xc8c8c8).CGColor;
        self.settingsButton.layer.cornerRadius = 2.0;
        self.settingsButton.layer.masksToBounds = YES;
        [self.topBar addSubview:self.settingsButton];
    }
    
    self.activityTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
    [self.activityTableView setDataSource:self];
    [self.activityTableView setDelegate:self];
    self.activityTableView.showsVerticalScrollIndicator = NO;
    
    self.activityTableViewController = [[UITableViewController alloc] init];
    self.activityTableViewController.tableView = self.activityTableView;
    
    if (self.isPrivate) {
        [self.view addSubview:self.activityTableView];
        
        UIImageView *lockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Lock.png"]];
        lockImageView.frame = CGRectMake((self.view.frame.size.width - 30.0) / 2.0, self.view.frame.size.height / 2.0 + 10.0, 30.0, 30.0);
        [self.view addSubview:lockImageView];
        
        UILabel *privateLabel = [[UILabel alloc] init];
        privateLabel.text = @"Private user";
        privateLabel.font = montserrat;
        privateLabel.textColor = UIColorFromRGB(0xc8c8c8);
        size = [privateLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
        privateLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, self.view.frame.size.height / 2.0 + 50.0, size.width, size.height);

        [self.view addSubview:privateLabel];
        self.activityArray = [[NSMutableArray alloc] init];
        self.activityTableView.frame = CGRectMake(0, TOP_BAR_HEIGHT, self.view.frame.size.width, 180.0);
        [self.activityTableView reloadData];
    } else {
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - SPINNER_SIZE) / 2.0, TOP_BAR_HEIGHT + 10.0, SPINNER_SIZE, SPINNER_SIZE)];
        self.activityIndicatorView.color = UIColorFromRGB(0x8e0528);
        [self.view addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
        
        [self loadActivity];
    }
}

-(void)closeView {
    if ([self.delegate respondsToSelector:@selector(closeProfileViewController:)]) {
        [self.delegate closeProfileViewController:self];
    }
}

-(void)openEditProfileView {
    self.editProfileVC = [[EditProfileViewController alloc] init];
    self.editProfileVC.delegate = self;
    [self.editProfileVC didMoveToParentViewController:self];
    [self.editProfileVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:self.editProfileVC.view];
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.editProfileVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

#pragma mark EditProfileViewControllerDelegate

-(void)closeEditProfileVC {
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.editProfileVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.editProfileVC.view removeFromSuperview];
                         [self.editProfileVC removeFromParentViewController];
                         self.editProfileVC = nil;
                         [self loadActivity];
                     }];
}

-(void)userChangedSettingsToUseCurrentLocation {
    if ([self.delegate respondsToSelector:@selector(userChangedSettingsToUseCurrentLocation)]) {
        [self.delegate userChangedSettingsToUseCurrentLocation];
    }
}

-(void)userChangedLocationInSettings:(CLLocation*)newLocation{
    if ([self.delegate respondsToSelector:@selector(userChangedLocationInSettings:)]) {
        [self.delegate userChangedLocationInSettings:newLocation];
    }
}

#pragma mark IBAction

-(void)friendSettingsClicked:(id)sender {
    UIActionSheet *actionSheet;
    if (self.user.blocked) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Unblock User", nil];
        actionSheet.delegate = self;
        actionSheet.tag = 1;
        [actionSheet showInView:self.view];
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Block User", nil];
        actionSheet.delegate = self;
        actionSheet.tag = 2;
        [actionSheet showInView:self.view];
    }
}

-(void)viewFollowers:(id)sender {
    self.participantsListViewController = [[ParticipantsListViewController alloc] init];
    self.participantsListViewController.participantIds = [self.user.followersArray mutableCopy];
    self.participantsListViewController.dontShowId = self.user.friendID;
    self.participantsListViewController.topBarLabel = [[UILabel alloc] init];
    [self.participantsListViewController.topBarLabel setText:@"Followers"];
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

-(void)viewFollowing:(id)sender {
    self.participantsListViewController = [[ParticipantsListViewController alloc] init];
    self.participantsListViewController.participantIds = [self.user.friendsArray mutableCopy];
    self.participantsListViewController.dontShowId = self.user.friendID;
    self.participantsListViewController.topBarLabel = [[UILabel alloc] init];
    [self.participantsListViewController.topBarLabel setText:@"Following"];
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

-(void)moveBack:(id)sender {
    [[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];
    
    CGPoint velocity = [(UIPanGestureRecognizer*)sender velocityInView:[sender view]];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if(velocity.x > 0) {
            [self closeView];
        }
    }
}

-(void)messageClicked:(id)sender {
    if ([self.delegate respondsToSelector:@selector(openMessageForFriend:)]) {
        [self.delegate openMessageForFriend:self.user];
    }
}

-(void)setupFollowButton {
    if (self.isFriend) {
        self.followImageView.image = [UIImage imageNamed:@"PinIcon"];
        [self.followButton setTitle:@"following" forState:UIControlStateNormal];
    } else {
        if (self.followButton.tag == 1) {
            self.followImageView.image = [UIImage imageNamed:@"GreyPinIcon"];
            [self.followButton setTitle:@"pending" forState:UIControlStateNormal];
        } else {
            self.followImageView.image = [UIImage imageNamed:@"GreyPinIcon"];
            [self.followButton setTitle:@"follow" forState:UIControlStateNormal];
        }
    }
}

-(void)followClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];

    if (!self.isFriend) {
        // different if private user -> send request

        if (self.user.isPrivate) {
            self.followButton.tag = 1;
        } else {
             self.isFriend = YES;
            self.followersLabel.text = [NSString stringWithFormat:@"%lu", MAX(0,[self.user.followersArray count] - 1)];
        }
        
        [self setupFollowButton];
        [self followerUser:self.user following:YES];
        
    } else {
        [sharedDataManager.tetherFriendsDictionary removeObjectForKey:self.user.friendID];
        [sharedDataManager.tetherFriendsNearbyDictionary removeObjectForKey:self.user.friendID];
        
        self.followersLabel.text = [NSString stringWithFormat:@"%d", MAX(0,[self.user.followersArray count] - 1)];
        
        self.isFriend = NO;
        [self setupFollowButton];
        
        [self followerUser:self.user following:NO];
    }
}

-(void)followerUser:(Friend*)friend following:(BOOL)adding {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (adding) {
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
            PFUser *user = [PFUser currentUser];
            NSMutableSet *tethrFriendsSet = [NSMutableSet setWithArray:[user objectForKey:@"tethrFriends"]];
            [tethrFriendsSet addObject:friend.friendID];
            [user setObject:[tethrFriendsSet allObjects] forKey:@"tethrFriends"];
            [user saveInBackground];
            
            NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
            [userDetails setObject:[tethrFriendsSet allObjects] forKey:@"tethrFriends"];
            [userDetails synchronize];
            if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
                [self.delegate pollDatabase];
            }
            
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
    } else {
        // unfollow user
        PFUser *user = [PFUser currentUser];
        NSMutableSet *tethrFriendsSet = [NSMutableSet setWithArray:[user objectForKey:@"tethrFriends"]];
        [tethrFriendsSet removeObject:friend.friendID];
        [user setObject:[tethrFriendsSet allObjects] forKey:@"tethrFriends"];
        [user saveInBackground];
        
        NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
        [userDetails setObject:[tethrFriendsSet allObjects] forKey:@"tethrFriends"];
        [userDetails synchronize];
        if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
            [self.delegate pollDatabase];
        }
        
        // remove yourself from this users folowers
        NSMutableSet *followersSet = [NSMutableSet setWithArray:[[friend.object objectForKey:@"followers"] mutableCopy]];
        [followersSet removeObject:sharedDataManager.facebookId];
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
        
        friend.followersArray = followersArray;
        [sharedDataManager.tetherFriendsDictionary removeObjectForKey:friend.friendID];
    }
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

-(void)showProfileOfFriend:(Friend*)user {
    if ([self.delegate respondsToSelector:@selector(showProfileOfFriend:)]) {
        [self.delegate showProfileOfFriend:user];
    }
}

-(void)scrollToPost:(NSString*)postId {
    PFObject *object = [self.activityObjectsDictionary objectForKey:postId];
    
    [self.activityTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([self.activityArray indexOfObject:object] + 1) inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    if (self.openComment) {
        [self showComments:object];
        self.openComment = NO;
    }
}

#pragma mark ParticipantsListViewControllerDelegate

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


#pragma mark ActivityCellDelegate

-(void)openPlace:(Place*)place {
    if ([self.delegate respondsToSelector:@selector(openPageForPlaceWithId:)]) {
        [self.delegate openPageForPlaceWithId:place.placeId];
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

-(void)postSettingsClicked:(PFObject*)postObject {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Delete Post", nil];
    actionSheet.delegate = self;
    [actionSheet showInView:self.view];
    self.postToDelete = postObject;
}

#pragma mark RequestCellDelegate

-(void)acceptRequest:(PFObject*)requestObject {
    PFUser *user = [requestObject objectForKey:@"fromUser"];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSMutableSet *followingSet = [NSMutableSet setWithArray:[[user objectForKey:@"tethrFriends"] mutableCopy]];
    [followingSet addObject:sharedDataManager.facebookId];
    NSArray *followingArray = [followingSet allObjects];
    
    [PFCloud callFunctionInBackground:@"SetTethrFriends"
                       withParameters:@{@"userId": [user objectForKey:@"facebookId"], @"tethrFriends": followingArray}
                                block:^(NSArray *results, NSError *error) {
                                    if (!error) {
                                        
                                    } else {
                                        NSLog(@"%@", [error description]);
                                    }
                                }];
    
    NSMutableSet *followersSet = [NSMutableSet setWithArray:[[[PFUser currentUser] objectForKey:@"followers"] mutableCopy]];
    [followersSet addObject:[user objectForKey:@"facebookId"]];
    NSArray *followersArray = [followersSet allObjects];
    
    [PFCloud callFunctionInBackground:@"SetFollowers"
                       withParameters:@{@"userId": sharedDataManager.facebookId, @"followers": followersArray}
                                block:^(NSArray *results, NSError *error) {
                                    if (!error) {
                                        
                                    } else {
                                        NSLog(@"%@", [error description]);
                                    }
                                }];
    

    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [userDetails setObject:followersArray forKey:@"followers"];
    
    [self.requestsArray removeObject:requestObject];
    [self.notificationTableView reloadData];
    [requestObject deleteInBackground];
}

-(void)declineRequest:(PFObject*)requestObject {
    [self.requestsArray removeObject:requestObject];
    [self.notificationTableView reloadData];
    [requestObject deleteInBackground];
}

#pragma mark CommentViewControllerDelegate

-(void)closeCommentView {
    [self.activityTableView reloadData];
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

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 2) {
        if (buttonIndex == 0) {
            if ([self.delegate respondsToSelector:@selector(blockFriend:block:)]) {
                [self.delegate blockFriend:self.user block:YES];
            }
            
            [self closeView];
        }
    } else if (actionSheet.tag == 1) {
        if (buttonIndex == 0) {
            if ([self.delegate respondsToSelector:@selector(blockFriend:block:)]) {
                [self.delegate blockFriend:self.user block:NO];
            }
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
                    }
                    else {
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
            if ([button.titleLabel.text isEqualToString:@"Delete Post"] || [button.titleLabel.text isEqualToString:@"Block User"]) {
                [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            }
        }
    }
}

#pragma mark UITableViewDelegate

-(void)loadActivity {
    if (!self.editProfileVC) {
        PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
        [query whereKey:@"user" equalTo:self.user.object];
        [query includeKey:@"photo"];
        [query includeKey:@"user"];
        [query orderByDescending:@"date"];
        [query setLimit:50.0];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            self.activityArray = [[NSMutableArray alloc] initWithArray:objects];
            if (!self.editProfileVC) {
                [self.activityTableView reloadData];
                [self.view addSubview:self.activityTableView];
                [self.activityIndicatorView stopAnimating];
                
                self.activityObjectsDictionary = [[NSMutableDictionary alloc] init];
                for (PFObject *object in self.activityArray) {
                    [self.activityObjectsDictionary setObject:object forKey:object.objectId];
                }
                if (self.postId) {
                    [self scrollToPost:self.postId];
                }
            }
        }];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.activityTableView) {
        if (indexPath.row == 0) {
            return 180.0;
        } else {
            PFObject *object = [self.activityArray objectAtIndex:indexPath.row - 1];
            if ([[object objectForKey:@"type"] isEqualToString:@"photo"]) {
                NSString *content = [object objectForKey:@"content"];
                UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
                CGRect textRect = [content boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 60.0, 1000.0)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{NSFontAttributeName:montserrat}
                                                        context:nil];
                return self.view.frame.size.width + 90.0 + textRect.size.height;
            } else if ([[object objectForKey:@"type"] isEqualToString:@"comment"]) {
                NSString *userName = [[object objectForKey:@"user"] objectForKey:@"firstName"];
                NSString * placeName = [object objectForKey:@"placeName"];
                NSString *content = [object objectForKey:@"content"];
                NSString *contentString = [NSString stringWithFormat:@"%@ commented on %@: \n\"%@\"", userName, placeName, content];
                UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
                CGRect textRect = [contentString boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 60.0, 1000.0)
                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                           attributes:@{NSFontAttributeName:montserrat}
                                                              context:nil];
                return textRect.size.height + 80.0;
            } else {
                NSString *userName = [[object objectForKey:@"user"] objectForKey:@"firstName"];
                NSString * placeName = [object objectForKey:@"placeName"];
                NSString *contentString = [NSString stringWithFormat:@"%@ tethred to %@", userName, placeName];
                UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
                CGRect textRect = [contentString boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 60.0, 1000.0)
                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                           attributes:@{NSFontAttributeName:montserrat}
                                                              context:nil];
                return textRect.size.height + 70.0;
            }
        }
    } else {
        if (indexPath.section == 0) {
            return 80.0;
        } else {
            UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
            NSString *contentText = [[self.notificationsArray objectAtIndex:indexPath.row] objectForKey:@"content"];
            CGRect textRect = [contentText boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 70.0, 1000.0)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{NSFontAttributeName:montserrat}
                                                        context:nil];
            
            return MAX(28.0 + 10.0, textRect.size.height) + 20.0;
        }

    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.activityTableView) {
        return 1;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.activityTableView) {
        return [self.activityArray count] + 1;
    } else {
        if (section == 0) {
            return [self.requestsArray count];
        } else {
            return [self.notificationsArray count];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.activityTableView) {
        if (indexPath.row == 0) {
            UITableViewCell *cell = [[UITableViewCell alloc] init];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 180.0)];
            self.userProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:self.user.friendID pictureCropping:FBProfilePictureCroppingSquare];
            self.userProfilePictureView.layer.cornerRadius = 12.0;
            self.userProfilePictureView.clipsToBounds = YES;
            [self.userProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
            self.userProfilePictureView.frame = CGRectMake(PADDING, PADDING, PROFILE_IMAGE_VIEW_SIZE, PROFILE_IMAGE_VIEW_SIZE);
            
            UIImage *maskingImage = [UIImage imageNamed:@"LocationIcon"];
            CALayer *maskingLayer = [CALayer layer];
            CGRect frame = self.userProfilePictureView.bounds;
            frame.origin.x = -7.0;
            frame.origin.y = -7.0;
            frame.size.width += 14.0;
            frame.size.height += 14.0;
            maskingLayer.frame = frame;
            [maskingLayer setContents:(id)[maskingImage CGImage]];
            [self.userProfilePictureView.layer setMask:maskingLayer];
            [headerView addSubview:self.userProfilePictureView];
            
            UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
            UIFont *mission = [UIFont fontWithName:@"MissionGothic-BlackItalic" size:16];
            
            self.tethrsButton = [[TethrButton alloc] initWithFrame:CGRectMake(90.0, 10.0, 50.0, 50.0)];
            [self.tethrsButton setTitle:@"tethrs" forState:UIControlStateNormal];
            self.tethrsButton.titleLabel.font = mission;
            [self.tethrsButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
            [self.tethrsButton setNormalColor:[UIColor clearColor]];
            [self.tethrsButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
            [self.tethrsButton setTitleEdgeInsets:UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)];
            
            UILabel *tethrsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 5.0, 50.0, 15)];
            tethrsLabel.text = [NSString stringWithFormat:@"%d", self.user.tethrCount];
            tethrsLabel.font = montserrat;
            [self.tethrsButton addSubview:tethrsLabel];
            
            [headerView addSubview:self.tethrsButton];
            
            self.followersButton = [[TethrButton alloc] initWithFrame:CGRectMake(150.0, 10.0, 70.0, 50.0)];
            [self.followersButton addTarget:self action:@selector(viewFollowers:) forControlEvents:UIControlEventTouchUpInside];
            [self.followersButton setTitle:@"followers" forState:UIControlStateNormal];
            self.followersButton.titleLabel.font = mission;
            [self.followersButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
            [self.followersButton setNormalColor:[UIColor clearColor]];
            [self.followersButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
            [self.followersButton setTitleEdgeInsets:UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)];
            
            self.followersLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 5.0, 50.0, 15.0)];
            self.followersLabel.text = [NSString stringWithFormat:@"%d", MAX(0,[self.user.followersArray count] - 1)];
            self.followersLabel.font = montserrat;
            [self.followersButton addSubview:self.followersLabel];
            
            [headerView addSubview:self.followersButton];
            
            self.followingButton = [[TethrButton alloc] initWithFrame:CGRectMake(230.0, 10.0, 70.0, 50.0)];
            [self.followingButton addTarget:self action:@selector(viewFollowing:) forControlEvents:UIControlEventTouchUpInside];
            [self.followingButton setTitle:@"following" forState:UIControlStateNormal];
            self.followingButton.titleLabel.font = mission;
            [self.followingButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
            [self.followingButton setNormalColor:[UIColor clearColor]];
            [self.followingButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
            [self.followingButton setTitleEdgeInsets:UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)];
            
            self.followingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 5.0, 50.0, 15.0)];
            self.followingLabel.text = [NSString stringWithFormat:@"%d", MAX(0, [self.user.friendsArray count] - 1)];
            self.followingLabel.font = montserrat;
            [self.followingButton addSubview:self.followingLabel];
            
            [headerView addSubview:self.followingButton];
            
            UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:12.0f];
            if (self.user.statusMessage && ![self.user.statusMessage isEqualToString:@""]) {
                self.statusLabel = [[UILabel alloc] init];
                self.statusLabel.text = [NSString stringWithFormat:@"\"%@\"", self.user.statusMessage];
                self.statusLabel.font = montserratSmall;
                self.statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
                self.statusLabel.numberOfLines = 0;
                CGRect textRect = [self.statusLabel.text boundingRectWithSize:CGSizeMake(self.view.frame.size.width - self.tethrsButton.frame.origin.x, 1000.0)
                                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                                   attributes:@{NSFontAttributeName:montserratSmall}
                                                                      context:nil];
                self.statusLabel.frame = CGRectMake((self.view.frame.size.width - textRect.size.width + self.tethrsButton.frame.origin.x) / 2.0, 60.0, MIN(self.view.frame.size.width - LEFT_PADDING*2, textRect.size.width), textRect.size.height);
                [headerView addSubview:self.statusLabel];
            }
            
            if (!self.isCurrentUser) {
                self.messageButton = [[TethrButton alloc] initWithFrame:CGRectMake(0.0, 120.0, self.view.frame.size.width / 2.0, 60.0)];
                [self.messageButton addTarget:self action:@selector(messageClicked:) forControlEvents:UIControlEventTouchUpInside];
                [self.messageButton setTitle:@"message" forState:UIControlStateNormal];
                self.messageButton.titleLabel.font = mission;
                [self.messageButton setTitleEdgeInsets:UIEdgeInsetsMake(15.0, 0.0, 0.0, 0.0)];
                [self.messageButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
                [self.messageButton setNormalColor:[UIColor clearColor]];
                [self.messageButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
                [headerView addSubview:self.messageButton];
                
                if (self.isPrivate) {
                    [self.messageButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateDisabled];
                    [self.messageButton setEnabled:NO];
                }
                
                self.messageImageView = [[UIImageView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width - PADDING * 2) / 2.0 - 25.0) / 2.0, 0.0, 30.0, 30.0)];
                [self.messageImageView setImage:[UIImage imageNamed:@"ChatIconRed.png"]];
                self.messageImageView.contentMode = UIViewContentModeScaleAspectFit;
                [self.messageButton addSubview:self.messageImageView];
                
                if (!self.isFriend && self.user.isPrivate) {
                    [self.messageButton setNormalColor:UIColorFromRGB(0xc8c8c8)];
                    [self.messageButton setEnabled:NO];
                    [self.messageImageView setImage:[UIImage imageNamed:@"ChatIcon.png"]];
                }
                
                UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2.0, 125.0, 1.0, 35.0)];
                [separator setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
                [headerView addSubview:separator];
                
                self.followButton = [[TethrButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2.0, 120.0, self.view.frame.size.width / 2.0, 60.0)];
                [self.followButton addTarget:self action:@selector(followClicked:) forControlEvents:UIControlEventTouchUpInside];
                Datastore *sharedDataManager = [Datastore sharedDataManager];
                self.followImageView = [[UIImageView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width - PADDING * 2) / 2.0 - 25.0) / 2.0, 0.0, 30.0, 30.0)];
                self.followImageView.contentMode = UIViewContentModeScaleAspectFit;
                [self.followButton addSubview:self.followImageView];
                
                if ([sharedDataManager.tetherFriends containsObject:self.user.friendID]) {
                    self.isFriend = YES;
                }
                
                if (self.isFriend) {
                    self.followImageView.image = [UIImage imageNamed:@"PinIcon"];
                    [self.followButton setTitle:@"following" forState:UIControlStateNormal];
                } else {
                self.followImageView.image = [UIImage imageNamed:@"GreyPinIcon"];
                    [self.followButton setTitle:@"follow" forState:UIControlStateNormal];
                }
                
                self.followButton.titleLabel.font = mission;
                [self.followButton setTitleEdgeInsets:UIEdgeInsetsMake(15.0, 0.0, 0.0, 0.0)];
                [self.followButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
                [self.followButton setNormalColor:[UIColor clearColor]];
                [self.followButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
                [headerView addSubview:self.followButton];
            } else {
                NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
                BOOL goingOut = [userDetails boolForKey:@"status"];
                UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:16.0f];
                self.goingOutLabel = [[UILabel alloc] init];
                self.goingOutLabel.text = @"Going out";
                
                self.goingOutSwitch = [[UISwitch alloc] init];
                self.goingOutSwitch.frame = CGRectMake(self.view.frame.size.width - 125.0, 80.0, 0, 0);
                [self.goingOutSwitch setOnTintColor:UIColorFromRGB(0x8e0528)];
                [self.goingOutSwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
                self.goingOutSwitch.on = goingOut;
                [headerView addSubview:self.goingOutSwitch];
                
                self.goingOutLabel.font = montserratLarge;
                self.goingOutLabel.textColor = UIColorFromRGB(0x1d1d1d);
                CGSize size = [self.goingOutLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLarge}];
                self.goingOutLabel.frame = CGRectMake(self.goingOutSwitch.frame.origin.x - size.width - PADDING, 85.0, size.width, size.height);
                [headerView addSubview:self.goingOutLabel];
                
                if (self.statusLabel) {
                    CGRect frame = self.statusLabel.frame;
                    frame.origin.y = self.goingOutLabel.frame.origin.y + self.goingOutLabel.frame.size.height + PADDING;
                    self.statusLabel.frame = frame;
                }
                
                self.cityLabel = [[UILabel alloc] init];
                NSString *location = [NSString stringWithFormat:@"%@, %@",[userDetails objectForKey:@"city"], [userDetails objectForKey:@"state"]];
                if ([userDetails objectForKey:@"city"] == NULL || [userDetails objectForKey:@"state"] == NULL) {
                    location = @"Edit profile to set your location";
                }
                [self.cityLabel setText:location];
                self.cityLabel.textColor = UIColorFromRGB(0x1d1d1d);
                self.cityLabel.font = montserrat;
                size = [self.cityLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
                CGFloat originY;
                if (self.statusLabel) {
                    originY = self.statusLabel.frame.origin.y + self.statusLabel.frame.size.height;
                } else {
                    originY = self.goingOutLabel.frame.origin.y + self.goingOutLabel.frame.size.height;
                }
                self.cityLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, originY + PADDING, size.width, size.height);
                [headerView addSubview:self.cityLabel];
                
                UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2.0, 145.0, 1.0, 25.0)];
                [separator setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
                [headerView addSubview:separator];
                
                self.feedButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 140.0, self.view.frame.size.width / 2.0, 40.0)];
                [self.feedButton addTarget:self action:@selector(showFeed:) forControlEvents:UIControlEventTouchUpInside];
                [self.feedButton setImage:[UIImage imageNamed:@"PersonalFeedRed.png"] forState:UIControlStateNormal];
                [headerView addSubview:self.feedButton];
                
                self.bellButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2.0, 140.0, self.view.frame.size.width / 2.0, 40.0)];
                [self.bellButton addTarget:self action:@selector(showNotifications:) forControlEvents:UIControlEventTouchUpInside];
                [self.bellButton setImage:[UIImage imageNamed:@"Bell.png"] forState:UIControlStateNormal];
                [headerView addSubview:self.bellButton];
                
                self.notificationTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 180., self.view.frame.size.width, self.view.frame.size.height - 180.0 - TOP_BAR_HEIGHT)];
                [self.notificationTableView setDataSource:self];
                [self.notificationTableView setDelegate:self];
                self.notificationTableView.showsVerticalScrollIndicator = NO;
                [self.notificationTableView setHidden:YES];
                
                self.notificationsTableViewController = [[UITableViewController alloc] init];
                self.notificationsTableViewController.tableView = self.self.notificationTableView;
                
                [self.activityTableView addSubview:self.notificationTableView];
            }
            
            [cell addSubview:headerView];
            
            
            return cell;
        }
        
        ActivityCell *cell = [[ActivityCell alloc] init];
        [cell setFeedType:@"profile"];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        cell.delegate = self;
        [cell setActivityObject:[self.activityArray objectAtIndex:indexPath.row - 1]];
        return cell;
    } else {
        if (indexPath.section == 0 && self.requestsArray) {
            FollowRequestCell *cell = [[FollowRequestCell alloc] init];
            cell.delegate = self;
            [cell setRequestObject:[self.requestsArray objectAtIndex:indexPath.row]];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return cell;
        } else {
            NotificationCell *cell = [[NotificationCell alloc] init];
            cell.delegate = self;
            [cell setNotificationObject:[self.notificationsArray objectAtIndex:indexPath.row]];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return cell;
        }
    }
}

-(IBAction)showFeed:(id)sender {
    [self.activityTableView setScrollEnabled:YES];
    [self.notificationTableView setHidden:YES];
    [self.feedButton setImage:[UIImage imageNamed:@"PersonalFeedRed.png"] forState:UIControlStateNormal];
    [self.bellButton setImage:[UIImage imageNamed:@"Bell.png"] forState:UIControlStateNormal];
}

-(IBAction)showNotifications:(id)sender {
    [self loadRequests];
    [self.activityTableView setScrollEnabled:NO];
    [self.notificationTableView setHidden:NO];
    [self.feedButton setImage:[UIImage imageNamed:@"PersonalFeed.png"] forState:UIControlStateNormal];
    [self.bellButton setImage:[UIImage imageNamed:@"BellRed.png"] forState:UIControlStateNormal];
}

-(void)loadRequests {
    PFQuery *query = [PFQuery queryWithClassName:@"Request"];
    [query whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [query orderByDescending:@"createdAt"];
    [query includeKey:@"fromUser"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.requestsArray = [[NSMutableArray alloc] init];
            self.requestsArray = [objects mutableCopy];
            [self loadNotifications];
        } else {
            [self loadNotifications];
        }
    }];
}

-(void)loadNotifications {
    PFQuery *query = [PFQuery queryWithClassName:@"PersonalNotification"];
    [query whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [query includeKey:@"fromUser"];
    [query orderByDescending:@"createdAt"];
    [query setLimit:100];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.notificationsArray = [[NSMutableArray alloc] init];
            
            self.notificationsArray = [objects mutableCopy];
        }
        [self.notificationTableView reloadData];
    }];
}

- (void)switchChange:(UISwitch *)theSwitch {
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [userDetails setBool:theSwitch.on forKey:@"status"];
    [userDetails synchronize];
    
    PFUser *user = [PFUser currentUser];
    [user setObject:[NSNumber numberWithBool:theSwitch.on] forKey:kUserStatusKey];
    [user setObject:[NSDate date] forKey:kUserTimeLastUpdatedKey];
    [user saveInBackground];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (!theSwitch.on && sharedDataManager.currentCommitmentPlace != nil) {
        if ([self.delegate respondsToSelector:@selector(removePreviousCommitment)]) {
            [self.delegate removePreviousCommitment];
        }
        if ([self.delegate respondsToSelector:@selector(removeCommitmentFromDatabase)]) {
            [self.delegate removeCommitmentFromDatabase];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(pollDatabase)]) {
            [self.delegate pollDatabase];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
