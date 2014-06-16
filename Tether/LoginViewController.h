//
//  LoginViewController.h
//  Tether
//
//  Created by Laura Smith on 11/22/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "TethrButton.h"

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (strong, nonatomic) TethrButton *loginButton;
-(void)loginPerformed:(BOOL)loggedIn withError:(NSError *)error;
-(void)loginFailed;
@end
