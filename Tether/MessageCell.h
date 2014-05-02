//
//  MessageCell.h
//  Tether
//
//  Created by Laura Smith on 2014-05-02.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "Message.h"

#import <UIKit/UIKit.h>

@interface MessageCell : UITableViewCell

@property (nonatomic, strong) Message *message;
@property (nonatomic, assign) BOOL showName;

@end
