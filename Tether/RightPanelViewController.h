//
//  RightPanelViewController.h
//  Tether
//
//  Created by Laura Smith on 12/12/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RightPanelViewControllerDelegate;

@interface RightPanelViewController : UIViewController
@property (nonatomic, weak) id<RightPanelViewControllerDelegate> delegate;
@property (retain, nonatomic) NSMutableArray *notificationsArray;
@property (nonatomic, strong) UITableView *notificationsTableView;
@property (nonatomic, strong) UITableViewController *notificationsTableViewController;
-(void)loadNotifications;
@end

@protocol RightPanelViewControllerDelegate <NSObject>

-(void)openPageForPlaceWithId:(id)placeId;
-(void)goToPlaceInListView:(id)placeId;
-(void)userChangedLocationToCityName:(NSString*)city;
-(void)openMessageViewControllerForMessageThread:(MessageThread *)thread;
-(void)openNewMessageViewController;

@end