//
//  MessageCell.m
//  Tether
//
//  Created by Laura Smith on 2014-04-25.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "Message.h"
#import "MessageCell.h"

#define MAX_LABEL_WIDTH 150.0
#define NAME_LABEL_OFFSET_X 20.0

@interface MessageCellContentView : UIView

@property (nonatomic, strong) Message *message;
@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation MessageCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.messageLabel = [[UILabel alloc] init];
        [self addSubview:self.messageLabel];
    }
    return self;
}

- (void)layoutSubviews {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.messageLabel.text = self.message.content;
    [self.messageLabel setFont:montserrat];
    CGSize size = [self.messageLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    if ([self.message.userId isEqualToString:sharedDataManager.facebookId]) {
        self.messageLabel.frame = CGRectMake(self.frame.size.width - size.width - NAME_LABEL_OFFSET_X, 10.0, MIN(size.width, MAX_LABEL_WIDTH), size.height);
        [self.messageLabel setTextColor:[UIColor whiteColor]];
        [self.messageLabel setBackgroundColor:UIColorFromRGB(0x8e0528)];
    } else {
        self.messageLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, 10.0, MIN(size.width, MAX_LABEL_WIDTH), size.height);
        [self.messageLabel setTextColor:[UIColor blackColor]];
        [self.messageLabel setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
    }
}

- (void)setMessage:(Message *)message {
    _message = message;
    
    [self setNeedsLayout];
}

@end

@interface MessageCell()
@property (nonatomic, strong) MessageCellContentView *cellContentView;
@end

@implementation MessageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (MessageCellContentView *)cellContentView {
    if (!_cellContentView) {
        _cellContentView = [[MessageCellContentView alloc] initWithFrame:self.contentView.bounds];
        _cellContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:_cellContentView];
    }
    return _cellContentView;
}

- (void)setMessage:(Message*)message {
    _message = message;
    [self.cellContentView setMessage:message];
}

- (void)awakeFromNib
{
    // Initialization code
}

@end
