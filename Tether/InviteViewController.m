//
//  InviteViewController.m
//  Tether
//
//  Created by Laura Smith on 12/19/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "Friend.h"
#import "FriendAtPlaceCell.h"
#import "FriendLabel.h"
#import "InviteViewController.h"

#define CELL_HEIGHT 60.0
#define LABEL_HEIGHT 30.0
#define MAX_MESSAGE_FIELD_HEIGHT 210.0
#define SEARCH_BAR_HEIGHT 40.0
#define SEARCH_BAR_WIDTH 280.0
#define STATUS_BAR_HEIGHT 20.0
#define PADDING 10.0

@interface InviteViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (retain, nonatomic) UISearchBar *searchBar;
@property (retain, nonatomic) NSMutableArray *friendSearchResultsArray;
@property (nonatomic, strong) UITableView *friendSearchResultsTableView;
@property (nonatomic, strong) UITableViewController *friendSearchResultsTableViewController;
@property (retain, nonatomic) UIScrollView *friendsInvitedScrollView;
@property (retain, nonatomic) UIView * topBarView;
@property (retain, nonatomic) UIView *searchBarBackgroundView;
@property (retain, nonatomic) NSMutableDictionary *friendsInvitedDictionary;
@property (retain, nonatomic) NSMutableDictionary *friendsLabelsDictionary;
@property (retain, nonatomic) NSMutableDictionary *removeLabelButtonsDictionary;
@property (retain, nonatomic) UITextView *messageTextView;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UIButton *backButtonLarge;
@property (assign, nonatomic) NSInteger friendsInvitedViewHeight;
@property (assign, nonatomic) NSInteger friendsInvitedViewWidth;
@property (retain, nonatomic) UIButton *sendButton;
@property (retain, nonatomic) UITextField *placeTextField;
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
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    self.topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50.0)];
    [self.topBarView setBackgroundColor:UIColorFromRGB(0x8e0528)];
    
    self.placeTextField = [[UITextField alloc] initWithFrame:CGRectMake(30.0, 10.0, self.view.frame.size.width - 40.0, 40.0)];
    self.placeTextField.text = self.place.name;
    [self.placeTextField setTextColor:[UIColor whiteColor]];
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:22];
    self.placeTextField.font = montserratLarge;
    self.placeTextField.adjustsFontSizeToFitWidth = YES;
    self.placeTextField.userInteractionEnabled = NO;
    [self.topBarView addSubview:self.placeTextField];
    [self.view addSubview:self.topBarView];
    
    self.searchBarBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, self.topBarView.frame.size.height, self.view.frame.size.width, SEARCH_BAR_HEIGHT)];
    [self.searchBarBackgroundView setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:self.searchBarBackgroundView];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake((self.view.frame.size.width - SEARCH_BAR_WIDTH) / 2, self.topBarView.frame.size.height, SEARCH_BAR_WIDTH, SEARCH_BAR_HEIGHT)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Invite friends...";
    [self.searchBar setBackgroundImage:[UIImage new]];
    [self.searchBar setTranslucent:YES];
    [self.view addSubview:self.searchBar];
    
    self.friendsInvitedScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.searchBarBackgroundView.frame.origin.y + self.searchBarBackgroundView.frame.size.height, self.view.frame.size.width, PADDING)];
    [self.friendsInvitedScrollView setBackgroundColor:[UIColor blackColor]];
    self.friendsInvitedScrollView.showsVerticalScrollIndicator = YES;
    self.friendsInvitedScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [self.view addSubview:self.friendsInvitedScrollView];
    
    self.messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(PADDING, self.friendsInvitedScrollView.frame.origin.y + self.friendsInvitedScrollView.frame.size.height, self.view.frame.size.width - PADDING*2, MAX_MESSAGE_FIELD_HEIGHT)];
    [self.messageTextView setBackgroundColor:[UIColor grayColor]];
    [self.messageTextView setTextColor:[UIColor whiteColor]];
    UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:20];
    [self.messageTextView setFont:montserratBold];
    [self.messageTextView setEditable:YES];
    [self.view addSubview:self.messageTextView];
    
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(220.0, self.messageTextView.frame.origin.y + self.messageTextView.frame.size.height - 50.0, 80.0, 40.0)];
    [self.sendButton addTarget:self action:@selector(sendButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:18.0];
    self.sendButton.titleLabel.font = montserrat;
    [self.sendButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.sendButton setBackgroundColor:[UIColor whiteColor]];
    [self.sendButton setEnabled:NO];
    [self.view addSubview:self.sendButton];
    
    self.friendSearchResultsArray = [[NSMutableArray alloc] init];
    
    self.friendSearchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.searchBarBackgroundView.frame.origin.y + self.searchBarBackgroundView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.searchBarBackgroundView.frame.size.height)];
    [self.friendSearchResultsTableView setDataSource:self];
    [self.friendSearchResultsTableView setDelegate:self];
    [self.friendSearchResultsTableView setHidden:YES];
    [self.view addSubview:self.friendSearchResultsTableView];
    
    self.friendSearchResultsTableViewController = [[UITableViewController alloc] init];
    self.friendSearchResultsTableViewController.tableView = self.friendSearchResultsTableView;
    [self.friendSearchResultsTableView reloadData];
    
    // left panel view button setup
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(10.0,  (self.topBarView.frame.size.height) / 2.0, 10.0, 10.0)];
    [self.backButton setImage:triangleImage forState:UIControlStateNormal];
    [self.view addSubview:self.backButton];
    self.backButton.tag = 1;
    [self.backButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    
    self.backButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, (self.view.frame.size.width) / 4.0, 50.0)];
    [self.backButtonLarge addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButtonLarge];
}

