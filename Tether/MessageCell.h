//
//  MessageCell.h
//  Tether
//
//  Created by Laura Smith on 2014-05-02.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Message.h"
#import "MessageThread.h"

#import <UIKit/UIKit.h>

@protocol MessageCellDelegate;

@interface MessageCell : UITableViewCell
@property (nonatomic, weak) id<MessageCellDelegate> delegate;
@property (nonatomic, strong) Message *message;
@property (nonatomic, strong) MessageThread *thread;
@property (nonatomic, assign) BOOL showName;

@end

@protocol MessageCellDelegate <NSObject>

-(void)tethrToInvite:(Invite*)invite;
-(void)declineInvite:(Invite*)invite fromMessage:(Message*)message;
-(void)openPlace:(Place*)place;

@end
