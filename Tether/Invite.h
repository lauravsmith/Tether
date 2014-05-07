//
//  Invite.h
//  Tether
//
//  Created by Laura Smith on 2014-05-02.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Place.h"

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface Invite : NSObject

@property (nonatomic, strong) PFObject *inviteObject;
@property (nonatomic, strong) Place *place;
@property (nonatomic, strong) NSMutableSet *acceptances;
@property (nonatomic, strong) NSMutableSet *declines;

@end
