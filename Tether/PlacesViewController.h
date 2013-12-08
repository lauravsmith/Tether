//
//  PlacesViewController.h
//  Tether
//
//  Created by Laura Smith on 11/29/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "ViewController.h"

@protocol PlacesViewControllerDelegate;

@interface PlacesViewController : ViewController
@property (nonatomic, weak) id<PlacesViewControllerDelegate> delegate;
-(void)getFriendsCommitments;
-(void)removePreviousCommitment;
@end

@protocol PlacesViewControllerDelegate <NSObject>

-(void)placeMarkOnMapView:(Place*)place;
-(void)closeListView;
-(void)setPlace:(id)placeId forFriend:(id)friendId;
-(void)commitToPlace:(Place*)place;

@end