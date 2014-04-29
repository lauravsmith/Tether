//
//  MessageViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-04-25.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "Message.h"
#import "MessageCell.h"
#import "MessageThread.h"
#import "MessageViewController.h"

#define BOTTOM_BAR_HEIGHT 50.0
#define MAX_MESSAGE_FIELD_HEIGHT 150.0
#define MESSAGE_FIELD_HEIGHT 28.0
#define MESSAGE_FIELD_WIDTH 229.0
#define MIN_CELL_HEIGHT 60.0
#define SEND_BUTTON_WIDTH 48.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

@interface MessageViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UILabel * nameLabel;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UIView * bottomBar;
@property (retain, nonatomic) UITextView * textView;
@property (nonatomic, strong) UITableView *messagesTableView;
@property (nonatomic, strong) UITableViewController *messagesTableViewController;
@property (nonatomic, assign) BOOL keyboardShowing;
@property (nonatomic, strong) NSNotification * notification;
@property (retain, nonatomic) UIButton *sendButton;

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
        if (![friendName isEqualToString:sharedDataManager.name]) {
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
    
    for (id key in self.thread.messages) {
        Message *message = [self.thread.messages objectForKey:key];
        [self.messagesArray addObject:message];
    }
    
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [self.messagesArray sortUsingDescriptors:[NSArray arrayWithObjects:dateDescriptor, nil]];
    
    self.messagesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT)];
    [self.messagesTableView setDataSource:self];
    [self.messagesTableView setDelegate:self];
    [self.messagesTableView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.messagesTableView];
    self.messagesTableView.showsVerticalScrollIndicator = NO;
    
    self.messagesTableViewController = [[UITableViewController alloc] init];
    self.messagesTableViewController.tableView = self.messagesTableView;
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
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake((self.bottomBar.frame.size.width - MESSAGE_FIELD_WIDTH) / 2.0,(self.bottomBar.frame.size.height - MESSAGE_FIELD_HEIGHT) / 2.0, MESSAGE_FIELD_WIDTH, MESSAGE_FIELD_HEIGHT)];
    self.textView.delegate = self;
    [[self.textView layer] setBorderColor:UIColorFromRGB(0xc8c8c8).CGColor];
    [[self.textView layer] setBorderWidth:0.5];
    [[self.textView layer] setCornerRadius:4.0];
    self.textView.font = montserrat;
    [self.bottomBar addSubview:self.textView];
    
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - SEND_BUTTON_WIDTH, 0.0, SEND_BUTTON_WIDTH, self.bottomBar.frame.size.height)];
    [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
    [self.sendButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = montserrat;
    [self.sendButton addTarget:self action:@selector(sendClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:self.sendButton];
}

-(void)closeMessageView {
    if ([self.delegate respondsToSelector:@selector(closeMessageView)]) {
        [self.delegate closeMessageView];
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
    
    [self sendMessage:newMessage];
    
    [self.messagesArray addObject:newMessage];
    [self.messagesTableView reloadData];
    
    self.textView.text = @"";
    
    NSIndexPath* ipath = [NSIndexPath indexPathForRow: [self.messagesArray count] -1 inSection: 0];
    [self.messagesTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
}

-(void)sendMessage:(Message*)message {
    // create message object associated with the thread object
    PFObject *messageObject = [PFObject objectWithClassName:@"Message"];
    [messageObject setObject:message.content forKey:@"message"];
    [messageObject setObject:message.userId forKey:@"facebookId"];
    [messageObject setObject:message.userName forKey:@"name"];
    [messageObject setObject:self.thread.threadObject forKey:@"threadId"];
    [messageObject saveEventually];
    
    // update recent message value of thread
    [self.thread.threadObject setObject:message.content forKey:@"recentMessage"];
    [self.thread.threadObject saveEventually];
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return MIN_CELL_HEIGHT;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messagesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell *cell = [[MessageCell alloc] init];
    [cell setMessage:[self.messagesArray objectAtIndex:indexPath.row]];
    return cell;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    self.notification = notification;
    self.keyboardShowing = YES;
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    CGRect tableFrame = self.messagesTableView.frame;
    tableFrame.size.height = self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT - keyboardSize.height;
    self.messagesTableView.frame = tableFrame;
    
    NSIndexPath* ipath = [NSIndexPath indexPathForRow: [self.messagesArray count] -1 inSection: 0];
    [self.messagesTableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                    CGRect frame = self.bottomBar.frame;
                    frame.origin.y = self.view.frame.size.height - keyboardSize.height - frame.size.height;
                    self.bottomBar.frame = frame;
                     }];
}

-(void)keyboardWillHide {
    self.keyboardShowing = NO;
    [UIView animateWithDuration:0.3
                     animations:^{
                         CGRect frame = self.bottomBar.frame;
                         frame.origin.y = self.view.frame.size.height - frame.size.height;
                         self.bottomBar.frame = frame;
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
        self.textView.textColor = UIColorFromRGB(0xc8c8c8);
        self.textView.text = @"Type a message...";
        [self.textView resignFirstResponder];
        self.textView.tag = 0;
        [self.sendButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    } else {
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
        
        NSDictionary *attributes = @{NSFontAttributeName: montserrat};
        CGRect rect = [self.textView.text boundingRectWithSize:CGSizeMake(MESSAGE_FIELD_WIDTH, 200.0)
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:attributes
                                                  context:nil];
        CGRect frame = self.textView.frame;
        frame.size.height = MAX(MESSAGE_FIELD_HEIGHT, MIN(rect.size.height, MAX_MESSAGE_FIELD_HEIGHT));
        self.textView.frame = frame;
        
        frame = self.bottomBar.frame;
        frame.size.height = self.textView.frame.size.height + 22.0;
        if (self.keyboardShowing) {
            // Works in both portrait and landscape mode
            CGSize keyboardSize = [[[self.notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
            
            frame.origin.y = self.view.frame.size.height - keyboardSize.height - frame.size.height;
        } else {
            frame.origin.y = self.view.frame.size.height - frame.size.height;
        }
        self.bottomBar.frame = frame;
        
        [self.sendButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
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
    
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
