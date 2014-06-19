//
//  FindFriendsViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-06-17.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "ViewController.h"

@protocol FindFriendsViewControllerDelegate;

@interface FindFriendsViewController : ViewController

@property (nonatomic, weak) id<FindFriendsViewControllerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *findFriendsArray;
@property (nonatomic, strong) NSMutableArray *friendIdsArray;

@end

@protocol FindFriendsViewControllerDelegate <NSObject>

-(void)closeFindFriendsVC;
-(void)pollDatabase;

@end