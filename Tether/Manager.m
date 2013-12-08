//
//  Manager.m
//  Tether
//
//  Created by Laura Smith on 12/7/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Manager.h"

@implementation Manager

@synthesize facebookId;

#pragma mark Singleton Methods

+ (id)sharedManager {
    static Manager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}


@end

