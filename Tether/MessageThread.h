//
//  MessageThread.h
//  Tether
//
//  Created by Laura Smith on 2014-04-24.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MessageThread : NSObject

@property (nonatomic, strong) NSString *threadId;
@property (nonatomic, strong) NSDate *recentMessageDate;
@property (nonatomic, strong) NSString *recentMessage;
@property (nonatomic, assign) BOOL *unread;
@property (nonatomic, strong) NSMutableSet *participantIds;
@property (nonatomic, strong) NSMutableSet *participantNames;
@property (nonatomic, strong) NSMutableSet *Messages;

@end