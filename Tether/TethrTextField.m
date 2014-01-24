//
//  TethrTextField.m
//  Tether
//
//  Created by Laura Smith on 1/23/2014.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "TethrTextField.h"

@implementation TethrTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset( bounds , 10 , 0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset( bounds , 10 , 0);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
