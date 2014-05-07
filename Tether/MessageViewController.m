//
//  MessageViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-04-25.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "Flurry.h"
#import "Message.h"
#import "MessageCell.h"
#import "MessageThread.h"
#import "MessageViewController.h"
#import "SelectInviteLocationViewController.h"

#define BOTTOM_BAR_HEIGHT 50.0
#define MAX_LABEL_WIDTH 200.0
#define MAX_MESSAGE_FIELD_HEIGHT 150.0
#define MESSAGE_FIELD_HEIGHT 28.0
#define MESSAGE_FIELD_WIDTH 229.0
#define MIN_CELL_HEIGHT 40.0
#define PADDING 15.0
#define POLLING_INTERVAL 10
#define SEND_BUTTON_WIDTH 48.0
#define SLIDE_TIMING 0.6
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

@interface MessageViewController () <MessageCellDelegate, SelectInviteLocationViewControllerDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UILabel * nameLabel;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UIView * bottomBar;
@property (retain, nonatomic) UIView * bottomBarBorder;
@property (retain, nonatomic) UITextView * textView;
@property (nonatomic, strong) UITableView *messagesTableView;
@property (nonatomic, strong) UITableViewController *messagesTableViewController;
@property (nonatomic, assign) BOOL keyboardShowing;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) NSNotification * notification;
@property (retain, nonatomic) UIButton *sendButton;
@property (nonatomic, assign) NSTimer *pollingTimer;
@property (retain, nonatomic) UIButton *inviteButton;
@property (retain, nonatomic) UIImageView *inviteImageView;
@property (nonatomic, strong) SelectInviteLocationViewController *selectInviteViewController;

@end

@implementation MessageViewController

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
    [self.backButton addTarget:self action:@selector(closeMessageView) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.backButton];
    
    // name labels setup
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    NSString *names = @"";
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    for (NSString *friendName in self.thread.participantNames) {
        if (![friendName isEqualToString:sharedDataManager.name] && ![friendName isEqualToString:sharedDataManager.firstName]) {
            if ([names isEqualToString:@""]) {
                names = friendName;
            } else {
                names = [NSString stringWithFormat:@"%@, %@", names,friendName];
            }
        }
    }
    
    self.nameLabel = [[UILabel alloc] init];
    [self.nameLabel setTextColor:[UIColor whiteColor]];
    self.nameLabel.font = montserrat;
    [self.nameLabel setText:names];
    CGSize size = [self.nameLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.nameLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, (TOP_BAR_HEIGHT - size.height + STATUS_BAR_HEIGHT) / 2.0, size.width, size.height);
    [self.topBar addSubview:self.nameLabel];
    
    self.messagesArray = [[NSMutableArray alloc] init];
    
    self.messagesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT)];
    [self.messagesTableView setDataSource:self];
    [self.messagesTableView setDelegate:self];
    [self.messagesTableView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.messagesTableView];
    self.messagesTableView.showsVerticalScrollIndicator = NO;
    [self.messagesTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    self.messagesTableViewController = [[UITableViewController alloc] init];
    self.messagesTableViewController.tableView = self.messagesTableView;
    
    if ([self.thread.messages count] > 0) {
        for (id key in self.thread.messages) {
            Message *message = [self.thread.messages objectForKey:key];
            [self.messagesArray addObject:message];
        }
        
        NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
        [self.messagesArray sortUsingDescriptors:[NSArray arrayWithObjects:dateDescriptor, nil]];
    } else {
        [self loadMessages];
    }
    [self.messagesTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // bottom bar setup
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width,BOTTOM_BAR_HEIGHT)];
    self.bottomBar.layer.backgroundColor = UIColorFromRGB(0xf8f8f8).CGColor;
    [self.view addSubview:self.bottomBar];
    
    self.bottomBarBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 0.5)];
    [self.bottomBarBorder setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.bottomBar addSubview:self.bottomBarBorder];
    
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
    
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - SEND_BUTTON_WIDTH, 0.0, SEND_BUTTON_WIDTH, self.bottomBar.frame.size.height)];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.sendButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = montserrat;
    [self.sendButton addTarget:self action:@selector(sendClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setEnabled:NO];
    [self.bottomBar addSubview:self.sendButton];
    
    UISwipeGestureRecognizer * swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
    [swipeDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.bottomBar addGestureRecognizer:swipeDown];
    
    UISwipeGestureRecognizer * swipeDownTextView = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
    [swipeDownTextView setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.textView addGestureRecognizer:swipeDownTextView];
    
    if (self.thread.unread) {
        [self markRead];
    }
    
    if (self.thread && [self.messagesArray count] > 0) {
        NSIndexPath* ipath = [NSIndexPath indexPathForRow: [self.messagesArray count] -1 inSection: 0];
        [self.messagesTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
    }
    
    self.inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, self.textView.frame.origin.x, BOTTOM_BAR_HEIGHT)];
    [self.inviteButton addTarget:self action:@selector(inviteClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.inviteImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0, 5.0, 21, 38)];
    [self.inviteImageView setImage:[UIImage imageNamed:@"PinIcon"]];
    [self.inviteButton addSubview:self.inviteImageView];
    [self.bottomBar addSubview:self.inviteButton];
    
    self.keyboardHeight = 0.0;
}

