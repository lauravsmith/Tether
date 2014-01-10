//
//  RightPanelViewController.h
//  Tether
//
//  Created by Laura Smith on 12/12/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RightPanelViewController : UIViewController
@property (retain, nonatomic) NSMutableArray *notificationsArray;
-(void)loadNotifications;
@end
