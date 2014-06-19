//
//  FindFriendCell.h
//  Tether
//
//  Created by Laura Smith on 2014-06-17.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FindFriendCellDelegate;

@interface FindFriendCell : UITableViewCell
@property (nonatomic, weak) id<FindFriendCellDelegate> delegate;
@property (nonatomic, strong) Friend *user;
@property (nonatomic, strong) NSMutableDictionary *findFriendsDictionary;
- (void)setUser:(Friend*)user;
-(void)setFindFriendsDictionary:(NSMutableDictionary *)findFriendsDictionary;

@end

@protocol FindFriendCellDelegate <NSObject>

-(void)followFriend:(Friend*)user following:(BOOL)follow;

@end