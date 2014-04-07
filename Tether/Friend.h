//
//  Friend.h
//  Tether
//
//  Created by Laura Smith on 11/25/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Place.h"
#import <Foundation/Foundation.h>

@interface Friend : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *friendID;
@property (nonatomic, strong) NSString *statusMessage;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSDate *timeLastUpdated;
@property (nonatomic, strong) NSArray *friendsArray;
@property (nonatomic, assign) BOOL status;
@property (nonatomic, assign) id placeId;
@property (nonatomic, assign) int mutualFriendsCount;
@property (nonatomic, assign) BOOL blocked;
@end
