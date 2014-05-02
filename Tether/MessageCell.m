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
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, assign) int showName;

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
    if (self.showName && ![self.message.userId isEqualToString:sharedDataManager.facebookId]) {
        UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:12.0f];
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.text = self.message.userName;
        [self.nameLabel setFont:montserratSmall];
        CGSize size = [self.nameLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratSmall}];
        self.nameLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, 0.0, size.width, size.height);
        [self.nameLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
        [self addSubview:self.nameLabel];
    }
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    self.messageLabel.text = self.message.content;
    [self.messageLabel setFont:montserrat];
    
    NSDictionary *attributes = @{NSFontAttributeName: montserrat};
    CGRect rect = [self.messageLabel.text boundingRectWithSize:CGSizeMake(MAX_LABEL_WIDTH, 1000.0)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:attributes
                                                       context:nil];
    
    self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.messageLabel.numberOfLines = 0;
    
    float yOrigin = 0.0;
    if (self.showName) {
        yOrigin = self.nameLabel.frame.size.height + 5.0;
    } else {
        yOrigin = 10.0;
    }
    
    if ([self.message.userId isEqualToString:sharedDataManager.facebookId]) {
        self.messageLabel.frame = CGRectMake(self.frame.size.width - rect.size.width - NAME_LABEL_OFFSET_X, yOrigin, MIN(rect.size.width, MAX_LABEL_WIDTH), rect.size.height);
        [self.messageLabel setTextColor:[UIColor whiteColor]];
        [self.messageLabel setBackgroundColor:UIColorFromRGB(0x8e0528)];
    } else {
        self.messageLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X, yOrigin, MIN(rect.size.width, MAX_LABEL_WIDTH), rect.size.height);
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
    if (self.showName) {
        self.cellContentView.showName = self.showName;
    }
    
    [self.cellContentView setMessage:message];
}

- (void)awakeFromNib
{
    // Initialization code
}

@end