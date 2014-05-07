//
//  NewMessageViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-04-30.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#define BOTTOM_BAR_HEIGHT 50.0
#define MAX_LABEL_WIDTH 150.0
#define MAX_MESSAGE_FIELD_HEIGHT 150.0
#define MESSAGE_FIELD_HEIGHT 28.0
#define MESSAGE_FIELD_WIDTH 229.0
#define MIN_CELL_HEIGHT 40.0
#define PADDING 15.0
#define SEARCH_RESULTS_CELL_HEIGHT 60.0
#define SEND_BUTTON_WIDTH 48.0
#define SLIDE_TIMING 0.6
#define STATUS_BAR_HEIGHT 20.0
#define SUB_BAR_HEIGHT 60.0
#define TOP_BAR_HEIGHT 70.0

#import "CenterViewController.h"
#import "Datastore.h"
#import "Flurry.h"
#import "FriendAtPlaceCell.h"
#import "Message.h"
#import "MessageCell.h"
#import "NewMessageViewController.h"
#import "SelectInviteLocationViewController.h"

@interface NewMessageViewController () <SelectInviteLocationViewControllerDelegate, UIGestureRecognizerDelegate, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UILabel * titleLabel;
@property (retain, nonatomic) UIView * bottomBar;
@property (retain, nonatomic) UIView * bottomBarBorder;
@property (retain, nonatomic) UIButton *sendButton;
@property (retain, nonatomic) UITextView * textView;
@property (retain, nonatomic) UIView * subBar;
@property (retain, nonatomic) UIView * subBarBorder;
@property (retain, nonatomic) UILabel * toLabel;
@property (retain, nonatomic) UITextView * searchFriendsTextView;
@property (retain, nonatomic) UITableView * searchResultsTableView;
@property (retain, nonatomic) UITableViewController * searchResultsTableViewController;
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (retain, nonatomic) NSMutableSet *friendsInvitedSet;
@property (retain, nonatomic) NSMutableSet *friendsInvitedIdSet;
@property (assign, nonatomic) NSRange searchRange;
@property (assign, nonatomic) BOOL deletingFriend;
@property (nonatomic, assign) BOOL keyboardShowing;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) NSNotification * notification;
@property (nonatomic, strong) UITableView *messagesTableView;
@property (nonatomic, strong) UITableViewController *messagesTableViewController;
@property (retain, nonatomic) UIButton *inviteButton;
@property (retain, nonatomic) UIImageView *inviteImageView;
@property (nonatomic, strong) SelectInviteLocationViewController *selectInviteViewController;

@end

