//
//  TetherCache.h
//  Tether
//
//  Created by Laura Smith on 11/23/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface TetherCache : NSObject
+ (id)sharedCache;

- (void)clear;
- (NSDictionary *)attributesForUser:(PFUser *)user;
- (void)setFacebookFriends:(NSArray *)friends;
- (NSArray *)facebookFriends;

@end