-(void)markRead {
    self.thread.unread = NO;
    [self.thread.participantObject setObject:[NSNumber numberWithBool:NO] forKey:@"unread"];
    [self.thread.participantObject saveInBackground];
    self.shouldUpdateMessageThreadVC = YES;
}

-(void)closeMessageView {
    if ([self.delegate respondsToSelector:@selector(closeMessageView)]) {
        [self.delegate closeMessageView];
    }
}

-(void)loadMessages {
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
                
                NSIndexPath* ipath = [NSIndexPath indexPathForRow: MAX(0, [self.messagesArray count] -1) inSection: 0];
                [self.messagesTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: NO];
                
                [sharedDataManager.messageThreadDictionary setObject:self.thread forKey:self.thread.threadId];
                self.shouldUpdateMessageThreadVC = YES;
            }
        }
    }];
}

-(void)moveBack:(id)sender {
    [[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];
    
    CGPoint velocity = [(UIPanGestureRecognizer*)sender velocityInView:[sender view]];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if(velocity.x > 0) {
            [self closeMessageView];
        }
    }
}

#pragma mark MessageCellDelegate

-(void)tethrToInvite:(Invite *)invite {
    NSLog(@"TETHR TO INVITE %@", invite.place.name);
    if ([self.delegate respondsToSelector:@selector(tethrToInvite:)]) {
        [self.delegate tethrToInvite:invite];
    }
    
    [self sendResponseToInvite:invite response:YES];
}

-(void)declineInvite:(Invite*)invite fromMessage:(Message*)message{
    [self.thread.messages setObject:message forKey:message.messageId];
    [self sendResponseToInvite:invite response:NO];
}

-(void)openPlace:(Place *)place {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (![sharedDataManager.foursquarePlacesDictionary objectForKey:place.placeId]) {
        [sharedDataManager.foursquarePlacesDictionary setObject:place forKey:place.placeId];
        if ([self.delegate respondsToSelector:@selector(newPlaceAdded)]) {
            [self.delegate newPlaceAdded];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(openPageForPlaceWithId:)]) {
        [self.delegate openPageForPlaceWithId:place.placeId];
    }
}

#pragma mark IBAction Delegate

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
                             [Flurry logEvent:@"User_Views_Select_Location_Invite_Page"];
                         }];
    }
}

-(IBAction)sendClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    Message *newMessage = [[Message alloc] init];
    newMessage.content = self.textView.text;
    newMessage.date = [NSDate date];
    newMessage.userId = sharedDataManager.facebookId;
    newMessage.userName = sharedDataManager.name;
    newMessage.threadId = self.thread.threadId;
    
    [self sendMessage:newMessage withInvite:nil];
    
    [self.messagesArray addObject:newMessage];
    [self.messagesTableView reloadData];
    
    self.textView.text = @"";
    
    NSIndexPath* ipath = [NSIndexPath indexPathForRow: MAX(0, [self.messagesArray count] -1) inSection: 0];
    [self.messagesTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
    
    [self textViewDidChange:self.textView];
}