@implementation NewMessageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.friendsInvitedSet = [[NSMutableSet alloc] init];
        self.friendsInvitedIdSet = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // top bar setup
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, self.view.frame.size.width,TOP_BAR_HEIGHT)];
    self.topBar.layer.backgroundColor = UIColorFromRGB(0x8e0528).CGColor;
    [self.view addSubview:self.topBar];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBack:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.topBar addGestureRecognizer:panRecognizer];
    
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, (TOP_BAR_HEIGHT - 31.0 + STATUS_BAR_HEIGHT) / 2.0, 32.0, 31.0)];
    [self.backButton setImageEdgeInsets:UIEdgeInsetsMake(10.0, 5.0, 10.0, 20.0)];
    [self.backButton setImage:triangleImage forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(closeNewMessageView:) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.backButton];
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.titleLabel = [[UILabel alloc] init];
    [self.titleLabel setTextColor:[UIColor whiteColor]];
    self.titleLabel.font = montserrat;
    [self.titleLabel setText:@"New Message"];
    CGSize size = [self.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.titleLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, (TOP_BAR_HEIGHT - size.height + STATUS_BAR_HEIGHT) / 2.0, size.width, size.height);
    [self.topBar addSubview:self.titleLabel];
    
    // top bar setup
    self.subBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width,SUB_BAR_HEIGHT)];
    self.subBar.layer.backgroundColor = UIColorFromRGB(0xf8f8f8).CGColor;
    [self.view addSubview:self.subBar];
    
    self.subBarBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0, SUB_BAR_HEIGHT - 1.0, self.view.frame.size.width, 1.0)];
    [self.subBarBorder setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.subBar addSubview:self.subBarBorder];
    
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:16.0f];
    self.toLabel = [[UILabel alloc] init];
    self.toLabel.text = @"To:";
    [self.toLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
    self.toLabel.font = montserratLarge;
    size = [self.toLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLarge}];
    self.toLabel.frame = CGRectMake(10.0, 8.0, size.width, size.height);
    [self.subBar addSubview:self.toLabel];
    
    self.messagesArray = [[NSMutableArray alloc] init];
    
    self.messagesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT)];
    [self.messagesTableView setDataSource:self];
    [self.messagesTableView setDelegate:self];
    [self.messagesTableView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.messagesTableView];
    self.messagesTableView.showsVerticalScrollIndicator = NO;
    [self.messagesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.messagesTableView setHidden:YES];
    
    self.messagesTableViewController = [[UITableViewController alloc] init];
    self.messagesTableViewController.tableView = self.messagesTableView;
    
    self.searchFriendsTextView = [[UITextView alloc] initWithFrame:CGRectMake(self.toLabel.frame.origin.x + self.toLabel.frame.size.width, 0.0, self.view.frame.size.width - self.toLabel.frame.origin.x - self.toLabel.frame.size.width, self.subBar.frame.size.height)];
    self.searchFriendsTextView.delegate = self;
    [self.searchFriendsTextView setBackgroundColor:[UIColor clearColor]];
    [self.searchFriendsTextView setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.searchFriendsTextView setFont:montserratLarge];
    [self.subBar addSubview:self.searchFriendsTextView];
    [self.searchFriendsTextView becomeFirstResponder];
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT + SUB_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT - SUB_BAR_HEIGHT - BOTTOM_BAR_HEIGHT)];
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    [self.searchResultsTableView setHidden:YES];
    [self.view addSubview:self.searchResultsTableView];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    [self.searchResultsTableView reloadData];
    
    // bottom bar setup
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width,BOTTOM_BAR_HEIGHT)];
    self.bottomBar.layer.backgroundColor = UIColorFromRGB(0xf8f8f8).CGColor;
    [self.view addSubview:self.bottomBar];
    
    self.bottomBarBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 0.5)];
    [self.bottomBarBorder setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.bottomBar addSubview:self.bottomBarBorder];
    
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - SEND_BUTTON_WIDTH, 0.0, SEND_BUTTON_WIDTH, self.bottomBar.frame.size.height)];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.sendButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = montserrat;
    [self.sendButton addTarget:self action:@selector(sendClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setEnabled:NO];
    [self.bottomBar addSubview:self.sendButton];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake((self.bottomBar.frame.size.width - MESSAGE_FIELD_WIDTH) / 2.0,(self.bottomBar.frame.size.height - MESSAGE_FIELD_HEIGHT) / 2.0, MESSAGE_FIELD_WIDTH, MESSAGE_FIELD_HEIGHT)];
    self.textView.delegate = self;
    [[self.textView layer] setBorderColor:UIColorFromRGB(0xc8c8c8).CGColor];
    [[self.textView layer] setBorderWidth:0.5];
    [[self.textView layer] setCornerRadius:4.0];
    self.textView.font = montserrat;
    self.textView.textColor = UIColorFromRGB(0xc8c8c8);
    self.textView.text = @"Type a message...";
    [self.textView setScrollEnabled:NO];
    [self.bottomBar addSubview:self.textView];
    
    UISwipeGestureRecognizer * swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
    [swipeDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.bottomBar addGestureRecognizer:swipeDown];
    
    UISwipeGestureRecognizer * swipeDownTextView = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
    [swipeDownTextView setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.textView addGestureRecognizer:swipeDownTextView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    self.inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, self.textView.frame.origin.x, BOTTOM_BAR_HEIGHT)];
    [self.inviteButton addTarget:self action:@selector(inviteClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.inviteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0, 5.0, 21, 38)];
    [self.inviteImageView setImage:[UIImage imageNamed:@"PinIcon"]];
    [self.inviteButton addSubview:self.inviteImageView];
    [self.inviteButton setEnabled:NO];
    [self.bottomBar addSubview:self.inviteButton];
    
    self.keyboardHeight = 0.0;
}

-(void)searchFriends:(NSString*)searchText {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.searchResults = [[NSMutableArray alloc] init];
    
    if ([searchText isEqualToString:@""]) {
        for(id key in sharedDataManager.tetherFriendsDictionary) {
            [self.searchResults addObject:[sharedDataManager.tetherFriendsDictionary objectForKey:key]];
        }
    } else {
        searchText = [searchText lowercaseString];
        for(id key in sharedDataManager.tetherFriendsDictionary) {
            Friend *friend = [sharedDataManager.tetherFriendsDictionary objectForKey:key];
            if (!friend.blocked && ![friend.friendID isEqualToString:sharedDataManager.facebookId] && ![self.friendsInvitedSet containsObject:friend]) {
                NSString *name = [friend.name lowercaseString];
                if ([name rangeOfString:searchText].location != NSNotFound) {
                    [self.searchResults addObject:friend];
                }
            }
        }
    }
    [self.searchResultsTableView reloadData];
}

-(void)adjustSubBar {
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    NSDictionary *attributes = @{NSFontAttributeName: montserrat};
    CGRect rect = [self.searchFriendsTextView.text boundingRectWithSize:CGSizeMake(self.searchFriendsTextView.frame.size.width, 1000.0)
                                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                             attributes:attributes
                                                                context:nil];
    self.subBar.frame = CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, MAX(SUB_BAR_HEIGHT, rect.size.height + 20.0));
    CGRect frame = self.searchFriendsTextView.frame;
    frame.size.height = rect.size.height + 40.0;
    frame.origin.y = 0.0;
    self.searchFriendsTextView.frame = frame;
    
    frame = self.subBarBorder.frame;
    frame.origin.y = self.subBar.frame.size.height - 1.0;
    self.subBarBorder.frame = frame;
    
    frame = self.searchResultsTableView.frame;
    frame.origin.y = self.subBar.frame.origin.y + self.subBar.frame.size.height;
    self.searchResultsTableView.frame = frame;
}

#pragma mark IBAction

-(IBAction)inviteClicked:(id)sender {
    if (!self.selectInviteViewController) {
        self.selectInviteViewController = [[SelectInviteLocationViewController alloc] init];
        self.selectInviteViewController.delegate = self;
        
        [self addChildViewController:self.selectInviteViewController];
        [self.selectInviteViewController didMoveToParentViewController:self];
        [self.selectInviteViewController.view setFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:self.selectInviteViewController.view];
        
        [UIView animateWithDuration:SLIDE_TIMING*1.2
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.selectInviteViewController.view setFrame:CGRectMake( 0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                             [Flurry logEvent:@"User_Views_Select_Location_Invite_Page_New_Message"];
                         }];
    }
}

