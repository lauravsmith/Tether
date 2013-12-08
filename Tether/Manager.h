//
//  Manager.h
//  Tether
//
//  Created by Laura Smith on 12/7/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Manager : NSObject {
   NSString *facebookId;
    NSString *name;
}

@property (nonatomic, retain) NSString *facebookId;
@property (nonatomic, retain) NSString *name;

+ (id)sharedManager;

@end