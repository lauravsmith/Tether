//
//  MessageThreadCell.m
//  Tether
//
//  Created by Laura Smith on 2014-04-24.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "MessageThreadCell.h"

#define MAX_LABEL_WIDTH 150.0
#define NAME_LABEL_OFFSET_X 70.0

@interface MessageThreadCellContentView : UIView

@property (nonatomic, strong) MessageThread *messageThread;
@property (nonatomic, strong) UILabel *friendNamesLabel;
@property (nonatomic, strong) UILabel *recentMessageLabel;
@property (nonatomic, strong) FBProfilePictureView *friendProfilePictureView;

@end

@implementation MessageThreadCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.friendNamesLabel = [[UILabel alloc] init];
        [self addSubview:self.friendNamesLabel];
        self.recentMessageLabel = [[UILabel alloc] init];
        [self addSubview:self.recentMessageLabel];
        [self setBackgroundColor:[UIColor blackColor]];
    }
    return self;
}

- (void)layoutSubviews {
    self.recentMessageLabel.text = self.messageThread.recentMessage;
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    CGSize size = [self.recentMessageLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.recentMessageLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, self.friendProfilePictureView.frame.origin.y, MIN(size.width, MAX_LABEL_WIDTH), size.height);
    [self.recentMessageLabel setTextColor:[UIColor whiteColor]];
    [self.recentMessageLabel setFont:montserrat];
}

- (void)prepareForReuse {
    [self layoutSubviews];
}

- (void)setMessageThread:(MessageThread *)thread {
    _messageThread = thread;
    
    [self setNeedsLayout];
}
@end


@interface MessageThreadCell()
@property (nonatomic, strong) MessageThreadCellContentView *cellContentView;
@end

@implementation MessageThreadCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
    }
    return self;
}

- (MessageThreadCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[MessageThreadCellContentView alloc] initWithFrame:self.contentView.bounds];
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_cellContentView];
    }
    return _cellContentView;
}

- (void)setMessageThread:(id<FBGraphUser>)thread {
    _messageThread = thread;
    [self.cellContentView setMessageThread:thread];
}

@end