-(IBAction)closeNewMessageView:(id)sender {
    [self closeView];
}

-(void)closeView {
    if ([self.delegate respondsToSelector:@selector(closeNewMessageView)]) {
        [self.delegate closeNewMessageView];
    }
}

-(IBAction)sendClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (!self.thread) {
        NSMutableSet *set = [self.friendsInvitedIdSet mutableCopy];
        [set addObject:sharedDataManager.facebookId];
        
        for (id key in sharedDataManager.messageThreadDictionary) {
            MessageThread *thread = [sharedDataManager.messageThreadDictionary objectForKey:key];
            if ([thread.participantIds isEqualToSet:set]) {
                self.thread = thread;
                break;
            }
        }
        
        if (!self.thread) {
            [self startNewConversationWithMessage:self.textView.text orInviteObject:nil];
            self.textView.text = @"";
            
            [self textViewDidChange:self.textView];
        } else {
            Message *newMessage = [[Message alloc] init];
            newMessage.content = self.textView.text;
            newMessage.date = [NSDate date];
            newMessage.userId = sharedDataManager.facebookId;
            newMessage.userName = sharedDataManager.name;
            newMessage.threadId = self.thread.threadId;
            
            [self.messagesArray addObject:newMessage];
            [self.messagesTableView reloadData];
            
            [self sendMessage:newMessage withInvite:nil];
            
            self.textView.text = @"";
            
            NSIndexPath* ipath = [NSIndexPath indexPathForRow: [self.messagesArray count] -1 inSection: 0];
            [self.messagesTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
            
            [self textViewDidChange:self.textView];
            
            [self hideSubBar];
        }
    } else {
        Message *newMessage = [[Message alloc] init];
        newMessage.content = self.textView.text;
        newMessage.date = [NSDate date];
        newMessage.userId = sharedDataManager.facebookId;
        newMessage.userName = sharedDataManager.name;
        newMessage.threadId = self.thread.threadId;
        
        [self.messagesArray addObject:newMessage];
        [self.messagesTableView reloadData];
        
        [self sendMessage:newMessage withInvite:nil];
        
        self.textView.text = @"";
        
        NSIndexPath* ipath = [NSIndexPath indexPathForRow: [self.messagesArray count] -1 inSection: 0];
        [self.messagesTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
        
        [self textViewDidChange:self.textView];
    }
}

-(void)sendMessage:(Message*)message withInvite:(PFObject*)inviteObject{
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    // create message object associated with the thread object
    PFObject *messageObject = [PFObject objectWithClassName:@"Message"];
    if (inviteObject) {
        [messageObject setObject:[NSString stringWithFormat:@"%@ invited you to %@", sharedDataManager.name, [inviteObject objectForKey:@"placeName"]] forKey:@"message"];
    } else {
        [messageObject setObject:message.content forKey:@"message"];
    }
    [messageObject setObject:message.userId forKey:@"facebookId"];
    [messageObject setObject:message.userName forKey:@"name"];
    [messageObject setObject:self.thread.threadObject forKey:@"threadId"];
    if (inviteObject) {
        [messageObject setObject:inviteObject forKey:@"invite"];
    }
    
    [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                PFQuery *friendQuery = [PFUser query];
                NSMutableArray *recipientsArray = [[self.thread.participantIds allObjects] mutableCopy];
                [recipientsArray removeObject:sharedDataManager.facebookId];
                [friendQuery whereKey:@"facebookId" containedIn:recipientsArray];
                
                [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (!error) {
                        // Create our Installation query
                        PFUser * user = [objects objectAtIndex:0];
                        PFQuery *pushQuery = [PFInstallation query];
                        [pushQuery whereKey:@"owner" equalTo:user]; //change this to use friends installation
                        NSString *messageHeader = [NSString stringWithFormat:@"%@: %@", sharedDataManager.name, message.content];
                        NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                              messageHeader, @"alert",
                                              @"Increment", @"badge",
                                              nil];
                        
                        // Send push notification to query
                        PFPush *push = [[PFPush alloc] init];
                        [push setQuery:pushQuery]; // Set our Installation query
                        [push setData:data];
                        [push sendPushInBackground];
                    }
                }];
    }];
    
    PFQuery *participantQuery = [PFQuery queryWithClassName:@"MessageParticipant"];
    [participantQuery whereKey:@"facebookId" containedIn:[self.thread.participantIds allObjects]];
    [participantQuery whereKey:@"facebookId" notEqualTo:sharedDataManager.facebookId];
    [participantQuery whereKey:@"threadId" equalTo:self.thread.threadObject];
    [participantQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        for (PFObject *participantObject in objects) {
            [participantObject setObject:[NSNumber numberWithBool:YES] forKey:@"unread"];
            [participantObject saveInBackground];
        }
    }];
    
    // update recent message value of thread
    [self.thread.threadObject setObject:message.content forKey:@"recentMessage"];
    [self.thread.threadObject saveEventually];
    
    self.bottomBar.frame = CGRectMake(0.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width,BOTTOM_BAR_HEIGHT);
    self.bottomBarBorder.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 0.5);
    
    CGRect frame = self.bottomBar.frame;
    frame.origin.y = self.view.frame.size.height - self.keyboardHeight - frame.size.height;
    self.bottomBar.frame = frame;
    
    self.textView.frame = CGRectMake((self.bottomBar.frame.size.width - MESSAGE_FIELD_WIDTH) / 2.0,(self.bottomBar.frame.size.height - MESSAGE_FIELD_HEIGHT) / 2.0, MESSAGE_FIELD_WIDTH, MESSAGE_FIELD_HEIGHT);
    [self.textView setScrollEnabled:NO];
}

