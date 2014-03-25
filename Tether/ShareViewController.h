//
//  ShareViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-03-17.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ShareViewControllerDelegate;

@interface ShareViewController : UIViewController

@property (nonatomic, weak) id<ShareViewControllerDelegate> delegate;

@end

@protocol ShareViewControllerDelegate <NSObject>

-(void)closeShareViewController;

@end
