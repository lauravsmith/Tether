//
//  CreatePlaceViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-04-07.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "TethrButton.h"
#import <UIKit/UIKit.h>

@protocol CreatePlaceViewControllerDelegate;

@interface CreatePlaceViewController : UIViewController
@property (nonatomic, weak) id<CreatePlaceViewControllerDelegate> delegate;
@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UILabel * topBarLabel;
@property (retain, nonatomic) UILabel * nameLabel;
@property (retain, nonatomic) UITextField * nameTextField;
@property (retain, nonatomic) UILabel * addressLabel;
@property (retain, nonatomic) UITextField * addressTextField;
@property (retain, nonatomic) UILabel * memoLabel;
@property (retain, nonatomic) UITextField * memoTextField;
@property (retain, nonatomic) UILabel * privateLabel;
@property (retain, nonatomic) UISwitch * privateSwitch;
@property (strong, nonatomic) TethrButton *createButton;
@property (retain, nonatomic) MKMapView * mv;
@property (retain, nonatomic) MKPointAnnotation *annotation;
@property (retain, nonatomic) UIView *confirmationView;
@property (retain, nonatomic) UILabel *confirmationLabel;
@property (nonatomic, retain) Place *place;
@property (retain, nonatomic) UIActivityIndicatorView *activityIndicatorView;
-(void)showConfirmationForAction:(NSString*)action;
-(void)dismissConfirmationForAction:(NSString*)action;
-(void)closeView;
-(void)closeViewAfterDelete;
@end

@protocol CreatePlaceViewControllerDelegate <NSObject>
@required
-(void)closeCreatePlaceVC;

@optional
-(void)refreshListAfterDelete;
-(void)openNewPlaceWithId:(NSString*)placeId;
-(void)refreshPlaceDetails:(Place*)place;
@end
