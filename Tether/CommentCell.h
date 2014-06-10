//
//  CommentCell.h
//  Tether
//
//  Created by Laura Smith on 2014-06-04.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import <Parse/Parse.h>
#import <UIKit/UIKit.h>

@protocol CommentCellDelegate;

@interface CommentCell : UITableViewCell

@property (nonatomic, weak) id<CommentCellDelegate> delegate;
@property (nonatomic, strong) PFObject *commentObject;

@end

@protocol CommentCellDelegate <NSObject>
-(void)postSettingsClicked:(PFObject*)postObject;
@end
