//
//  Datastore.m
//  Tether
//
//  Created by Laura Smith on 12/7/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Datastore.h"

@implementation Datastore

@synthesize facebookId;
@synthesize name;
@synthesize city;
@synthesize state;
@synthesize facebookFriends;
@synthesize status;
@synthesize tetherFriendsNearbyDictionary;
@synthesize tetherFriendsDictionary;
@synthesize tetherFriendsGoingOut;
@synthesize tetherFriendsNotGoingOut;
@synthesize tetherFriendsUndecided;
@synthesize friendsPlacesDictionary;
@synthesize foursquarePlacesDictionary;
@synthesize placesDictionary;
@synthesize currentCommitmentParseObject;
@synthesize currentCommitmentPlace;

#pragma mark Singleton Methods

+ (id)sharedDataManager {
    static Datastore *sharedDataManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDataManager = [[self alloc] init];
    });
    return sharedDataManager;
}

@end