-(void)pushToFriendsWithMessageContent:(NSString*)content {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    PFQuery *friendQuery = [PFUser query];
    NSMutableArray *recipientsArray = [[self.friendsInvitedSet allObjects] mutableCopy];
    [friendQuery whereKey:@"facebookId" containedIn:recipientsArray];
    
    [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // Create our Installation query
            PFUser * user = [objects objectAtIndex:0];
            PFQuery *pushQuery = [PFInstallation query];
            [pushQuery whereKey:@"owner" equalTo:user]; //change this to use friends installation
            NSString *messageHeader = [NSString stringWithFormat:@"%@: %@", sharedDataManager.name, content];
            NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                  messageHeader, @"alert",
                                  @"Increment", @"badge",
                                  nil];
            
            // Send push notification to query
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:pushQuery]; // Set our Installation query
            [push setData:data];
            [push sendPushInBackground];
        }
    }];
}

-(void)startNewConversationWithMessage:(NSString*)content orInviteObject:(PFObject*)inviteObject{
    // check if exisiting message thread with same participants
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    PFObject *threadObject = [PFObject objectWithClassName:@"MessageThread"];
    [threadObject setObject:content forKey:@"recentMessage"];
    
    NSArray *friendsInvitedArray = [self.friendsInvitedSet allObjects];
    NSMutableArray *friendNamesArray = [[NSMutableArray alloc] initWithCapacity:[friendsInvitedArray count] + 1];
    NSMutableArray *friendFirstNamesArray = [[NSMutableArray alloc] initWithCapacity:[friendsInvitedArray count] + 1];
    NSMutableArray *friendIdsArray = [[NSMutableArray alloc] initWithCapacity:[friendsInvitedArray count] + 1];
    [friendNamesArray addObject:sharedDataManager.name];
    [friendFirstNamesArray addObject:sharedDataManager.firstName];
    [friendIdsArray addObject:sharedDataManager.facebookId];
    
    for (Friend *friend in friendsInvitedArray) {
        [friendNamesArray addObject:friend.name];
        [friendFirstNamesArray addObject:friend.firstName];
        [friendIdsArray addObject:friend.friendID];
    }
    
    [threadObject setObject:friendNamesArray forKey:@"participantNames"];
    [threadObject setObject:friendFirstNamesArray forKey:@"participantFirstNames"];
    [threadObject setObject:friendIdsArray forKey:@"participantIds"];
    
    [threadObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        self.messageThreadObject = threadObject;
        
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        Message *newMessage = [[Message alloc] init];
        if (inviteObject) {
            newMessage.content = [NSString stringWithFormat:@"You sent an invite to %@", [inviteObject objectForKey:@"placeName"]];
        } else {
            newMessage.content = content;
        }
        newMessage.date = [NSDate date];
        newMessage.userId = sharedDataManager.facebookId;
        newMessage.userName = sharedDataManager.name;
        newMessage.threadId = self.thread.threadId;
        
        MessageThread *thread = [[MessageThread alloc] init];
        thread.threadId = threadObject.objectId;
        thread.threadObject = threadObject;
        thread.recentMessageDate = threadObject.updatedAt;
        thread.recentMessage = [threadObject objectForKey:@"recentMessage"];
        if (sharedDataManager.name) {
            if ([thread.recentMessage rangeOfString:sharedDataManager.name].location != NSNotFound) {
                thread.recentMessage = [thread.recentMessage stringByReplacingOccurrencesOfString:sharedDataManager.name withString:@"You"];
                
            }
        }
        
        thread.participantIds = [NSMutableSet setWithArray:[threadObject objectForKey:@"participantIds"]];
        thread.participantNames = [NSMutableSet setWithArray:[threadObject objectForKey:@"participantNames"]];
        if ([thread.participantIds count] > 2) {
            thread.isGroupMessage = YES;
            thread.participantNames = [NSMutableSet setWithArray:[threadObject objectForKey:@"participantFirstNames"]];
        } else {
            thread.isGroupMessage = NO;
        }

        thread.messages = [[NSMutableDictionary alloc] init];
        self.thread = thread;
        
        [self.messagesArray addObject:newMessage];
        [self.messagesTableView reloadData];
        [self.messagesTableView setHidden:NO];
        
        PFObject *myParticipantObject = [PFObject objectWithClassName:@"MessageParticipant"];
        [myParticipantObject setObject:threadObject forKey:@"threadId"];
        [myParticipantObject setObject:sharedDataManager.facebookId forKey:@"facebookId"];
        [myParticipantObject setObject:sharedDataManager.name forKey:@"name"];
        [myParticipantObject setObject:sharedDataManager.firstName forKey:@"firstName"];
        [myParticipantObject setObject:[NSNumber numberWithBool:NO] forKey:@"unread"];
        [myParticipantObject saveInBackground];
        
        for (Friend *friend in friendsInvitedArray) {
            PFObject *participantObject = [PFObject objectWithClassName:@"MessageParticipant"];
            [participantObject setObject:threadObject forKey:@"threadId"];
            [participantObject setObject:friend.friendID forKey:@"facebookId"];
            [participantObject setObject:friend.name forKey:@"name"];
            [participantObject setObject:friend.firstName forKey:@"firstName"];
            [participantObject setObject:[NSNumber numberWithBool:YES] forKey:@"unread"];
            [participantObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            }];
        }
        
        PFObject * messageObject = [PFObject objectWithClassName:@"Message"];
        [messageObject setObject:threadObject forKey:@"threadId"];
        [messageObject setObject:sharedDataManager.facebookId forKey:@"facebookId"];
        if (inviteObject) {
            [messageObject setObject:inviteObject forKey:@"invite"];
        }
        [messageObject setObject:sharedDataManager.name forKey:@"name"];
        [messageObject setObject:content forKey:@"message"];
        [messageObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            PFQuery *friendQuery = [PFUser query];
            NSMutableArray *recipientsArray = [[self.thread.participantIds allObjects] mutableCopy];
            [recipientsArray removeObject:sharedDataManager.facebookId];
            [friendQuery whereKey:@"facebookId" containedIn:recipientsArray];
            
            [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    // Create our Installation query
                    PFUser * user = [objects objectAtIndex:0];
                    PFQuery *pushQuery = [PFInstallation query];
                    [pushQuery whereKey:@"owner" equalTo:user]; //change this to use friends installation
                    NSString *messageHeader = [NSString stringWithFormat:@"%@: %@", sharedDataManager.name, content];
                    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                          messageHeader, @"alert",
                                          @"Increment", @"badge",
                                          nil];
                    
                    // Send push notification to query
                    PFPush *push = [[PFPush alloc] init];
                    [push setQuery:pushQuery]; // Set our Installation query
                    [push setData:data];
                    [push sendPushInBackground];
                }
            }];
        }];
        
        NSString *names = @"";
        for (NSString *friendName in friendFirstNamesArray) {
            if (![friendName isEqualToString:sharedDataManager.name] && ![friendName isEqualToString:sharedDataManager.firstName]) {
                if ([names isEqualToString:@""]) {
                    names = friendName;
                } else {
                    names = [NSString stringWithFormat:@"%@, %@", names,friendName];
                }
            }
        }
        
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
        [self.titleLabel setText:names];
        CGSize size = [self.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
        self.titleLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, (TOP_BAR_HEIGHT - size.height + STATUS_BAR_HEIGHT) / 2.0, size.width, size.height);
    }];
}

