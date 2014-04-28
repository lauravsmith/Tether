//
//  MessageViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-04-25.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

@protocol MessageViewControllerDelegate;

@interface MessageViewController : UIViewController
@property (nonatomic, weak) id<MessageViewControllerDelegate> delegate;
@property (retain, nonatomic) MessageThread *thread;
@property (retain, nonatomic) PFObject *messageThreadObject;
@property (retain, nonatomic) NSMutableArray *messagesArray;

@end

@protocol MessageViewControllerDelegate <NSObject>
-(void)closeMessageView;
@end