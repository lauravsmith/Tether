//
//  PlaceCommentViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-06-04.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "PlaceCommentViewController.h"

#define PADDING 10.0
#define SLIDE_TIMING 0.1
#define STATUS_BAR_HEIGHT 20.0
#define SUB_BAR_HEIGHT 40.0
#define TOP_BAR_HEIGHT 70.0

@interface PlaceCommentViewController () <UITextViewDelegate>

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UILabel *topBarLabel;
@property (retain, nonatomic) UIButton *cancelButton;
@property (retain, nonatomic) UIButton *postButton;
@property (nonatomic, strong) UIView *subBar;
@property (nonatomic, strong) UITextView *commentTexView;
@property (retain, nonatomic) UIView *switchView;
@property (retain, nonatomic) UIView *sliderView;
@property (assign, nonatomic) BOOL sliderOn;

@end

@implementation PlaceCommentViewController

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:self.topBar];
    
    self.topBarLabel = [[UILabel alloc] init];
    self.topBarLabel.text = @"Comment";
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    [self.topBarLabel setTextColor:[UIColor whiteColor]];
    self.topBarLabel.font = montserrat;
    CGSize size = [self.topBarLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.topBarLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, STATUS_BAR_HEIGHT + (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT - size.height) / 2.0, size.width, size.height);
    [self.topBar addSubview:self.topBarLabel];
    
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, STATUS_BAR_HEIGHT, 80.0, TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT)];
    self.cancelButton.titleLabel.font = montserratSmall;
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.cancelButton];
    
    self.postButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80.0, STATUS_BAR_HEIGHT, 80.0, TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT)];
    [self.postButton addTarget:self action:@selector(postComment) forControlEvents:UIControlEventTouchUpInside];
    self.postButton.titleLabel.font = montserratSmall;
    [self.postButton setTitle:@"Post" forState:UIControlStateNormal];
    [self.postButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.postButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateDisabled];
    [self.postButton setEnabled:NO];
    [self.topBar addSubview:self.postButton];
    
    self.commentTexView = [[UITextView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
    self.commentTexView.delegate = self;
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:16.0f];
    self.commentTexView.font = montserratLarge;
    self.commentTexView.tag = 0;
    self.commentTexView.textColor = UIColorFromRGB(0xc8c8c8);
    self.commentTexView.text = @"Write something...";
    [self.view addSubview:self.commentTexView];
    [self.commentTexView becomeFirstResponder];
}

- (void)keyboardWasShown:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    self.subBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - keyboardSize.height - SUB_BAR_HEIGHT, self.view.frame.size.width, SUB_BAR_HEIGHT)];
    [self.subBar setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.subBar];
    
    self.switchView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 70.0, (self.subBar.frame.size.height - 34.0) / 2.0, 68.0, 34.0)];
    [self.switchView setBackgroundColor:[UIColor whiteColor]];
    self.switchView.layer.borderColor = UIColorFromRGB(0xc8c8c8).CGColor;
    self.switchView.layer.cornerRadius = 5.0;
    self.switchView.layer.borderWidth = 1.0;
    [self.subBar addSubview:self.switchView];
    
    self.sliderView = [[UIView alloc] initWithFrame:CGRectMake(2.0, 2.0, 30.0, 34.0 - 4.0)];
    [self.sliderView setBackgroundColor:UIColorFromRGB(0x8e0528)];
    self.sliderView.layer.cornerRadius = 5.0;
    [self.switchView addSubview:self.sliderView];
    
    UIButton *lockButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 34.0, 34.0)];
    [lockButton setImage:[UIImage imageNamed:@"Lock.png"] forState:UIControlStateNormal];
    [lockButton setImageEdgeInsets:UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0)];
    [lockButton addTarget:self action:@selector(lockTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.switchView addSubview:lockButton];
    
    UIView *sliderSeparator = [[UIView alloc] initWithFrame:CGRectMake(34.0, 0.0, 1.0, self.switchView.frame.size.height)];
    [sliderSeparator setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.switchView addSubview:sliderSeparator];
    
    UIButton *globeButton = [[UIButton alloc] initWithFrame:CGRectMake(34.0, 0.0, 34.0, 34.0)];
    [globeButton setImage:[UIImage imageNamed:@"Globe.png"] forState:UIControlStateNormal];
    [globeButton setImageEdgeInsets:UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0)];
    [globeButton addTarget:self action:@selector(globeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.switchView addSubview:globeButton];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, 1.0)];
    [separator setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.subBar addSubview:separator];
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    self.sliderOn = [standardUserDefaults boolForKey:@"private"];
}