-(void)sendMessage:(Message*)message withInvite:(PFObject*)inviteObject{
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    // create message object associated with the thread object
    PFObject *messageObject = [PFObject objectWithClassName:@"Message"];
    NSString *recentMessage = @"";
    if (inviteObject) {
        recentMessage = [NSString stringWithFormat:@"%@ invited you to %@", sharedDataManager.name, [inviteObject objectForKey:@"placeName"]];
    } else {
        recentMessage = message.content;
    }
    [messageObject setObject:recentMessage forKey:@"message"];
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
    [self.thread.threadObject setObject:recentMessage forKey:@"recentMessage"];
    [self.thread.threadObject saveEventually];
    
    self.bottomBar.frame = CGRectMake(0.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width,BOTTOM_BAR_HEIGHT);
    self.bottomBarBorder.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 0.5);
    
    CGRect frame = self.bottomBar.frame;
    frame.origin.y = self.view.frame.size.height - self.keyboardHeight - frame.size.height;
    self.bottomBar.frame = frame;
    
    self.textView.frame = CGRectMake((self.bottomBar.frame.size.width - MESSAGE_FIELD_WIDTH) / 2.0,(self.bottomBar.frame.size.height - MESSAGE_FIELD_HEIGHT) / 2.0, MESSAGE_FIELD_WIDTH, MESSAGE_FIELD_HEIGHT);
    self.textView.textColor = UIColorFromRGB(0xc8c8c8);
    self.textView.text = @"Type a message...";
    [self.textView setScrollEnabled:NO];
}

-(void)sendResponseToInvite:(Invite*)invite response:(BOOL)response {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    Message *newMessage = [[Message alloc] init];
    if (response) {
        newMessage.content = [NSString stringWithFormat:@"%@ tethred to %@", sharedDataManager.name, invite.place.name];
    } else {
        newMessage.content = [NSString stringWithFormat:@"%@ declined the invite to %@", sharedDataManager.name, invite.place.name];
    }
    newMessage.date = [NSDate date];
    newMessage.userId = @"";
    newMessage.userName = sharedDataManager.name;
    newMessage.threadId = self.thread.threadId;
    
    [self sendMessage:newMessage withInvite:nil];
    
    self.messagesArray = [[NSMutableArray alloc] init];
    for (id key in self.thread.messages) {
        Message *message = [self.thread.messages objectForKey:key];
        [self.messagesArray addObject:message];
    }
    
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [self.messagesArray sortUsingDescriptors:[NSArray arrayWithObjects:dateDescriptor, nil]];
    
    [self.messagesArray addObject:newMessage];
    [self.messagesTableView reloadData];
    
    NSIndexPath* ipath = [NSIndexPath indexPathForRow: MAX(0, [self.messagesArray count] -1) inSection: 0];
    [self.messagesTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
}

#pragma mark SelectInviteViewControllerDelegate

-(void)inviteToPlace:(Place*) place {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    Message *newMessage = [[Message alloc] init];
    
    if (self.thread.isGroupMessage) {
        newMessage.content = [NSString stringWithFormat:@"You sent an invite to %@", place.name];
    } else {
        for (NSString *name in self.thread.participantNames) {
            if (![name isEqualToString:sharedDataManager.name]) {
                newMessage.content = [NSString stringWithFormat:@"You invited %@ to %@", name, place.name];
            }
        }
    }
    newMessage.date = [NSDate date];
    newMessage.userId = sharedDataManager.facebookId;
    newMessage.userName = sharedDataManager.name;
    newMessage.threadId = self.thread.threadId;
    
    Invite *invite = [[Invite alloc] init];
    invite.place = place;
    newMessage.invite = invite;
    
    // create message object associated with the thread object
    PFObject *inviteObject = [PFObject objectWithClassName:@"Invite"];
    [inviteObject setObject:place.name forKey:@"placeName"];
    [inviteObject setObject:place.placeId forKey:@"placeId"];
    [inviteObject setObject:place.city forKey:@"city"];
    [inviteObject setObject:place.state forKey:@"state"];
    
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

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messagesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell *cell = [[MessageCell alloc] init];
    cell.delegate = self;
    Message *message = [self.messagesArray objectAtIndex:indexPath.row];
    [cell setThread:self.thread];
    
    if (self.thread.isGroupMessage && !message.invite) {
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
                         if(self.textView.text.length == 0){
                             self.textView.textColor = UIColorFromRGB(0xc8c8c8);
                             self.textView.text = @"Type a message...";
                             self.textView.tag = 0;
                             [self.sendButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
                             [self.sendButton setEnabled:NO];
                         }
                     }];
}

#pragma mark TextViewDelegate

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    if (self.textView.tag == 0) {
        self.textView.text = @"";
        self.textView.textColor = [UIColor blackColor];
        self.textView.tag = 1;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
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

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        if(self.textView.text.length == 0){
            self.textView.textColor = UIColorFromRGB(0xc8c8c8);
            self.textView.text = @"Type a message...";
            [self.textView resignFirstResponder];
            self.textView.tag = 0;
        }
        return NO;
    }
    
    return YES;
}

#pragma mark UIGestureRecognizer

-(void)swipeDown:(UIGestureRecognizer*)recognizer  {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
