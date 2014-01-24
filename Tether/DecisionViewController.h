//
//  DecisionViewController.h
//  Tether
//
//  Created by Laura Smith on 11/24/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DecisionViewControllerDelegate;

@interface DecisionViewController : UIViewController

@property (nonatomic, weak) id<DecisionViewControllerDelegate> delegate;
@property (strong, nonatomic) UILabel *numberLabel;
-(void)addProfileImageView;
-(IBAction)handleYesButton:(id)sender;
-(IBAction)handleNoButton:(id)sender;
-(void)layoutNumberLabel;

@end

@protocol DecisionViewControllerDelegate <NSObject>

-(void)handleChoice:(BOOL)choice;

@end