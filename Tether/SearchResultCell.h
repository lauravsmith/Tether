//
//  SearchResultCell.h
//  Tether
//
//  Created by Laura Smith on 12/11/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Place.h"

#import <UIKit/UIKit.h>

@protocol SearchResultCellDelegate;

@interface SearchResultCell : UITableViewCell
@property (nonatomic, weak) id<SearchResultCellDelegate> delegate;
@property (nonatomic, strong) Place *place;
@end

@protocol SearchResultCellDelegate <NSObject>

@end