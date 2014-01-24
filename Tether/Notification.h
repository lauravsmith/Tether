//
//  Notification.h
//  Tether
//
//  Created by Laura Smith on 12/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Friend.h"
#import "Place.h"

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface Notification : NSObject
@property (retain, nonatomic) PFObject *parseObject;
@property (retain, nonatomic) NSString *messageHeader;
@property (retain, nonatomic) NSString *message;
@property (retain, nonatomic) NSDate *time;
@property (retain, nonatomic) NSMutableArray *allRecipients;
@property (retain, nonatomic) Friend *sender;
@property (retain, nonatomic) Place *place;
@property (retain, nonatomic) NSString *placeId;
@property (retain, nonatomic) NSString *placeName;
@property (retain, nonatomic) NSString *type;
@end
