//
//  ShareViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-03-17.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#define PADDING 10.0
#define STATUS_BAR_HEIGHT 20.0
#define SEGMENT_HEIGHT 60.0
#define TOP_BAR_HEIGHT 70.0

#import "CenterViewController.h"
#import "Flurry.h"
#import "ShareViewController.h"
#import "TethrButton.h"

#import <MessageUI/MessageUI.h>
#import <Social/Social.h>

@interface ShareViewController () <MFMessageComposeViewControllerDelegate, UIGestureRecognizerDelegate>

@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UIButton *backButtonLarge;

@end

@implementation ShareViewController

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
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBack:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];

    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:14.0f];
    UILabel *topBarLabel = [[UILabel alloc] init];
    [topBarLabel setTextColor:[UIColor whiteColor]];
    topBarLabel.text = @"Share Tethr with friends";
    topBarLabel.font = montserratLarge;
    CGSize size = [topBarLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratLarge}];
    topBarLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, STATUS_BAR_HEIGHT + PADDING + 4.0, size.width, size.height);
    [self.topBar addSubview:topBarLabel];
    
    [self.view addSubview:self.topBar];
    
    // left panel view button setup
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0,  (TOP_BAR_HEIGHT + 7.0) / 2.0, 7.0, 11.0)];
    [self.backButton setImage:triangleImage forState:UIControlStateNormal];
    [self.view addSubview:self.backButton];
    self.backButton.tag = 1;
    [self.backButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    
    self.backButtonLarge = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, (self.view.frame.size.width) / 4.0, 50.0)];
    [self.backButtonLarge addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButtonLarge];
    
    UIView *segment1 = [[UIView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [self.view addSubview:segment1];
    
    TethrButton *messageButtonLarge = [[TethrButton alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [messageButtonLarge setNormalColor:UIColorFromRGB(0xf8f8f8)];
    [messageButtonLarge setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [messageButtonLarge addTarget:self action:@selector(openSMSDialog:) forControlEvents:UIControlEventTouchUpInside];
    [segment1 addSubview:messageButtonLarge];
    
    UIImageView *messageIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MessageIcon"]];
    messageIcon.frame = CGRectMake(PADDING, PADDING, 40.0, 40.0);
    [segment1 addSubview:messageIcon];
    
    UIButton *messageButton = [[UIButton alloc] init];
    [messageButton setTitle:@"Tell a Friend" forState:UIControlStateNormal];
    messageButton.titleLabel.font = montserratLarge;
    size = [messageButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLarge}];
    messageButton.frame = CGRectMake(messageIcon.frame.origin.x + messageIcon.frame.size.width + PADDING, (SEGMENT_HEIGHT - size.height) / 2.0, size.width, size.height);
    [messageButton setTitleColor:UIColorFromRGB(0x1d1d1d) forState:UIControlStateNormal];
    [messageButton addTarget:self action:@selector(openSMSDialog:) forControlEvents:UIControlEventTouchUpInside];
    [segment1 addSubview:messageButton];
    
    UIView *segment2 = [[UIView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT + SEGMENT_HEIGHT, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [self.view addSubview:segment2];
    
    TethrButton *facebookButtonLarge = [[TethrButton alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [facebookButtonLarge setNormalColor:[UIColor whiteColor]];
    [facebookButtonLarge setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [facebookButtonLarge addTarget:self action:@selector(shareOnFacebook:) forControlEvents:UIControlEventTouchUpInside];
    [segment2 addSubview:facebookButtonLarge];
    
    UIImageView *facebookIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"FacebookIcon"]];
    facebookIcon.frame = CGRectMake(PADDING, PADDING, 40.0, 40.0);
    [segment2 addSubview:facebookIcon];
    
    UIButton *facebookButton = [[UIButton alloc] init];
    [facebookButton setTitle:@"Share on Facebook" forState:UIControlStateNormal];
    facebookButton.titleLabel.font = montserratLarge;
    size = [facebookButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLarge}];
    facebookButton.frame = CGRectMake(facebookIcon.frame.origin.x + facebookIcon.frame.size.width + PADDING, (SEGMENT_HEIGHT - size.height) / 2.0, size.width, size.height);
    [facebookButton setTitleColor:UIColorFromRGB(0x1d1d1d) forState:UIControlStateNormal];
    [facebookButton addTarget:self action:@selector(tweet:) forControlEvents:UIControlEventTouchUpInside];
    [segment2 addSubview:facebookButton];
    
    UIView *segment3 = [[UIView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT + SEGMENT_HEIGHT*2, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [self.view addSubview:segment3];
    
    TethrButton *twitterButtonLarge = [[TethrButton alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [twitterButtonLarge setNormalColor:UIColorFromRGB(0xf8f8f8)];
    [twitterButtonLarge setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [twitterButtonLarge addTarget:self action:@selector(tweet:) forControlEvents:UIControlEventTouchUpInside];
    [segment3 addSubview:twitterButtonLarge];
    
    UIButton *twitterButton = [[UIButton alloc] init];
    [twitterButton setTitle:@"Share on Twitter" forState:UIControlStateNormal];
    twitterButton.titleLabel.font = montserratLarge;
    size = [twitterButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLarge}];
    twitterButton.frame = CGRectMake(facebookIcon.frame.origin.x + facebookIcon.frame.size.width + PADDING, (SEGMENT_HEIGHT - size.height) / 2.0, size.width, size.height);
    [twitterButton setTitleColor:UIColorFromRGB(0x1d1d1d) forState:UIControlStateNormal];
    [twitterButton addTarget:self action:@selector(tweet:) forControlEvents:UIControlEventTouchUpInside];
    [segment3 addSubview:twitterButton];
    
    UIImageView *twitterIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TwitterIcon"]];
    twitterIcon.frame = CGRectMake(PADDING, PADDING, 40.0, 40.0);
    [segment3 addSubview:twitterIcon];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)shareOnFacebook:(id)sender {
    [Flurry logEvent:@"User_Clicked_Share_On_Facebook"];
    NSURL* url = [NSURL URLWithString:@"https://itunes.apple.com/ca/app/tethr/id825917714?mt=8"];
    [FBDialogs presentShareDialogWithLink:url
                                  handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                      if(error) {
                                          NSLog(@"Error: %@", error.description);
                                      } else {
                                          NSLog(@"Success");
                                      }
                                  }];
}

-(IBAction)tweet:(id)sender {
    [Flurry logEvent:@"User_Clicked_Share_On_Twitter"];
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:@"Checkout #Tethr on the App Store https://itunes.apple.com/ca/app/tethr/id825917714?mt=8"];
        [tweetSheet addURL:[NSURL URLWithString:@"https://itunes.apple.com/ca/app/tethr/id825917714?mt=8"]];
        [self presentViewController:tweetSheet animated:YES completion:nil];
    }
}

-(IBAction)openSMSDialog:(id)sender {
    [Flurry logEvent:@"User_Clicked_Share_SMS"];
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    NSString *message = [NSString stringWithFormat:@"Checkout Tethr https://itunes.apple.com/app/tethr/id825917714?mt=8"];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:nil];
    [messageController setBody:message];
    
    // Present message view controller on screen
    [self addChildViewController:messageController];
    [messageController didMoveToParentViewController:self];
    [messageController.view setFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)]; //notice this is OFF screen!
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
    if ([self.delegate respondsToSelector:@selector(closeShareViewController)]) {
        [self.delegate closeShareViewController];
    }
}

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
    
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.6*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [controller.view setFrame:CGRectMake(0.0f, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [controller.view removeFromSuperview];
                         [controller removeFromParentViewController];
                     }];
}

@end
