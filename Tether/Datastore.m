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
@synthesize firstName;
@synthesize facebookFriends;
@synthesize tetherFriends;
@synthesize blockedFriends;
@synthesize friendsOfFriends;
@synthesize statusMessage;
@synthesize tetherFriendsNearbyDictionary;
@synthesize tetherFriendsDictionary;
@synthesize tetherFriendsGoingOut;
@synthesize tetherFriendsNotGoingOut;
@synthesize tetherFriendsUndecided;
@synthesize tetherFriendsUnseen;
@synthesize friendsToPlacesMap;
@synthesize popularPlacesDictionary;
@synthesize foursquarePlacesDictionary;
@synthesize tethrPlacesDictionary;
@synthesize placesDictionary;
@synthesize historicalTethrsDictionary;
@synthesize currentCommitmentParseObject;
@synthesize currentCommitmentPlace;
@synthesize notifications;
@synthesize todaysNotificationsArray;
@synthesize blockedList;
@synthesize bestFriendSet;
@synthesize placeIDForNotification;
@synthesize hasUpdatedFriends;
@synthesize placesArray;
@synthesize userCoordinates;
@synthesize messageThreadDictionary;
@synthesize profilePicture;

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

