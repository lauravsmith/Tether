//
//  CenterViewController.h
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "LeftPanelViewController.h"
#import "ViewController.h"

#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
//RGB color macro
#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@protocol CenterViewControllerDelegate <NSObject>

@optional
- (void)movePanelRight;
- (void)movePanelLeft;

@required
- (void)movePanelToOriginalPosition;
- (void)showSettingsView;
-(void)showListView;
-(void)finishedResettingNewLocation;
-(void)saveCity:(NSString*)city state:(NSString*)state;
@end

@interface CenterViewController : ViewController <MKMapViewDelegate>

@property (nonatomic, assign) id<CenterViewControllerDelegate> delegate;

@property (retain, nonatomic) UIButton *bottomLeftButton;
@property (retain, nonatomic) UIButton * numberButton;
@property (retain, nonatomic) UILabel * cityLabel;
@property (retain, nonatomic) MKMapView * mv;
@property (retain, nonatomic) NSMutableDictionary * placeToAnnotationDictionary;
@property (assign, nonatomic) bool resettingLocation;
@property (strong, nonatomic) UIButton *notificationsButton;
@property (retain, nonatomic) UILabel * placeLabel;
@property (retain, nonatomic) UILabel * placeNumberLabel;
-(void)updateLocation;
-(void)setCityFromCLLocation:(CLLocation*)location;
-(void)layoutNumberLabel;
-(void)locationSetup;
-(void)refreshNotificationsNumber;
@end
