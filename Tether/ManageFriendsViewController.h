//
//  ManageFriendsViewController.h
//  Tether
//
//  Created by Laura Smith on 2/11/2014.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Friend.h"
#import "ViewController.h"

@protocol ManageFriendsViewControllerDelegate;

@interface ManageFriendsViewController : ViewController

@property (nonatomic, assign) id<ManageFriendsViewControllerDelegate> delegate;

@end

@protocol ManageFriendsViewControllerDelegate <NSObject>
-(void)blockFriend:(Friend*)friend block:(BOOL)block;
-(void)closeManageFriendsView;
@end