//
//  TetherCache.m
//  Tether
//
//  Created by Laura Smith on 11/23/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "TetherCache.h"

@interface TetherCache()

@property (nonatomic, strong) NSCache *cache;

@end

@implementation TetherCache
@synthesize cache;

#pragma mark - Initialization

+ (id)sharedCache {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init {
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

#pragma mark - TetherCache

- (void)clear {
    [self.cache removeAllObjects];
}

- (void)setFacebookFriends:(NSArray *)friends {
    NSString *key = @"facebookFriendsKey";
//    kPAPUserDefaultsCacheFacebookFriendsKey;
    [self.cache setObject:friends forKey:key];
    [[NSUserDefaults standardUserDefaults] setObject:friends forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)facebookFriends {
    NSString *key = @"facebookFriendsKey";
//    kPAPUserDefaultsCacheFacebookFriendsKey;
    if ([self.cache objectForKey:key]) {
        return [self.cache objectForKey:key];
    }
    
    NSArray *friends = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    if (friends) {
        [self.cache setObject:friends forKey:key];
    }
    
    return friends;
}

@end
