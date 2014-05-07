//
//  NewMessageViewController.h
//  Tether
//
//  Created by Laura Smith on 2014-04-30.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "MessageThread.h"

#import <UIKit/UIKit.h>

@protocol NewMessageViewControllerDelegate;

@interface NewMessageViewController : UIViewController
@property (nonatomic, weak) id<NewMessageViewControllerDelegate> delegate;
@property (retain, nonatomic) MessageThread *thread;
@property (retain, nonatomic) NSMutableArray *messagesArray;
@property (retain, nonatomic) PFObject *messageThreadObject;
-(void)loadMessages;

@end

@protocol NewMessageViewControllerDelegate <NSObject>
-(void)closeNewMessageView;
@end