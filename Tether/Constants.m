//
//  Constants.m
//  Tether
//
//  Created by Laura Smith on 12/22/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Constants.h"

#pragma mark - NSUserDefaults
NSString *const kUserDefaultsCityKey             = @"city";
NSString *const kUserDefaultsStateKey            = @"state";
NSString *const kUserDefaultsStatusKey           = @"status";
NSString *const kUserDefaultsTimeLastUpdatedKey  = @"timeLastUpdated";
NSString *const kUserDefaultsHasSeenTethrTutorialKey = @"hasSeenTethrTutorial";
NSString *const kUserDefaultsHasSeenPlaceInviteTutorialKey = @"hasSeenPlaceInviteTutorial";
NSString *const kUserDefaultsHasSeenPlaceTethrTutorialKey = @"hasSeenPlaceTethrTutorial";
NSString *const kUserDefaultsHasSeenRefreshTutorialKey = @"hasSeenRefreshTutorial";
NSString *const kUserDefaultsHasSeenFriendsListTutorialKey= @"hasSeenFriendsListTutorial";
NSString *const kUserDefaultsHasSeenPlaceListTutorialKey= @"hasSeenPlaceListTutorial";
NSString *const kUserDefaultsHasSeenBlockTutorialKey= @"hasSeenBlockTutorial";

#pragma mark - User Class
NSString *const kUserDisplayNameKey     = @"displayName";
NSString *const kUserFirstNameKey       = @"firstName";
NSString *const kUserFacebookIDKey      = @"facebookId";
NSString *const kUserCityKey            = @"cityLocation";
NSString *const kUserStateKey           = @"stateLocation";
NSString *const kUserStatusKey          = @"status";
NSString *const kUserStatusMessageKey   = @"statusMessage";
NSString *const kUserGenderKey          = @"gender";
NSString *const kUserFacebookFriendsKey = @"facebookFriends";
NSString *const kUserTimeLastUpdatedKey = @"timeLastUpdated";
NSString *const kUserBlockedListKey     = @"blockedList";

#pragma mark - Commitment Class
NSString *const kCommitmentClassKey     = @"Commitment";
NSString *const kCommitmentPlaceKey     = @"placeName";
NSString *const kCommitmentGeoPointKey  = @"placePoint";
NSString *const kCommitmentDateKey      = @"dateCommitted";
NSString *const kCommitmentAddressKey   = @"address";
NSString *const kCommitmentPlaceIDKey   = @"placeId";
NSString *const kCommitmentCityKey      = @"placeCityName";
NSString *const kCommitmentStateKey     = @"state";

#pragma mark - Notification Class
NSString *const kNotificationClassKey         = @"Notification";
NSString *const kNotificationSenderKey        = @"sender";
NSString *const kNotificationPlaceNameKey     = @"placeName";
NSString *const kNotificationPlaceIdKey       = @"placeId";
NSString *const kNotificationMessageHeaderKey = @"messageHeader";
NSString *const kNotificationMessageContentKey = @"message";
NSString *const kNotificationRecipientKey = @"recipientID";
NSString *const kNotificationAllRecipientsKey = @"allRecipients";
NSString *const kNotificationTypeKey = @"type";
NSString *const kNotificationCityKey = @"city";

#pragma mark - CityPlaceSearch Class
NSString *const kCityPlaceSearchClassKey = @"CityPlaceSearch";
NSString *const kCityPlaceSearchCityKey = @"city";
NSString *const kCityPlaceSearchStateKey = @"state";
NSString *const kCityPlaceSearchDateKey = @"date";

#pragma mark - Place Class
NSString *const kPlaceClassKey = @"Place";
NSString *const kPlaceSearchKey =  @"placeSearchObjectId";
NSString *const kPlaceCityKey = @"city";
NSString *const kPlaceStateKey =  @"state";
NSString *const kPlaceCoordinateKey = @"coordinate";
NSString *const kPlaceNameKey = @"name";
NSString *const kPlaceAddressKey = @"address";