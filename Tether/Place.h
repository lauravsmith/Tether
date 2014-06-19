//
//  Place.h
//  Tether
//
//  Created by Laura Smith on 11/29/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

@interface Place : NSObject
@property (nonatomic, strong) id placeId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) CLLocationCoordinate2D coord;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSMutableSet *friendsCommitted;
@property (nonatomic, strong) NSMutableSet *othersCommitted;
@property (nonatomic, assign) int numberCommitments;
@property (nonatomic, assign) int numberPastCommitments;
@property (nonatomic, strong) NSString *memo;
@property (nonatomic, strong) NSString *owner;
@property (nonatomic, assign) BOOL isPrivate;
@property (nonatomic, strong) NSDate *date;
@end
