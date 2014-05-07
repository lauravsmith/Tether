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

#import <TTTAttributedLabel.h>
#import <QuartzCore/QuartzCore.h>

#define MAX_LABEL_WIDTH 200.0
#define NAME_LABEL_OFFSET_X 20.0

@protocol MessageCellContentViewDelegate;

@interface MessageCellContentView : UIView

@property (nonatomic, weak) id<MessageCellContentViewDelegate> delegate;
@property (nonatomic, strong) Message *message;
@property (nonatomic, strong) MessageThread *thread;
@property (nonatomic, strong) UIImageView *dialog;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, assign) int showName;
@property (nonatomic, strong) UIButton *acceptButton;
@property (nonatomic, strong) UIButton *declineButton;

@end

@protocol MessageCellContentViewDelegate <NSObject>

-(void)tethrToInvite:(Invite*)invite;
-(void)declineInvite:(Invite*)invite fromMessage:(Message *)message;
-(void)openPlace:(Place*)place;

@end

@implementation MessageCellContentView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.messageLabel = [[UILabel alloc] init];
    }
    return self;
}

- (void)layoutSubviews {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    if (!self.message.userId || [self.message.userId isEqualToString:@""]) {
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
        
        if ([self.message.userName isEqualToString:sharedDataManager.name]) {
            self.message.content = [self.message.content stringByReplacingOccurrencesOfString:self.message.userName withString:@"You"];
        }
        self.messageLabel.text = self.message.content;
        [self.messageLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
        [self.messageLabel setFont:montserrat];
        NSDictionary *attributes = @{NSFontAttributeName: montserrat};
        CGRect rect = [self.messageLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - 20.0, 1000.0)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                        attributes:attributes
                                                           context:nil];
        
        self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.messageLabel.numberOfLines = 0;
        self.messageLabel.textAlignment = NSTextAlignmentCenter;
        self.messageLabel.frame = CGRectMake((self.frame.size.width - rect.size.width) / 2.0, 0.0, rect.size.width, rect.size.height);
        [self addSubview:self.messageLabel];
    } else {    
        if (self.showName && ![self.message.userId isEqualToString:sharedDataManager.facebookId]) {
            UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:12.0f];
            self.nameLabel = [[UILabel alloc] init];
            self.nameLabel.text = self.message.userName;
            [self.nameLabel setFont:montserratSmall];
            CGSize size = [self.nameLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratSmall}];
            self.nameLabel.frame = CGRectMake(NAME_LABEL_OFFSET_X - 5.0, 0.0, size.width, size.height);
            [self.nameLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
            [self addSubview:self.nameLabel];
        }
        
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
        self.messageLabel.text = self.message.content;
        [self.messageLabel setFont:montserrat];
        
        if (self.message.invite && [self.message.userId isEqualToString:sharedDataManager.facebookId]) {
            if (self.thread.isGroupMessage) {
                self.messageLabel.text = [NSString stringWithFormat:@"You sent an invite to %@", self.message.invite.place.name];
            } else {
                for (NSString *name in self.thread.participantNames) {
                    if (![name isEqualToString:sharedDataManager.name]) {
                        self.messageLabel.text = [NSString stringWithFormat:@"You invited %@ to %@", name, self.message.invite.place.name];
                    }
                }
            }
        }
        
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
            UIImage *bubble = [[UIImage imageNamed:@"RedSpeechBubble.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(30.0, 30.0, 69.0, 69.0) resizingMode:UIImageResizingModeTile];
            
            self.dialog = [[UIImageView alloc] initWithImage:bubble];
            self.dialog.frame = CGRectZero;
            
             self.dialog.frame = CGRectMake(self.frame.size.width - rect.size.width - NAME_LABEL_OFFSET_X - 20.0, 0.0, MIN(rect.size.width, MAX_LABEL_WIDTH)+ 40.0, rect.size.height + 36.0);
            
            self.messageLabel.frame = CGRectMake(20.0, 12.0, MIN(rect.size.width, MAX_LABEL_WIDTH), rect.size.height);
            [self.messageLabel setTextColor:[UIColor whiteColor]];
            
            [self.dialog addSubview:self.messageLabel];
            [self addSubview:self.dialog];
        } else {
            CGFloat yOrigin = 0.0;
            if (self.nameLabel) {
                yOrigin = 10.0;
            }
            UIImage *bubble = [[UIImage imageNamed:@"GreySpeechBubble.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(34.0, 50.0, 45.0, 23.0) resizingMode:UIImageResizingModeTile];
            self.dialog = [[UIImageView alloc] initWithImage:bubble];
            self.dialog.frame = CGRectZero;
            
            self.dialog.frame = CGRectMake(NAME_LABEL_OFFSET_X - 20.0, yOrigin, MIN(rect.size.width, MAX_LABEL_WIDTH) + 40.0, rect.size.height + 36.0);
            
            self.messageLabel.frame = CGRectMake(20.0, 12.0, MIN(rect.size.width, MAX_LABEL_WIDTH), rect.size.height);
            [self.messageLabel setTextColor:[UIColor blackColor]];
            [self.dialog addSubview:self.messageLabel];
            [self addSubview:self.dialog];
        }
        
        if (self.message.invite) {
            if (![self.message.userId isEqualToString:sharedDataManager.facebookId]) {
                Datastore *sharedDataManager = [Datastore sharedDataManager];
                NSMutableSet *acceptanceSet = self.message.invite.acceptances;
                if ((!acceptanceSet || ![acceptanceSet containsObject:sharedDataManager.facebookId]) && (!self.message.invite.declines || ![self.message.invite.declines containsObject:sharedDataManager.facebookId])) {
                    self.acceptButton = [[UIButton alloc] initWithFrame:CGRectMake(40.0, self.dialog.frame.size.height - 10.0, 41.0, 38.0)];
                    [self.acceptButton addTarget:self action:@selector(tethrToInvite:) forControlEvents:UIControlEventTouchUpInside];
                    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0, 0.0, 21.0, 38.0)];
                    [imageView setImage:[UIImage imageNamed:@"PinIcon"]];
                    [self.acceptButton addSubview:imageView];
                    [self addSubview:self.acceptButton];
                    
                    [[self.acceptButton layer] setBorderWidth:2.0f];
                    [[self.acceptButton layer] setCornerRadius:20.0];
                    [[self.acceptButton layer] setBorderColor:UIColorFromRGB(0xc8c8c8).CGColor];
                    
                    self.declineButton = [[UIButton alloc] initWithFrame:CGRectMake(100.0, self.dialog.frame.size.height - 10.0, 41.0, 38.0)];
                    [self.declineButton addTarget:self action:@selector(declineInvite:) forControlEvents:UIControlEventTouchUpInside];
                    [self addSubview:self.declineButton];
                    
                    [[self.declineButton layer] setBorderWidth:2.0f];
                    [[self.declineButton layer] setCornerRadius:20.0];
                    [[self.declineButton layer] setBorderColor:UIColorFromRGB(0xc8c8c8).CGColor];
                }
            } else {
                [self.acceptButton removeFromSuperview];
                [self.declineButton removeFromSuperview];
            }
            self.dialog.userInteractionEnabled = YES;
            UITapGestureRecognizer *tapGesture =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openInvitePlace)];
            [self.dialog addGestureRecognizer:tapGesture];
            
            NSMutableAttributedString* attrStr = [[NSMutableAttributedString alloc] initWithString:self.messageLabel.text];
            [attrStr addAttribute:(NSString*)kCTUnderlineStyleAttributeName
                            value:[NSNumber numberWithInt:kCTUnderlineStyleSingle]
                            range:[self.messageLabel.text rangeOfString:self.message.invite.place.name]];
            self.messageLabel.attributedText = attrStr;
        }
    }
}