-(void)removeFriendFromSet:(NSString*)name {
    NSLog(@"Deleting name:%@",name);
    NSArray *tempParticipantsArray = [self.friendsInvitedSet allObjects];
    for (Friend *friend in tempParticipantsArray) {
        if ([friend.name isEqualToString:name]) {
            [self.friendsInvitedSet removeObject:friend];
            [self.friendsInvitedIdSet removeObject:friend.friendID];
            NSLog(@"DELETED FRIEND:%@", name);
        }
    }
    if ([self.friendsInvitedSet count] == 0) {
        [self.inviteButton setEnabled:NO];
        [self.sendButton setEnabled:NO];
    }
}

-(void)loadMessages {
    if (self.thread) {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        PFQuery *query = [PFQuery queryWithClassName:@"Message"];
        [query whereKey:@"threadId" equalTo:self.thread.threadObject];
        [query findObjectsInBackgroundWithBlock:^(NSArray *messages, NSError *error) {
            if (!error) {
                NSMutableDictionary *tempMessageDictionary = [[NSMutableDictionary alloc] init];
                for (PFObject *messageObject in messages) {
                    Message *message = [[Message alloc] init];
                    message.messageId = messageObject.objectId;
                    message.userId = [messageObject objectForKey:@"facebookId"];
                    message.userName = [messageObject objectForKey:@"name"];
                    message.content = [messageObject objectForKey:@"message"];
                    message.date = messageObject.updatedAt;
                    
                    [tempMessageDictionary setObject:message forKey:message.messageId];
                }
                
                if (![tempMessageDictionary isEqualToDictionary:self.thread.messages]) {
                    self.thread.messages = tempMessageDictionary;
                    self.messagesArray = [[NSMutableArray alloc] init];
                    
                    for (id key in self.thread.messages) {
                        Message *message = [self.thread.messages objectForKey:key];
                        [self.messagesArray addObject:message];
                    }
                    
                    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
                    [self.messagesArray sortUsingDescriptors:[NSArray arrayWithObjects:dateDescriptor, nil]];
                    
                    [self.messagesTableView reloadData];
                    
                    [sharedDataManager.messageThreadDictionary setObject:self.thread forKey:self.thread.threadId];
                }        }
        }];
    }
}


