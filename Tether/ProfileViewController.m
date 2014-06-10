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

@interface ProfileViewController () <UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, ActivityCellDelegate, PartcipantsListViewControllerDelegate, EditProfileViewControllerDelegate, UIActionSheetDelegate, CommentViewControllerDelegate>

@property (retain, nonatomic) UIView * topBar;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) TethrButton *tethrsButton;
@property (nonatomic, strong) TethrButton *followersButton;
@property (nonatomic, strong) TethrButton *followingButton;
@property (retain, nonatomic) UIView * separatorBar;
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
@property (assign, nonatomic) BOOL isPrivate;

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
    [self.view addSubview:self.topBar];
    
    UIImage *triangleImage = [UIImage imageNamed:@"RedTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, TOP_BAR_HEIGHT)];
    [self.backButton setImage:triangleImage forState:UIControlStateNormal];
    [self.backButton setImageEdgeInsets:UIEdgeInsetsMake(17.0, 0.0, 0.0, 32.0)];
    [self.backButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButton];
    
    self.nameLabel = [[UILabel alloc] init];
    if (self.isPrivate) {
        self.nameLabel.text = self.user.firstName;
    } else {
        self.nameLabel.text = self.user.name;
    }
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    [self.nameLabel setTextColor:UIColorFromRGB(0x8e0528)];
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
    }
    
    self.separatorBar = [[UIView alloc] initWithFrame:CGRectMake(0, TOP_BAR_HEIGHT - 1.0, self.view.frame.size.width, 1.0)];
    [self.separatorBar setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.topBar addSubview:self.separatorBar];
    
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
    [self loadActivity];
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

-(void)viewFollowers:(id)sender {
    self.participantsListViewController = [[ParticipantsListViewController alloc] init];
    self.participantsListViewController.participantIds = [self.user.friendsArray mutableCopy];
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

-(void)followClicked:(id)sender {
    
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
    [actionSheet showInView:self.view];
    self.postToDelete = postObject;
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

#pragma mark UITableViewDelegate

-(void)loadActivity {
    PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
    [query whereKey:@"user" equalTo:self.user.object];
    [query includeKey:@"photo"];
    [query includeKey:@"user"];
    [query orderByDescending:@"date"];
    [query setLimit:50.0];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.activityArray = [[NSMutableArray alloc] initWithArray:objects];
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
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
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
            return self.view.frame.size.width + 100.0 + textRect.size.height;
        } else if ([[object objectForKey:@"type"] isEqualToString:@"comment"]) {
            NSString *userName = [[object objectForKey:@"user"] objectForKey:@"firstName"];
            NSString * placeName = [object objectForKey:@"placeName"];
            NSString *content = [object objectForKey:@"content"];
            NSString *contentString = [NSString stringWithFormat:@"%@ commented on %@: \n\n\"%@\"", userName, placeName, content];
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
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.activityArray count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
        
        UILabel *followersLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 5.0, 50.0, 15.0)];
        followersLabel.text = [NSString stringWithFormat:@"%d", MAX(0,[self.user.followersArray count] - 1)];
        followersLabel.font = montserrat;
        [self.followersButton addSubview:followersLabel];
        
        [headerView addSubview:self.followersButton];
        
        self.followingButton = [[TethrButton alloc] initWithFrame:CGRectMake(230.0, 10.0, 70.0, 50.0)];
        [self.followingButton setTitle:@"following" forState:UIControlStateNormal];
        self.followingButton.titleLabel.font = mission;
        [self.followingButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
        [self.followingButton setNormalColor:[UIColor clearColor]];
        [self.followingButton setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
        [self.followingButton setTitleEdgeInsets:UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)];
        
        UILabel *followingLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 5.0, 50.0, 15.0)];
        followingLabel.text = [NSString stringWithFormat:@"%d", MAX(0, [self.user.friendsArray count] - 1)];
        followingLabel.font = montserrat;
        [self.followingButton addSubview:followingLabel];
        
        [headerView addSubview:self.followingButton];
        
        if (self.user.statusMessage && ![self.user.statusMessage isEqualToString:@""]) {
            self.statusLabel = [[UILabel alloc] init];
            self.statusLabel.text = [NSString stringWithFormat:@"\"%@\"", self.user.statusMessage];
            self.statusLabel.font = montserrat;
            self.statusLabel.adjustsFontSizeToFitWidth = YES;
            CGSize size = [self.statusLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
            self.statusLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, 60.0, MIN(self.view.frame.size.width - LEFT_PADDING*2, size.width), size.height);
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
            
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2.0, 125.0, 1.0, 35.0)];
            [separator setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
            [headerView addSubview:separator];
            
            self.followButton = [[TethrButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2.0, 120.0, self.view.frame.size.width / 2.0, 60.0)];
            [self.followButton addTarget:self action:@selector(followClicked:) forControlEvents:UIControlEventTouchUpInside];
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            UIImageView * pinImageView = [[UIImageView alloc] initWithFrame:CGRectMake(((self.view.frame.size.width - PADDING * 2) / 2.0 - 25.0) / 2.0, 0.0, 30.0, 30.0)];
            pinImageView.contentMode = UIViewContentModeScaleAspectFit;
            [self.followButton addSubview:pinImageView];
            
            if ([sharedDataManager.tetherFriends containsObject:self.user.friendID]) {
                pinImageView.image = [UIImage imageNamed:@"PinIcon"];
                [self.followButton setTitle:@"following" forState:UIControlStateNormal];
            } else {
            pinImageView.image = [UIImage imageNamed:@"GreyPinIcon"];
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
        }
        
        [cell addSubview:headerView];
        return cell;
    }
    
    ActivityCell *cell = [[ActivityCell alloc] init];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    cell.delegate = self;
    [cell setActivityObject:[self.activityArray objectAtIndex:indexPath.row - 1]];
    return cell;
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
