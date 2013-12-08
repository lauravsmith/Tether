//
//  TetherAnnotation.h
//  Tether
//
//  Created by Laura Smith on 12/2/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Place.h"

#import <MapKit/MapKit.h>

@interface TetherAnnotation : MKPointAnnotation
@property (nonatomic, strong) Place *place;
@end
