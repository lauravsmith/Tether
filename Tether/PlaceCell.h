//
//  PlaceCell.h
//  Tether
//
//  Created by Laura Smith on 11/30/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Place.h"

#import <UIKit/UIKit.h>

@protocol PlaceCellDelegate;

@interface PlaceCell : UITableViewCell
@property (nonatomic, weak) id<PlaceCellDelegate> delegate;
@property (nonatomic, strong) Place *place;
@property (nonatomic, strong) NSIndexPath *cellIndexPath;
-(void)setTethered:(bool)isTethered;
@end

@protocol PlaceCellDelegate <NSObject>

-(void)commitToPlace:(Place *)place fromCell:(PlaceCell*)cell;
-(void)removePreviousCommitment;
-(void)removeCommitmentFromDatabase;
-(void)showFriendsViewFromCell:(PlaceCell*)placeCell;
-(void)inviteToPlace:(Place *)place;

@end