-(void)openInvitePlace {
    if ([self.delegate respondsToSelector:@selector(openPlace:)]) {
        [self.delegate openPlace:self.message.invite.place];
    }
}

- (void)setMessage:(Message *)message {
    _message = message;
    
    [self setNeedsLayout];
}

-(IBAction)tethrToInvite:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSMutableSet *acceptanceSet = self.message.invite.acceptances;
    if (!acceptanceSet) {
        acceptanceSet = [[NSMutableSet alloc] init];
    }
    [acceptanceSet addObject:sharedDataManager.facebookId];
    self.message.invite.acceptances = acceptanceSet;
    
    [self.message.invite.inviteObject setObject:[self.message.invite.acceptances allObjects]  forKey:@"acceptances"];
    [self.message.invite.inviteObject saveInBackground];
    
    if ([self.delegate respondsToSelector:@selector(tethrToInvite:)]) {
        [self.delegate tethrToInvite:self.message.invite];
    }
}

-(IBAction)declineInvite:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSMutableSet *declineSet = self.message.invite.declines;
    if (!declineSet) {
        declineSet = [[NSMutableSet alloc] init];
    }
    [declineSet addObject:sharedDataManager.facebookId];
    self.message.invite.declines = declineSet;
    
    [self.message.invite.inviteObject setObject:[self.message.invite.declines allObjects]  forKey:@"declines"];
    [self.message.invite.inviteObject saveInBackground];
    
    if ([self.delegate respondsToSelector:@selector(declineInvite:fromMessage:)]) {
        [self.delegate declineInvite:self.message.invite fromMessage:self.message];
    }
}

@end

@interface MessageCell() <MessageCellContentViewDelegate>
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
        _cellContentView.delegate = self;
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

- (void)setThread:(MessageThread *)thread {
    _thread = thread;
    
    [self.cellContentView setThread:thread];
}

-(void)tethrToInvite:(Invite *)invite {
    if ([self.delegate respondsToSelector:@selector(tethrToInvite:)]) {
        [self.delegate tethrToInvite:invite];
    }
}

-(void)declineInvite:(Invite *)invite fromMessage:(Message *)message{
    if ([self.delegate respondsToSelector:@selector(declineInvite:fromMessage:)]) {
        [self.delegate declineInvite:self.message.invite fromMessage:message];
    }
}

-(void)openPlace:(Place *)place {
    if ([self.delegate respondsToSelector:@selector(openPlace:)]) {
        [self.delegate openPlace:place];
    }
}

- (void)awakeFromNib
{
    // Initialization code
}

@end