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
    NSString *city;
    NSString *state;
    BOOL status;
    BOOL userSetLocation;
    NSArray *facebookFriends;
    NSMutableDictionary *tetherFriendsNearbyDictionary;
    NSMutableDictionary *tetherFriendsDictionary;
    NSMutableArray * tetherFriendsGoingOut;
    NSMutableArray * tetherFriendsNotGoingOut;
    NSMutableArray * tetherFriendsUndecided;
    NSMutableDictionary *friendsToPlacesMap;
    NSMutableDictionary *popularPlacesDictionary;
    NSMutableDictionary *foursquarePlacesDictionary;
    NSMutableDictionary *placesDictionary;
    PFObject *currentCommitmentParseObject;
    Place *currentCommitmentPlace;
}

@property (nonatomic, retain) NSString *facebookId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSArray *facebookFriends;
@property (nonatomic, retain) NSMutableDictionary *tetherFriendsNearbyDictionary;
@property (nonatomic, retain) NSMutableDictionary *tetherFriendsDictionary;
@property (nonatomic, assign) BOOL status;
@property (nonatomic, assign) BOOL userSetLocation;
@property (nonatomic, strong) NSMutableArray * tetherFriendsGoingOut;
@property (nonatomic, strong) NSMutableArray * tetherFriendsNotGoingOut;
@property (nonatomic, strong) NSMutableArray * tetherFriendsUndecided;
@property (nonatomic, strong) NSMutableDictionary *friendsToPlacesMap;
@property (nonatomic, strong) NSMutableDictionary *popularPlacesDictionary;
@property (nonatomic, strong) NSMutableDictionary *foursquarePlacesDictionary;
@property (nonatomic, strong) NSMutableDictionary *placesDictionary;
@property (retain, nonatomic) PFObject *currentCommitmentParseObject;
@property (retain, nonatomic) Place *currentCommitmentPlace;

+ (id)sharedDataManager;

@end