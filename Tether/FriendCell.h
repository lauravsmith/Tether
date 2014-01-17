//
//  FriendCell.h
//  Tether
//
//  Created by Laura Smith on 11/24/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Friend.h"
#import <FacebookSDK/FacebookSDK.h>
#import <UIKit/UIKit.h>

@protocol FriendCellDelegate;

@interface FriendCell : UITableViewCell
@property (nonatomic, weak) id<FriendCellDelegate> delegate;
@property (nonatomic, strong) Friend *friend;
@end

@protocol FriendCellDelegate <NSObject>
-(void)goToPlaceInListView:(id)placeId;
-(void)inviteFriend:(Friend*)friend;
@end