-(void)closeView {
    if ([self.delegate respondsToSelector:@selector(closeInviteView)]) {
        [self.delegate closeInviteView];
    }
}

-(void)layoutFriendsInvitedView {
    self.friendsInvitedScrollView.frame = CGRectMake(0, self.searchBarBackgroundView.frame.origin.y + self.searchBarBackgroundView.frame.size.height, self.view.frame.size.width, MIN(MAX(PADDING,self.friendsInvitedViewHeight), 100));
    self.friendsInvitedScrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.friendsInvitedViewHeight);
    self.friendsInvitedScrollView.contentOffset = CGPointMake(0, self.friendsInvitedViewHeight - self.friendsInvitedScrollView.frame.size.height);
    CGRect frame = self.messageTextView.frame;
    frame.origin.y = self.friendsInvitedScrollView.frame.origin.y + self.friendsInvitedScrollView.frame.size.height;
    frame.size.height = MAX_MESSAGE_FIELD_HEIGHT - self.friendsInvitedScrollView.frame.size.height + 10.0;
    self.messageTextView.frame = frame;
}

-(void)layoutFriendLabels {
    for (UIView *subview in self.friendsInvitedScrollView.subviews) {
        [subview removeFromSuperview];
    }
    
    self.friendsInvitedViewHeight = 0.0;
    self.friendsInvitedViewWidth = 0.0;
    
    for (id key in self.friendsLabelsDictionary) {
        FriendLabel *friendLabel = [self.friendsLabelsDictionary objectForKey:key];
        [self addLabel:friendLabel];
     }
}

-(void)addFriend:(Friend *)friend {
    [self.sendButton setEnabled:YES];
    FriendLabel *friendLabel = [[FriendLabel alloc] init];
    friendLabel.friend = friend;
    [friendLabel setTextColor:[UIColor whiteColor]];
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14];
    friendLabel.font = montserrat;
    CGSize friendLabelSize = [friend.name sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    friendLabel.text = [NSString stringWithFormat:@"  %@", friend.name];
    [friendLabel setBackgroundColor:[UIColor grayColor]];
    friendLabel.layer.cornerRadius = 2.0;
    friendLabel.frame = CGRectMake(0, 0, friendLabelSize.width + 20.0, LABEL_HEIGHT);

    UIButton *xButton = [[UIButton alloc] init];
    [xButton setTitle:@"x" forState:UIControlStateNormal];
    xButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
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
    [self.friendsInvitedScrollView addSubview:friendLabel];
    
    UIButton *xButton = [self.removeLabelButtonsDictionary objectForKey:friendLabel.friend.friendID];
    xButton.frame = CGRectMake(self.friendsInvitedViewWidth - PADDING, self.friendsInvitedViewHeight - LABEL_HEIGHT - 15.0, 15.0, 15.0);
    [self.friendsInvitedScrollView addSubview:xButton];
}


