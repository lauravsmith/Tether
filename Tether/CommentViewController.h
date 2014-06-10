//
//  CommentViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-06-04.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CommentViewControllerDelegate;

@interface CommentViewController : UIViewController

@property (nonatomic, weak) id<CommentViewControllerDelegate> delegate;
@property (retain, nonatomic) PFObject * activityObject;

@end

@protocol CommentViewControllerDelegate <NSObject>
-(void)closeCommentView;
@end