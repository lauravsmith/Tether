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
@property (nonatomic, strong) UITableView *placesTableView;
-(void)getFriendsCommitments;
-(void)removePreviousCommitment;
-(void)scrollToPlaceWithId:(id)placeId;
-(void)removeCommitmentFromDatabase;
-(void)sortPlacesByPopularity;
-(void)openPageForPlaceWithId:(id)placeId;

@end

@protocol PlacesViewControllerDelegate <NSObject>

-(void)placeMarkOnMapView:(Place*)place;
-(void)closeListView;
-(void)setPlace:(id)placeId forFriend:(id)friendId;
-(void)commitToPlace:(Place*)place;
-(void)canUpdatePlaces:(BOOL)canUpdate;
-(void)refreshCommitmentName;
-(void)removePreviousCommitment;
-(void)removeCommitmentFromDatabase;
-(void)movePanelToOriginalPosition;
-(void)movePanelRight;
-(void)movePanelLeft;
-(void)removePlaceMarkFromMapView:(Place*)place;
-(void)sortFriendsList;
-(void)pollDatabase;

@end