-(void)hideSubBar {
    NSArray *friendsInvitedArray = [self.friendsInvitedSet allObjects];
    NSMutableArray *friendNamesArray = [[NSMutableArray alloc] initWithCapacity:[friendsInvitedArray count]];
    if ([self.friendsInvitedSet count] > 1) {
        for (Friend *friend in friendsInvitedArray) {
            [friendNamesArray addObject:friend.firstName];
        }
    } else {
        for (Friend *friend in friendsInvitedArray) {
            [friendNamesArray addObject:friend.name];
        }
    }
    
    NSString *names = @"";
    for (NSString *friendName in friendNamesArray) {
        if ([names isEqualToString:@""]) {
            names = friendName;
        } else {
            names = [NSString stringWithFormat:@"%@, %@", names,friendName];
        }
    }
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    [self.titleLabel setText:names];
    CGSize size = [self.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.titleLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, (TOP_BAR_HEIGHT - size.height + STATUS_BAR_HEIGHT) / 2.0, size.width, size.height);
    [self.subBar setHidden:YES];
    
    [self.messagesTableView setHidden:NO];
}


#pragma mark SelectInviteViewControllerDelegate

-(void)inviteToPlace:(Place*) place {
    if (self.thread) {
        [self sendInviteToPlace:place];
    } else {
        Datastore *sharedDataManager = [Datastore sharedDataManager];
        NSMutableSet *set = [self.friendsInvitedIdSet mutableCopy];
        [set addObject:sharedDataManager.facebookId];
        
        for (id key in sharedDataManager.messageThreadDictionary) {
            MessageThread *thread = [sharedDataManager.messageThreadDictionary objectForKey:key];
            if ([thread.participantIds isEqualToSet:set]) {
                self.thread = thread;
                break;
            }
        }
        
        if (self.thread) {
            [self sendInviteToPlace:place];
            
            [self hideSubBar];
        } else {
            // create message object associated with the thread object
            PFObject *inviteObject = [PFObject objectWithClassName:@"Invite"];
            [inviteObject setObject:place.name forKey:@"placeName"];
            [inviteObject setObject:place.placeId forKey:@"placeId"];
            [inviteObject setObject:place.city forKey:@"city"];
            [inviteObject setObject:place.state forKey:@"state"];
            
            [self startNewConversationWithMessage:[NSString stringWithFormat:@"%@ invited you to %@", sharedDataManager.name, place.name] orInviteObject:inviteObject];
        }
    }
}

-(void)sendInviteToPlace:(Place*)place {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    Message *newMessage = [[Message alloc] init];
    newMessage.content = [NSString stringWithFormat:@"You sent an invite to %@", place.name];
    newMessage.date = [NSDate date];
    newMessage.userId = sharedDataManager.facebookId;
    newMessage.userName = sharedDataManager.name;
    newMessage.threadId = self.thread.threadId;
    
    // create message object associated with the thread object
    PFObject *inviteObject = [PFObject objectWithClassName:@"Invite"];
    [inviteObject setObject:place.name forKey:@"placeName"];
    [inviteObject setObject:place.placeId forKey:@"placeId"];
    [inviteObject setObject:place.city forKey:@"city"];
    [inviteObject setObject:place.state forKey:@"state"];
    
    Invite *invite = [[Invite alloc] init];
    invite.place = place;
    newMessage.invite = invite;
    
    if (place.country) {
        [inviteObject setObject:place.country forKey:@"country"];
    }
    
    if (place.memo) {
        [inviteObject setObject:place.memo forKey:@"memo"];
    }
    
    if (place.address) {
        [inviteObject setObject:place.address forKey:@"address"];
    }
    
    if (place.isPrivate) {
        [inviteObject setObject:[NSNumber numberWithBool:place.isPrivate] forKey:@"private"];
    }
    
    [inviteObject setObject:[PFGeoPoint geoPointWithLatitude:place.coord.latitude
                                                   longitude:place.coord.longitude] forKey:@"coordinate"];
    
    [inviteObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [self sendMessage:newMessage withInvite:inviteObject];
        newMessage.invite.inviteObject = inviteObject;
        
        [self.messagesArray addObject:newMessage];
        [self.messagesTableView reloadData];
        
        NSIndexPath* ipath = [NSIndexPath indexPathForRow: MAX(0, [self.messagesArray count] -1) inSection: 0];
        [self.messagesTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
    }];
}

