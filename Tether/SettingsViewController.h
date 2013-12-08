//
//  SettingsViewController.h
//  Tether
//
//  Created by Laura Smith on 11/28/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "ViewController.h"

#import <FacebookSDK/FacebookSDK.h>

@protocol SettingsViewControllerDelegate;

@interface SettingsViewController : ViewController

@property (nonatomic, weak) id<SettingsViewControllerDelegate> delegate;
@property (nonatomic, strong) FBProfilePictureView *userProfilePictureView;
@property (retain, nonatomic) NSString * city;

@end

@protocol SettingsViewControllerDelegate <NSObject>

-(void)closeSettings;
-(void)updateStatus;

@end
