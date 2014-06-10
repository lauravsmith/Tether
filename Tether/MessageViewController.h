//
//  MessageViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-04-25.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "MessageThread.h"

@protocol MessageViewControllerDelegate;

@interface MessageViewController : UIViewController
@property (nonatomic, weak) id<MessageViewControllerDelegate> delegate;
@property (retain, nonatomic) MessageThread *thread;
@property (retain, nonatomic) PFObject *messageParticipant;
@property (retain, nonatomic) NSMutableArray *messagesArray;
@property (nonatomic, assign) BOOL shouldUpdateMessageThreadVC;
-(void)loadMessages;
-(void)loadMessagesFromThreadId:(NSString*)threadId;

@end

@protocol MessageViewControllerDelegate <NSObject>
-(void)tethrToInvite:(Invite*)invite;
-(void)closeMessageView;
-(void)newPlaceAdded;
-(void)openPageForPlaceWithId:(NSString*)placeId;
-(void)showProfileOfFriend:(Friend*)user;
@end