-(void)closeSelectInviteLocationView {
    [self.textView becomeFirstResponder];
    [UIView animateWithDuration:SLIDE_TIMING*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.selectInviteViewController.view setFrame:CGRectMake(0.0f, self.view.frame.size.height + 40.0, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.selectInviteViewController.view removeFromSuperview];
                         [self.selectInviteViewController removeFromParentViewController];
                         self.selectInviteViewController = nil;
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

#pragma mark UITextViewDelegate

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    if ([textView isEqual:self.textView]) {
        if (self.textView.tag == 0) {
            self.textView.text = @"";
            self.textView.textColor = [UIColor blackColor];
            self.textView.tag = 1;
        }
    }
    
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView {
    if ([textView isEqual:self.searchFriendsTextView]) {
        NSString *string = textView.text;
        if ([string rangeOfString:@","].location == NSNotFound) {
            if (string.length == 0) {
                [self.searchResultsTableView setHidden:YES];
                [self.searchResults removeAllObjects];
                [self.searchResultsTableView reloadData];
            } else {
                [self searchFriends:textView.text];
                NSRange searchRange;
                searchRange.location = 0;
                searchRange.length = string.length;
                self.searchRange = searchRange;
                [self.searchResultsTableView setHidden:NO];
            }
        } else {
            NSRange range = NSMakeRange(0, string.length);
            NSRange previousRange;
            while(range.location != NSNotFound)
            {
                previousRange = range;
                range = [string rangeOfString:@"," options:0 range:range];
                if(range.location != NSNotFound) {
                    range = NSMakeRange(range.location + range.length, string.length - (range.location + range.length));
                }
            }
            
            NSRange searchRange;
            if (previousRange.location < string.length - 1) {
                searchRange.location = previousRange.location + 1;
                searchRange.length = string.length - previousRange.location - 1;
                self.searchRange = searchRange;
                NSString *substring = [string substringWithRange:searchRange];
                [self searchFriends:substring];
                if ([substring isEqualToString:@""] || [substring isEqualToString:@" "]) {
                    [self.searchResultsTableView setHidden:YES];
                    [self.searchResults removeAllObjects];
                    [self.searchResultsTableView reloadData];
                } else {
                    [self.searchResultsTableView setHidden:NO];
                }
            }
        }
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
        [self.searchFriendsTextView setFont:montserrat];
        [self adjustSubBar];
    } else {
        if(self.textView.text.length == 0){
            self.textView.tag = 0;
        } else {
            UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
            
            NSDictionary *attributes = @{NSFontAttributeName: montserrat};
            CGRect rect = [self.textView.text boundingRectWithSize:CGSizeMake(MESSAGE_FIELD_WIDTH, 200.0)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:attributes
                                                           context:nil];
            
            // resize textview
            CGRect frame = self.textView.frame;
            frame.size.height = MAX(MESSAGE_FIELD_HEIGHT, MIN(rect.size.height + 10.0, MAX_MESSAGE_FIELD_HEIGHT));
            self.textView.frame = frame;
            if (rect.size.height < MAX_MESSAGE_FIELD_HEIGHT) {
                [self.textView setScrollEnabled:NO];
            } else {
                [self.textView setScrollEnabled:YES];
            }
            
            // resize bottom bar
            frame = self.bottomBar.frame;
            frame.size.height = self.textView.frame.size.height + 22.0;
            if (self.keyboardShowing) {
                CGSize keyboardSize = [[[self.notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
                frame.origin.y = self.view.frame.size.height - keyboardSize.height - frame.size.height;
            } else {
                frame.origin.y = self.view.frame.size.height - frame.size.height;
            }
            self.bottomBar.frame = frame;
            
            [self.sendButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
            [self.sendButton setEnabled:YES];
        }
    }
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([textView isEqual:self.searchFriendsTextView]) {
        NSString *substring = [textView.text substringWithRange:range];
        if (range.length == 1 && [substring isEqualToString:@","]) {
            self.deletingFriend = YES;
            [self.searchResultsTableView setHidden:YES];
            [self.searchResults removeAllObjects];
            [self.searchResultsTableView reloadData];
            
            NSLog(@"Deleting friend");
        } else if (self.deletingFriend) {
            NSString *string = textView.text;
            NSRange tempRange = NSMakeRange(0, string.length);
            NSRange previousRange;
            while(tempRange.location != NSNotFound && tempRange.location < range.location)
            {
                previousRange = tempRange;
                tempRange = [string rangeOfString:@"," options:0 range:tempRange];
                if(tempRange.location != NSNotFound) {
                    tempRange = NSMakeRange(tempRange.location + tempRange.length, string.length - (tempRange.location + tempRange.length));
                }
            }
            // remove friend
            NSRange deletingRange;
            if (previousRange.location < string.length - 1 || previousRange.location == 0) {
                NSString *deletedName;
                if (previousRange.location == 0) {
                    deletingRange.location = previousRange.location;
                    deletingRange.length = string.length;
                    deletedName = [string substringWithRange:deletingRange];
                    string = [string stringByReplacingCharactersInRange:deletingRange withString:@""];
                } else {
                    deletingRange.location = previousRange.location + 1;
                    deletingRange.length = string.length - previousRange.location - 1;
                    deletedName = [string substringWithRange:deletingRange];
                    string = [string stringByReplacingCharactersInRange:deletingRange withString:@" "];
                }
                [self removeFriendFromSet:deletedName];
                textView.text = string;
            }
            
            [self.searchResultsTableView setHidden:YES];
            [self.searchResults removeAllObjects];
            [self.searchResultsTableView reloadData];
            
            self.deletingFriend = NO;
        } else {
            NSRange previous = range;
            if (previous.location != 0) {
                previous.location = MAX(0, previous.location - 1);
            }
            NSString *substringPrevious = [textView.text substringWithRange:previous];
            if ((range.length == 1 && [substring isEqualToString:@" "]) || [substringPrevious isEqualToString:@" "]){
                [self.searchResultsTableView setHidden:YES];
                [self.searchResults removeAllObjects];
                [self.searchResultsTableView reloadData];
                NSRange tempRange = self.searchRange;
                tempRange.length = tempRange.length - 1;
                
                if (tempRange.location != 0) {
                    tempRange.location = MAX(0, tempRange.location - 1);
                }
                self.searchRange = tempRange;
            }
        }
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
        [self.searchFriendsTextView setFont:montserrat];
    } else {
        if([text isEqualToString:@"\n"]) {
            [textView resignFirstResponder];
            if(self.textView.text.length == 0){
                self.textView.textColor = UIColorFromRGB(0xc8c8c8);
                self.textView.text = @"Type a message...";
                [self.textView resignFirstResponder];
                self.textView.tag = 0;
            }
            return NO;
        }
    }
    return YES;
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
}

- (void)formatTextInTextView:(UITextView *)textView
{
    textView.scrollEnabled = NO;
    NSRange selectedRange = textView.selectedRange;
    NSString *text = textView.text;
    
    // This will give me an attributedString with the base text-style
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(\\w+)" options:0 error:&error];
    NSArray *matches = [regex matchesInString:text
                                      options:0
                                        range:NSMakeRange(0, text.length)];
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match rangeAtIndex:0];
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:UIColorFromRGB(0x8e0528)
                                 range:matchRange];
        [attributedString addAttribute:NSFontAttributeName value:montserrat range:[text rangeOfString:text]];
    }
    
    textView.attributedText = attributedString;
    textView.selectedRange = selectedRange;
    textView.scrollEnabled = YES;
}

#pragma mark keyboard listeners

- (void)keyboardWillShow:(NSNotification *)notification {
    self.notification = notification;
    self.keyboardShowing = YES;
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.keyboardHeight = keyboardSize.height;
    
    CGRect tableFrame = self.messagesTableView.frame;
    tableFrame.size.height = self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT - keyboardSize.height;
    self.messagesTableView.frame = tableFrame;
    
    if (self.thread) {
        NSIndexPath* ipath = [NSIndexPath indexPathForRow: [self.messagesArray count] -1 inSection: 0];
        [self.messagesTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
    }
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         CGRect frame = self.bottomBar.frame;
                         frame.origin.y = self.view.frame.size.height - keyboardSize.height - frame.size.height;
                         self.bottomBar.frame = frame;
                     }];
}

-(void)keyboardWillHide {
    CGRect tableFrame = self.messagesTableView.frame;
    tableFrame.size.height = self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT;
    self.keyboardHeight = 0.0;
    
    self.keyboardShowing = NO;
    [UIView animateWithDuration:0.3
                     animations:^{
                         CGRect frame = self.bottomBar.frame;
                         frame.origin.y = self.view.frame.size.height - frame.size.height;
                         self.bottomBar.frame = frame;
                         self.messagesTableView.frame = tableFrame;
                     }];
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.searchResultsTableView]) {
        return SEARCH_RESULTS_CELL_HEIGHT;
    } else {
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
        Message *message = [self.messagesArray objectAtIndex:indexPath.row];
        
        NSDictionary *attributes = @{NSFontAttributeName: montserrat};
        
        if (!message.userId || [message.userId isEqualToString:@""]) {
            CGRect rect = [message.content boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 20.0, 1000.0)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:attributes
                                                        context:nil];
            return rect.size.height;
        } else {
            CGRect rect = [message.content boundingRectWithSize:CGSizeMake(MAX_LABEL_WIDTH, 1000.0)
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:attributes
                                                        context:nil];
            
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            if (message.invite && ![message.userId isEqualToString:sharedDataManager.facebookId] && ![message.invite.acceptances containsObject:sharedDataManager.facebookId] && ![message.invite.declines containsObject:sharedDataManager.facebookId]) {
                return MAX(MIN_CELL_HEIGHT, rect.size.height + PADDING*3 + 30.0);
            } else {
                return MAX(MIN_CELL_HEIGHT, rect.size.height + PADDING*3);
            }
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([tableView isEqual:self.searchResultsTableView]) {
        return [self.searchResults count];
    } else {
        return [self.messagesArray count];
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.searchResultsTableView]) {
        FriendAtPlaceCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        if (!cell) {
            cell = [[FriendAtPlaceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        }
        [cell setFriend:[self.searchResults objectAtIndex:indexPath.row]];
        return cell;
    } else {
        MessageCell *cell = [[MessageCell alloc] init];
        Message *message = [self.messagesArray objectAtIndex:indexPath.row];
        
        if (self.thread.isGroupMessage) {
            if (indexPath.row == 0) {
                cell.showName = YES;
            } else {
                Message *previousMessage = [self.messagesArray objectAtIndex:indexPath.row - 1];
                if (![message.userId isEqualToString:previousMessage.userId]) {
                    cell.showName = YES;
                }
            }
        }
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setMessage:[self.messagesArray objectAtIndex:indexPath.row]];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath && [self.searchResults count] > 0) {
        Friend *friend = [self.searchResults objectAtIndex:indexPath.row];
        [self.friendsInvitedSet addObject:friend];
        [self.friendsInvitedIdSet addObject:friend.friendID];
        
        NSString *newContent = [self.searchFriendsTextView.text stringByReplacingCharactersInRange:self.searchRange withString:[NSString stringWithFormat:@"%@, " ,friend.name]];
        self.searchFriendsTextView.text = newContent;
        [self.searchResultsTableView setHidden:YES];
        [self formatTextInTextView:self.searchFriendsTextView];
        
        self.searchFriendsTextView.selectedRange = NSMakeRange([self.searchFriendsTextView.text length], 0);
        [self adjustSubBar];
        
        NSRange searchRange = self.searchRange;
        searchRange.location = MAX(0.0,self.searchFriendsTextView.text.length - 1);
        searchRange.length = 0.0;
        self.searchRange = searchRange;
        
        [self.searchResults removeAllObjects];
        [self.searchResultsTableView reloadData];
        
        if (![self.textView.text isEqualToString:@""]) {
            [self.sendButton setEnabled:YES];
        }
        
        [self.inviteButton setEnabled:YES];
    }
}

#pragma mark

-(void)swipeDown:(UIGestureRecognizer*)recognizer  {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end