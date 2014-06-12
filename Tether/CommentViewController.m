//
//  CommentViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-06-04.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "CommentCell.h"
#import "CommentViewController.h"
#import "Datastore.h"

#define BOTTOM_BAR_HEIGHT 50.0
#define MAX_MESSAGE_FIELD_HEIGHT 150.0
#define MESSAGE_FIELD_HEIGHT 28.0
#define MESSAGE_FIELD_WIDTH 260.0
#define SEND_BUTTON_WIDTH 48.0
#define SPINNER_SIZE 30.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

@interface CommentViewController () <CommentCellDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>

@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UILabel * topBarLabel;
@property (retain, nonatomic) UIView * bottomBar;
@property (retain, nonatomic) UIView * bottomBarBorder;
@property (retain, nonatomic) UITextView * textView;
@property (retain, nonatomic) UIButton *postButton;
@property (retain, nonatomic) NSMutableArray *commentsArray;
@property (nonatomic, strong) UITableView *commentsTableView;
@property (nonatomic, strong) UITableViewController *commentsTableViewController;
@property (nonatomic, assign) BOOL keyboardShowing;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, strong) NSNotification * notification;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
@property (retain, nonatomic) PFObject * commentToDelete;

@end

@implementation CommentViewController

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
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBack:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];
    
    // top bar setup
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, self.view.frame.size.width,TOP_BAR_HEIGHT)];
    self.topBar.layer.backgroundColor = UIColorFromRGB(0x8e0528).CGColor;
    [self.view addSubview:self.topBar];
    
    self.topBarLabel = [[UILabel alloc] init];
    self.topBarLabel.text = @"Comments";
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    [self.topBarLabel setTextColor:[UIColor whiteColor]];
    self.topBarLabel.font = montserrat;
    self.topBarLabel.adjustsFontSizeToFitWidth = YES;
    CGSize size = [self.topBarLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.topBarLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, STATUS_BAR_HEIGHT + (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT - size.height) / 2.0, size.width, size.height);
    [self.topBar addSubview:self.topBarLabel];
    
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, (TOP_BAR_HEIGHT - 31.0 + STATUS_BAR_HEIGHT) / 2.0, 32.0, 31.0)];
    [self.backButton setImageEdgeInsets:UIEdgeInsetsMake(10.0, 5.0, 10.0, 20.0)];
    [self.backButton setImage:triangleImage forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.backButton];
    
    // bottom bar setup
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width,BOTTOM_BAR_HEIGHT)];
    self.bottomBar.layer.backgroundColor = UIColorFromRGB(0xf8f8f8).CGColor;
    [self.view addSubview:self.bottomBar];
    
    self.bottomBarBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 0.5)];
    [self.bottomBarBorder setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.bottomBar addSubview:self.bottomBarBorder];

    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(10.0,(self.bottomBar.frame.size.height - MESSAGE_FIELD_HEIGHT) / 2.0, MESSAGE_FIELD_WIDTH, MESSAGE_FIELD_HEIGHT)];
    self.textView.delegate = self;
    self.textView.text = @"";
    [self.textView setScrollEnabled:NO];
    [[self.textView layer] setBorderColor:UIColorFromRGB(0xc8c8c8).CGColor];
    [[self.textView layer] setBorderWidth:0.5];
    [[self.textView layer] setCornerRadius:4.0];
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:16.0f];
    self.textView.font = montserratLarge;
    self.textView.textColor = UIColorFromRGB(0xc8c8c8);
    
    [self.bottomBar addSubview:self.textView];
    
    self.postButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - SEND_BUTTON_WIDTH, 0.0, SEND_BUTTON_WIDTH, self.bottomBar.frame.size.height)];
    [self.postButton setTitle:@"Post" forState:UIControlStateNormal];
    [self.postButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateDisabled];
    self.postButton.titleLabel.font = montserratLarge;
    [self.postButton addTarget:self action:@selector(postClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.postButton setEnabled:NO];
    [self.bottomBar addSubview:self.postButton];
    
    self.commentsArray = [[NSMutableArray alloc] init];
    
    self.commentsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT)];
    [self.commentsTableView setDataSource:self];
    [self.commentsTableView setDelegate:self];
    [self.commentsTableView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.commentsTableView];
    self.commentsTableView.showsVerticalScrollIndicator = NO;
    
    self.commentsTableViewController = [[UITableViewController alloc] init];
    self.commentsTableViewController.tableView = self.commentsTableView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [self.textView becomeFirstResponder];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - SPINNER_SIZE) / 2.0, TOP_BAR_HEIGHT + 10.0, SPINNER_SIZE, SPINNER_SIZE)];
    self.activityIndicatorView.color = UIColorFromRGB(0x8e0528);
    [self.view addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
    
    [self loadComments];
}

-(void)loadComments {
    PFQuery *query = [PFQuery queryWithClassName:@"Comment"];
    [query whereKey:@"activity" equalTo:self.activityObject];
    [query includeKey:@"user"];
    [query orderByAscending:@"date"];
    [query setLimit:100];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.commentsArray = [[NSMutableArray alloc] initWithArray:objects];
        [self.commentsTableView reloadData];
        [self.activityIndicatorView stopAnimating];
    }];
}