#pragma mark button action handlers

-(IBAction)sendButtonClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    NSMutableArray *friendsInvited = [[NSMutableArray alloc] init];
    for (id key in self.friendsInvitedDictionary) {
        Friend *friend = [self.friendsInvitedDictionary objectForKey:key];
        [friendsInvited addObject:friend.friendID];
    }
    
    for (id key in self.friendsInvitedDictionary) {
        Friend *friend = [self.friendsInvitedDictionary objectForKey:key];
        PFQuery *friendQuery = [PFUser query];
        [friendQuery whereKey:@"facebookId" equalTo:friend.friendID];
        
        [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
            // Create our Installation query
            PFUser * user = [objects objectAtIndex:0];
            PFQuery *pushQuery = [PFInstallation query];
            [pushQuery whereKey:@"owner" equalTo:user]; //change this to use friends installation
            NSString *messageContent = [NSString stringWithFormat:@"%@ invited you to %@", sharedDataManager.name, self.place.name];
            NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                  messageContent, @"alert",
                                  @"Increment", @"badge",
                                  nil];
            
            // Send push notification to query
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:pushQuery]; // Set our Installation query
            [push setData:data];
            [push sendPushInBackground];
            
            PFObject *invitation = [PFObject objectWithClassName:@"Invitation"];
            [invitation setObject:sharedDataManager.facebookId forKey:@"sender"];
            [invitation setObject:self.place.name forKey:@"placeName"];
            [invitation setObject:self.place.placeId forKey:@"placeId"];
            [invitation setObject:messageContent forKey:@"messageHeader"];
            [invitation setObject:self.messageTextView.text forKey:@"message"];
            [invitation setObject:friend.friendID forKey:@"recipientID"];
            [invitation setObject:friendsInvited forKey:@"allRecipients"];
            [invitation saveInBackground];
            }
        }];
    }
    
    if ([self.delegate respondsToSelector:@selector(closeInviteView)]) {
        [self.delegate closeInviteView];
    }
}

-(IBAction)removeFriend:(id)sender {
    UIButton *button = (UIButton *)sender;
    FriendLabel *label = [self.friendsLabelsDictionary objectForKey:[NSValue valueWithNonretainedObject:button]];
    [label removeFromSuperview];
    [self.friendsInvitedDictionary removeObjectForKey:label.friend.friendID];
    [self.friendsLabelsDictionary removeObjectForKey:[NSValue valueWithNonretainedObject:button]];
    [self layoutFriendLabels];
    [self layoutFriendsInvitedView];
    
    if ([self.friendsInvitedDictionary count] == 0) {
        [self.sendButton setEnabled:NO];
    }
}


#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text=@"";
    
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    
    self.friendSearchResultsArray = nil;
    [self.friendSearchResultsTableView reloadData];
    self.friendSearchResultsTableView.hidden = YES;
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.friendSearchResultsTableView.hidden = NO;
    [self searchFriends:searchBar.text];
}

-(void)searchFriends:(NSString*)searchText {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.friendSearchResultsArray = [[NSMutableArray alloc] init];
    searchText = [searchText lowercaseString];
    for(id key in sharedDataManager.tetherFriendsDictionary) {
        Friend *friend = [sharedDataManager.tetherFriendsDictionary objectForKey:key];
        NSString *name = [friend.name lowercaseString];
        if ([name rangeOfString:searchText].location != NSNotFound) {
            [self.friendSearchResultsArray addObject:friend];
        }
    }
    [self.friendSearchResultsTableView reloadData];
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
        return CELL_HEIGHT;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.friendSearchResultsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FriendAtPlaceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[FriendAtPlaceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    [cell setFriend:[self.friendSearchResultsArray objectAtIndex:indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Friend *friend = [self.friendSearchResultsArray objectAtIndex:indexPath.row];
    [self addFriend:friend];
    [self layoutFriendsInvitedView];
    [self searchBarCancelButtonClicked:self.searchBar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
