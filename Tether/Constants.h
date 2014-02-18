//
//  Constants.h
//  Tether
//
//  Created by Laura Smith on 12/22/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#pragma mark - NSUserDefaults
extern NSString *const kUserDefaultsCityKey;
extern NSString *const kUserDefaultsStateKey;
extern NSString *const kUserDefaultsStatusKey;
extern NSString *const kUserDefaultsTimeLastUpdatedKey;
extern NSString *const kUserDefaultsHasSeenTethrTutorialKey;
extern NSString *const kUserDefaultsHasSeenPlaceInviteTutorialKey;
extern NSString *const kUserDefaultsHasSeenFriendInviteTutorialKey;
extern NSString *const kUserDefaultsHasSeenPlaceTethrTutorialKey;
extern NSString *const kUserDefaultsHasSeenRefreshTutorialKey;
extern NSString *const kUserDefaultsHasSeenFriendsListTutorialKey;
extern NSString *const kUserDefaultsHasSeenPlaceListTutorialKey;
extern NSString *const kUserDefaultsHasSeenCityChangeTutorialKey;
extern NSString *const kUserDefaultsHasSeenBlockTutorialKey;

#pragma mark - PFObject User Class
extern NSString *const kUserDisplayNameKey;
extern NSString *const kUserFirstNameKey;
extern NSString *const kUserFacebookIDKey;
extern NSString *const kUserCityKey;
extern NSString *const kUserStateKey;
extern NSString *const kUserStatusKey;
extern NSString *const kUserStatusMessageKey;
extern NSString *const kUserGenderKey;
extern NSString *const kUserFacebookFriendsKey;
extern NSString *const kUserTimeLastUpdatedKey;
extern NSString *const kUserBlockedListKey;

#pragma mark - PFObject Commitment Class
extern NSString *const kCommitmentClassKey;
extern NSString *const kCommitmentPlaceKey;
extern NSString *const kCommitmentGeoPointKey;
extern NSString *const kCommitmentDateKey;
extern NSString *const kCommitmentAddressKey;
extern NSString *const kCommitmentPlaceIDKey;
extern NSString *const kCommitmentCityKey;
extern NSString *const kCommitmentStateKey;

#pragma mark - Notification Class
extern NSString *const kNotificationClassKey;
extern NSString *const kNotificationSenderKey;
extern NSString *const kNotificationPlaceNameKey;
extern NSString *const kNotificationPlaceIdKey;
extern NSString *const kNotificationMessageHeaderKey;
extern NSString *const kNotificationMessageContentKey;
extern NSString *const kNotificationRecipientKey;
extern NSString *const kNotificationAllRecipientsKey;
extern NSString *const kNotificationTypeKey;
extern NSString *const kNotificationCityKey;

#pragma mark - CityPlaceSearch Class
extern NSString *const kCityPlaceSearchClassKey;
extern NSString *const kCityPlaceSearchCityKey;
extern NSString *const kCityPlaceSearchStateKey;
extern NSString *const kCityPlaceSearchDateKey;

#pragma mark - Place Class
extern NSString *const kPlaceClassKey;
extern NSString *const kPlaceSearchKey;
extern NSString *const kPlaceCityKey;
extern NSString *const kPlaceStateKey;
extern NSString *const kPlaceCoordinateKey;
extern NSString *const kPlaceNameKey;
extern NSString *const kPlaceAddressKey;