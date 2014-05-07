//
//  Message.h
//  Tether
//
//  Created by Laura Smith on 2014-04-24.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Invite.h"

#import <Foundation/Foundation.h>

@interface Message : NSObject
@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSString *threadId;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) Invite *invite;
@end