-(void)lockTapped {
    self.sliderOn = NO;
    [self setupSlider];
}

-(void)globeTapped {
    self.sliderOn = YES;
    [self setupSlider];
}

-(void)setupSlider {
    CGRect frame;
    if (self.sliderOn) {
        frame = CGRectMake(36.0, 2.0, 30.0, 30.0);
    } else {
        frame = CGRectMake(2.0, 2.0, 30.0, 30.0);
    }

    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.sliderView.frame = frame;
                     }
                     completion:^(BOOL finished) {
                     }];
}

-(void)closeView {
    if ([self.delegate respondsToSelector:@selector(closePlaceCommentView)]) {
        [self.delegate closePlaceCommentView];
    }
}

-(void)postComment {
    PFObject *activity = [PFObject objectWithClassName:@"Activity"];
    [activity setObject:[PFUser currentUser] forKey:@"user"];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    [activity setObject:sharedDataManager.facebookId forKey:@"facebookId"];
    [activity setObject:@"comment" forKey:@"type"];
    if (![self.commentTexView.text isEqualToString:@""] && self.commentTexView.tag != 0) {
        [activity setObject:self.commentTexView.text forKey:@"content"];
    }
    
    if (!self.sliderOn) {
        [activity setObject:[NSNumber numberWithBool:!self.sliderOn] forKey:@"private"];
    }
    
    [activity setObject:self.place.placeId forKey:@"placeId"];
    [activity setObject:self.place.name forKey:@"placeName"];
    if (self.place.city) {
        [activity setObject:self.place.city forKey:@"city"];
    }
    
    if (self.place.state) {
        [activity setObject:self.place.state forKey:@"state"];
    }
    
    [activity setObject:[PFGeoPoint geoPointWithLatitude:self.place.coord.latitude
                                               longitude:self.place.coord.longitude] forKey:@"coordinate"];
    [activity setObject:[NSDate date] forKey:@"date"];
    
    if (self.place.owner) {
        [activity setObject:self.place.owner forKey:@"owner"];
    }
    
    if (self.place.memo) {
        if (![self.place.memo isEqualToString:@""]) {
            [activity setObject:self.place.memo forKey:@"memo"];
        }
    } else {
        [activity setObject:@"" forKey:@"memo"];
    }
    
    if (self.place.isPrivate) {
        [activity setObject:[NSNumber numberWithBool:self.place.isPrivate] forKey:@"private"];
    }
    
    [activity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [self.delegate reloadActivity];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your comment"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
            [alert show];
        }
    }];
    
    [self.delegate newsTapped:self];
    
    if (self.place.owner && self.place) {
        [self sendOwnerPush];
    }
    
    [self closeView];
}

-(void)sendOwnerPush {
    PFQuery *userQuery = [PFQuery queryWithClassName:@"User"];
    [userQuery whereKey:@"facebookId" equalTo:self.place.owner];
    
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && [objects count] > 0) {
            PFUser *user = [objects objectAtIndex:0];
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            NSString *messageHeader = [NSString stringWithFormat:@"%@ commented on %@", sharedDataManager.firstName, self.place.name];
            PFQuery *pushQuery = [PFInstallation query];
            [pushQuery whereKey:@"owner" equalTo:user];
            
            NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                  messageHeader, @"alert",
                                  @"placeComment", @"type",
                                  self.place.placeId, @"placeId",
                                  nil];
            
            // Send push notification to query
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:pushQuery]; // Set our Installation query
            [push setData:data];
            [push sendPushInBackground];
        }
    }];
}

#pragma mark TextViewDelegate

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView {
    if (self.commentTexView.tag == 0) {
        self.commentTexView.text = @"";
        self.commentTexView.textColor = [UIColor blackColor];
        self.commentTexView.tag = 1;
    }
    
    return YES;
}


-(void) textViewDidChange:(UITextView *)textView {
    if(self.commentTexView.text.length == 0) {
        [self.postButton setEnabled:NO];
    } else {
        [self.postButton setEnabled:YES];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        if(self.commentTexView.text.length == 0){
            [self.postButton setEnabled:NO];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
