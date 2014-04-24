//
//  Datastore.h
//  Tether
//
//  Created by Laura Smith on 12/7/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Place.h"
#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface Datastore : NSObject {
    NSString *facebookId;
    NSString *name;
    NSString *statusMessage;
    NSArray *facebookFriends;
    NSMutableArray * tetherFriends;
    NSMutableArray * blockedFriends;
    NSMutableDictionary *tetherFriendsNearbyDictionary;
    NSMutableDictionary *tetherFriendsDictionary;
    NSMutableArray * tetherFriendsGoingOut;
    NSMutableArray * tetherFriendsNotGoingOut;
    NSMutableArray * tetherFriendsUndecided;
    NSMutableArray * tetherFriendsUnseen;
    NSMutableDictionary *friendsToPlacesMap;
    NSMutableDictionary *popularPlacesDictionary;
    NSMutableDictionary *foursquarePlacesDictionary;
    NSMutableDictionary *tethrPlacesDictionary;
    NSMutableDictionary *placesDictionary;
    PFObject *currentCommitmentParseObject;
    Place *currentCommitmentPlace;
    NSInteger notifications;
    NSMutableArray *todaysNotificationsArray;
    NSMutableArray * blockedList;
    NSMutableSet *bestFriendSet;
    NSString *placeIDForNotification;
    BOOL hasUpdatedFriends;
    NSMutableArray * placesArray;
    CLLocation *userCoordinates;
}

@property (nonatomic, retain) NSString *facebookId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSArray *facebookFriends;
@property (nonatomic, strong) NSMutableArray * tetherFriends;
@property (nonatomic, strong) NSMutableArray * blockedFriends;
@property (nonatomic, retain) NSMutableDictionary *tetherFriendsNearbyDictionary;
@property (nonatomic, retain) NSMutableDictionary *tetherFriendsDictionary;
@property (nonatomic, retain) NSString *statusMessage;
@property (nonatomic, strong) NSMutableArray * tetherFriendsGoingOut;
@property (nonatomic, strong) NSMutableArray * tetherFriendsNotGoingOut;
@property (nonatomic, strong) NSMutableArray * tetherFriendsUndecided;
@property (nonatomic, strong) NSMutableArray * tetherFriendsUnseen;
@property (nonatomic, strong) NSMutableArray * blockedList;
@property (nonatomic, strong) NSMutableDictionary *friendsToPlacesMap;
@property (nonatomic, strong) NSMutableDictionary *popularPlacesDictionary;
@property (nonatomic, strong) NSMutableDictionary *foursquarePlacesDictionary;
@property (nonatomic, strong) NSMutableDictionary *tethrPlacesDictionary;
@property (nonatomic, strong) NSMutableDictionary *placesDictionary;
@property (retain, nonatomic) PFObject *currentCommitmentParseObject;
@property (retain, nonatomic) Place *currentCommitmentPlace;
@property (nonatomic, assign) NSInteger notifications;
@property (nonatomic, strong) NSMutableArray *todaysNotificationsArray;
@property (nonatomic, strong) NSMutableSet *bestFriendSet;
@property (nonatomic, strong) NSString *placeIDForNotification;
@property (nonatomic, assign) BOOL hasUpdatedFriends;
@property (nonatomic, strong) NSMutableArray * placesArray;
@property (strong, nonatomic) CLLocation *userCoordinates;

+ (id)sharedDataManager;

@end