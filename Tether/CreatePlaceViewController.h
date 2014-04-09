//
//  CreatePlaceViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-04-07.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

@protocol CreatePlaceViewControllerDelegate;

@interface CreatePlaceViewController : UIViewController
@property (nonatomic, weak) id<CreatePlaceViewControllerDelegate> delegate;

@end

@protocol CreatePlaceViewControllerDelegate <NSObject>
-(void)closeCreatePlaceVC;
@end
