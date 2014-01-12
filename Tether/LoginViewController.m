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
    
    self.loginButton = [[UIButton alloc] init];
    [self.loginButton setTitle:@"Login with facebook" forState:UIControlStateNormal];
    UIFont *champagne = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:25];
    CGSize size = [self.loginButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:champagne}];
    CGRect frame = self.loginButton.frame;
    frame.origin.x = (self.view.frame.size.width - size.width) / 2.0;
    frame.origin.y = self.view.frame.size.height / 2.0;
    frame.size.width = size.width + 10.0;
    frame.size.height = size.height;
    self.loginButton.frame = frame;
    [self.loginButton setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = champagne;
    self.loginButton.layer.cornerRadius = 10.0;
    [self.loginButton setTitleEdgeInsets:UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)];
    [self.loginButton addTarget:self action:@selector(loginButtonTouchHandler:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.loginButton];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 50.0) / 2, 100.0, 50.0, 50.0)];
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
