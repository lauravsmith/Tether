//
//  LoginViewController.m
//  Tether
//
//  Created by Laura Smith on 11/22/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "AppDelegate.h"
#import "CenterViewController.h"
#import "LoginViewController.h"
#import <Parse/Parse.h>

@interface LoginViewController ()

@end

@implementation LoginViewController

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
    
    UIImage *topImage = [UIImage imageNamed:@"LoginPageImage"];
    UIImageView *topImageView = [[UIImageView alloc] initWithImage:topImage];
    topImageView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height * 3.5 /4.0);
    topImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:topImageView];
    
    UIImageView *textureImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BlackTexture"]];
    textureImageView.frame = CGRectMake(0, self.view.frame.size.height - self.view.frame.size.height / 3.0, self.view.frame.size.width, self.view.frame.size.height / 3.0);
    [self.view addSubview:textureImageView];

    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:15.0f];
    UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:15.0f];
    
    UILabel *sloganLabel = [[UILabel alloc] init];
    sloganLabel.text = @"tethr brings people together.";
    sloganLabel.lineBreakMode = NSLineBreakByWordWrapping;
    sloganLabel.numberOfLines = 2.0;
    sloganLabel.textAlignment = NSTextAlignmentCenter;
    sloganLabel.font = montserrat;
    sloganLabel.textColor = UIColorFromRGB(0x8e0528);
    sloganLabel.frame = CGRectMake((self.view.frame.size.width - 160.0) / 2.0, self.view.frame.size.height / 3.5, 160.0, 40.0);
    [self.view addSubview:sloganLabel];
    
    self.loginButton = [[UIButton alloc] init];
    [self.loginButton setTitle:@"Login with facebook" forState:UIControlStateNormal];
    self.loginButton.frame = CGRectMake((self.view.frame.size.width - 230.0) / 2.0, textureImageView.frame.origin.y - 25.0, 230.0, 50.0);
    [self.loginButton setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = montserratBold;
    [self.loginButton setTitleEdgeInsets:UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)];
    [self.loginButton addTarget:self action:@selector(loginButtonTouchHandler:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.loginButton];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 50.0) / 2, sloganLabel.frame.origin.y + (self.loginButton.frame.origin.y - sloganLabel.frame.origin.y) / 2.0, 50.0, 50.0)];
    [self.spinner setColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:self.spinner];
}

- (IBAction)loginButtonTouchHandler:(id)sender  {
    [self.spinner startAnimating];
    
    [self.loginButton setEnabled:NO];
    
    [self login];
}

-(void)login {
    [PFFacebookUtils initializeFacebook];
    
    NSArray *permissionsArray = @[ @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
            }
            [self loginPerformed:NO];
        } else if (user.isNew) {
            NSLog(@"User with facebook signed up and logged in!");
            [self loginPerformed:YES];
        } else {
            NSLog(@"User with facebook logged in!");
            [self loginPerformed:YES];
        }
    }];
}

-(void)loginPerformed:(BOOL)loggedIn {
    [self.spinner stopAnimating];
    
    if (loggedIn) {
        AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate sessionStateChanged:[FBSession activeSession] state:[FBSession activeSession].state error:nil];
        
        // Saving the device's owner to the push installation
        PFInstallation *installation = [PFInstallation currentInstallation];
        [installation setObject:[PFUser currentUser] forKey:@"owner"];
        [installation saveInBackground];
        
    } else {
        // Show error alert
		[[[UIAlertView alloc] initWithTitle:@"Login Failed"
                                    message:@"Facebook Login failed. Please try again"
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
    }
}

-(void)loginFailed {
    [self.spinner stopAnimating];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
