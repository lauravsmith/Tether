//
//  MessageThreadCell.h
//  Tether
//
//  Created by Laura Smith on 2014-04-24.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "MessageThread.h"

#import <FacebookSDK/FacebookSDK.h>
#import <UIKit/UIKit.h>

@interface MessageThreadCell : UITableViewCell

@property (nonatomic, strong) MessageThread *messageThread;

@end
