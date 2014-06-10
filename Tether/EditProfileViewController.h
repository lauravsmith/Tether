//
//  EditProfileViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-06-02.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "ILGeoNamesLookup.h"

#import <UIKit/UIKit.h>

@protocol EditProfileViewControllerDelegate;

@interface EditProfileViewController : UIViewController

@property (nonatomic, weak) id<EditProfileViewControllerDelegate> delegate;

@end

@protocol EditProfileViewControllerDelegate <NSObject>

-(void)closeEditProfileVC;
-(void)userChangedSettingsToUseCurrentLocation;
-(void)userChangedLocationInSettings:(CLLocation*)newLocation;

@end