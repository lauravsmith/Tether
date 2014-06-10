//
//  MainViewController.h
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "ViewController.h"

#import <UIKit/UIKit.h>

@interface MainViewController : ViewController
@property (nonatomic, strong) CenterViewController *centerViewController;
@property (strong, nonatomic) NSMutableDictionary *friendsDictionary;
@property (assign, nonatomic) BOOL openMessage;
-(void)pollDatabase;
-(void)movePanelLeft;
-(void)loadNotifications;
-(void)showDecisionView;
-(void)refreshNotificationsNumber;
-(void)updateNotificationsNumber;
-(BOOL)shouldShowDecisionView;
-(void)setupView;
-(void)queryFriendsStatus;
-(void)showPostFromPush:(NSString*)postId;
-(void)openMessageWithThreadId:(NSString*)threadId;
@end