-(void)closeView {
    if ([self.delegate respondsToSelector:@selector(closeCommentView)]) {
        [self.delegate closeCommentView];
    }
}

-(void)postClicked {
    PFObject *comment = [PFObject objectWithClassName:@"Comment"];
    [comment setObject:[PFUser currentUser] forKey:@"user"];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [comment setObject:sharedDataManager.facebookId forKey:@"facebookId"];
    [comment setObject:self.textView.text forKey:@"content"];
    [comment setObject:self.activityObject forKey:@"activity"];
    
    [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self.commentsArray addObject:comment];
            [self.commentsTableView reloadData];
            
            self.textView.text = @"";
            int commentCount = [[self.activityObject objectForKey:@"commentCount"] intValue];
            if (!commentCount) {
                commentCount = 0;
            }
            commentCount += 1;
            self.activityObject[@"commentCount"] = [NSNumber numberWithInt:commentCount];
            [self.activityObject saveInBackground];
            
            [self sendCommentPush:[comment objectForKey:@"content"]];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your comment" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
        }
    }];

}

-(void)sendCommentPush:(NSString*)comment {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    NSString *type = [self.activityObject objectForKey:@"type"];
    if ([type isEqualToString:@"createLocation"]) {
        type = @"location";
    }
    
    NSString *messageHeader = [NSString stringWithFormat:@"%@ commented on your %@: %@", sharedDataManager.firstName, type, comment];
    PFObject *personalNotificationObject = [PFObject objectWithClassName:@"PersonalNotification"];
    [personalNotificationObject setObject:[PFUser currentUser] forKey:@"fromUser"];
    [personalNotificationObject setObject:[self.activityObject objectForKey:@"user"] forKey:@"toUser"];
    [personalNotificationObject setObject:messageHeader forKey:@"content"];
    [personalNotificationObject setObject:self.activityObject forKey:@"activity"];
    [personalNotificationObject setObject:@"comment" forKey:@"type"];
    [personalNotificationObject saveInBackground];
    
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"owner" equalTo:[self.activityObject objectForKey:@"user"]];
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          messageHeader, @"alert",
                          @"comment", @"type",
                          self.activityObject.objectId, @"postId",
                          nil];
    
    // Send push notification to query
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery];
    [push setData:data];
    [push sendPushInBackground];
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
        [self.postButton setEnabled:NO];
    }
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    
    NSDictionary *attributes = @{NSFontAttributeName: montserrat};
    CGRect rect = [[NSString stringWithFormat:@"      %@", self.textView.text] boundingRectWithSize:CGSizeMake(MESSAGE_FIELD_WIDTH, 200.0)
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
    
    [self.postButton setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    [self.postButton setEnabled:YES];
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
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    
    NSDictionary *attributes = @{NSFontAttributeName: montserrat};
    CGRect rect = [[NSString stringWithFormat:@"      %@", self.textView.text] boundingRectWithSize:CGSizeMake(MESSAGE_FIELD_WIDTH, 200.0)
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
    
    return YES;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        [self.commentToDelete deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [self loadComments];
                int count = [[self.activityObject objectForKey:@"commentCount"] intValue];
                count = MAX(0, count - 1);
                [self.activityObject setObject:[NSNumber numberWithInt:count] forKey:@"commentCount"];
                [self.activityObject saveInBackground];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Could not delete your post, please try again" message:nil delegate: nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }];
    }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            if ([button.titleLabel.text isEqualToString:@"Delete Comment"]) {
                [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            }
        }
    }
}

#pragma mark CommentCellDelegate

-(void)postSettingsClicked:(PFObject*)commentObject {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Delete Comment", nil];
    [actionSheet showInView:self.view];
    self.commentToDelete = commentObject;
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *commentObject = [self.commentsArray objectAtIndex:indexPath.row];
    NSString *content = [commentObject objectForKey:@"content"];
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    CGRect textRect = [content boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 60.0, 1000.0)
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:@{NSFontAttributeName:montserrat}
                                            context:nil];
    return textRect.size.height + 40.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.commentsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CommentCell *cell = [[CommentCell alloc] init];
    cell.delegate = self;
    [cell setCommentObject:[self.commentsArray objectAtIndex:indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    self.notification = notification;
    self.keyboardShowing = YES;
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.keyboardHeight = keyboardSize.height;
    
    CGRect tableFrame = self.commentsTableView.frame;
    tableFrame.size.height = self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT - keyboardSize.height;
    self.commentsTableView.frame = tableFrame;
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         CGRect frame = self.bottomBar.frame;
                         frame.origin.y = self.view.frame.size.height - keyboardSize.height - frame.size.height;
                         self.bottomBar.frame = frame;
                     }];
}

-(void)keyboardWillHide {
    CGRect tableFrame = self.commentsTableView.frame;
    tableFrame.size.height = self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT;
    self.keyboardHeight = 0.0;
    
    self.keyboardShowing = NO;
    [UIView animateWithDuration:0.3
                     animations:^{
                         CGRect frame = self.bottomBar.frame;
                         frame.origin.y = self.view.frame.size.height - frame.size.height;
                         self.bottomBar.frame = frame;
                         self.commentsTableView.frame = tableFrame;
                     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
