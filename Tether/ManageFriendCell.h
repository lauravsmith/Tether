//
//  ManageFriendCell.h
//  Tether
//
//  Created by Laura Smith on 2/11/2014.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Friend.h"
#import "FriendAtPlaceCell.h"

@protocol ManageFriendCellDelegate;

@interface ManageFriendCell : UITableViewCell
@property (nonatomic, weak) id<ManageFriendCellDelegate> delegate;
@property (nonatomic, strong) Friend *friend;
@end

@protocol ManageFriendCellDelegate <NSObject>

- (void)blockFriend:(Friend*)friend setBlocked:(BOOL)block;

@end