//
//  TethrAlerView.m
//  Tether
//
//  Created by Laura Smith on 1/20/2014.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "TethrAlerView.h"

@implementation TethrAlerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithMessage:(NSString *)message dismissAfter:(NSTimeInterval)interval
{
    if ((self = [super init]))
    {
        UIView * customView = [[UIView alloc] init];
        [self addSubview:customView];
        [self performSelector:@selector(dismissAfterDelay) withObject:nil afterDelay:interval];
    }
    return self;
}

- (void)dismissAfterDelay
{
    [self dismissWithClickedButtonIndex:0 animated:YES];
}

@end
