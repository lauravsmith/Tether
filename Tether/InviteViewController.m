//
//  InviteViewController.m
//  Tether
//
//  Created by Laura Smith on 12/19/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Datastore.h"
#import "Friend.h"
#import "InviteViewController.h"

#define CELL_HEIGHT 40.0

@interface InviteViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (retain, nonatomic) UISearchBar *searchBar;
@property (retain, nonatomic) NSMutableArray *friendSearchResultsArray;
@property (nonatomic, strong) UITableView *friendSearchResultsTableView;
@property (nonatomic, strong) UITableViewController *friendSearchResultsTableViewController;
@property (retain, nonatomic) UIView *friendsInvitedView;
@property (retain, nonatomic) NSMutableArray *friendsInvitedArray;
@property (retain, nonatomic) NSMutableArray *friendsLabelsArray;
@property (retain, nonatomic) UITextView *messageTextView;
@property (retain, nonatomic) UIButton *backButton;
@end

@implementation InviteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.friendsInvitedArray = [[NSMutableArray alloc] init];
        self.friendsLabelsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.friendsInvitedView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
    [self.friendsInvitedView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.friendsInvitedView];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, self.friendsInvitedView.frame.size.height, self.view.frame.size.width, 50)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Type a friends name to search...";
    [self.view addSubview:self.searchBar];
    
    self.messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(10.0, self.searchBar.frame.origin.y + self.searchBar.frame.size.height + 10.0, self.view.frame.size.width - 20.0, 180.0)];
    [self.messageTextView setBackgroundColor:[UIColor grayColor]];
    [self.messageTextView setEditable:YES];
    [self.view addSubview:self.messageTextView];
    
    self.friendSearchResultsArray = [[NSMutableArray alloc] init];
    
    self.friendSearchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.searchBar.frame.origin.y + self.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.searchBar.frame.size.height)];
    [self.friendSearchResultsTableView setDataSource:self];
    [self.friendSearchResultsTableView setDelegate:self];
    [self.friendSearchResultsTableView setHidden:YES];
    [self.view addSubview:self.friendSearchResultsTableView];
    
    self.friendSearchResultsTableViewController = [[UITableViewController alloc] init];
    self.friendSearchResultsTableViewController.tableView = self.friendSearchResultsTableView;
    [self.friendSearchResultsTableView reloadData];
    
    UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(220, 280, 80, 40)];
    [sendButton addTarget:self action:@selector(sendButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [sendButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [sendButton setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:sendButton];
    
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.messageTextView.frame.origin.y + self.messageTextView.frame.size.height, 80, 40)];
    [self.backButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton setTitle:@"back" forState:UIControlStateNormal];
    [self.backButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:self.backButton];
}

-(void)closeView {
    if ([self.delegate respondsToSelector:@selector(closeInviteView)]) {
        [self.delegate closeInviteView];
    }
}

-(IBAction)sendButtonClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    NSMutableArray *friendsInvited = [[NSMutableArray alloc] init];
    for (Friend *f in self.friendsInvitedArray) {
        [friendsInvited addObject:f.friendID];
    }
    
    for (Friend *friend in self.friendsInvitedArray) {
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
    NSLog(@"remove friend at index %ld", (long)button.tag);
    UILabel *label = [self.friendsLabelsArray objectAtIndex:button.tag];
    [label removeFromSuperview];
    [self.friendsInvitedArray removeObjectAtIndex:button.tag];
}

#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:YES animated:YES];
    self.friendSearchResultsTableView.hidden = NO;
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
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    Friend *friend = [self.friendSearchResultsArray objectAtIndex:indexPath.row];
    nameLabel.text = friend.name;
    [cell addSubview:nameLabel];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Friend *friend = [self.friendSearchResultsArray objectAtIndex:indexPath.row];
    UILabel *friendLabel = [[UILabel alloc] init];
    if ([self.friendsLabelsArray count] > 0) {
        int index = [self.friendsLabelsArray count] - 1;
        UILabel *previousLabel = [self.friendsLabelsArray objectAtIndex:index];
        CGRect previousLabelFrame = previousLabel.frame;
        friendLabel.frame = CGRectMake(previousLabelFrame.origin.x + previousLabelFrame.size.width, 20.0, 100, 40.0);
    } else {
        friendLabel.frame = CGRectMake(0.0, 20.0, 100.0, 40.0);
    }
    friendLabel.userInteractionEnabled = YES;
    UIButton *xButton = [[UIButton alloc] initWithFrame:CGRectMake(80, 0, 20, 20)];
    xButton.tag = indexPath.row;
    [xButton setTitle:@"X" forState:UIControlStateNormal];
    [xButton addTarget:self action:@selector(removeFriend:) forControlEvents:UIControlEventTouchUpInside];
    [friendLabel addSubview:xButton];
    friendLabel.text = friend.name;
    [friendLabel setBackgroundColor:[UIColor grayColor]];
    [self.friendsInvitedArray addObject:friend];
    [self.friendsLabelsArray addObject:friendLabel];
    [self.friendsInvitedView addSubview:friendLabel];
    
    self.searchBar.text = @"";
    self.friendSearchResultsArray = nil;
    [self.friendSearchResultsTableView reloadData];
    [self.friendSearchResultsTableView setHidden:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
