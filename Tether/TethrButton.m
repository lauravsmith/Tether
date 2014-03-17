//
//  TethrButton.m
//  Tether
//
//  Created by Laura Smith on 3/12/2014.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "TethrButton.h"

@interface TethrButton ()
@property(nonatomic, strong, readwrite) UIColor *normalColor;
@property(nonatomic, strong, readwrite) UIColor *highlightedColor;
@end

@implementation TethrButton

#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

#pragma mark Settings

- (void)setNormalColor:(UIColor *)normalColor {
    [self setBackgroundColor:normalColor];
    _normalColor = normalColor;
}

- (void)setHighlightedColor:(UIColor *)highlightedColor {
    _highlightedColor = highlightedColor;
}

-(void) setHighlighted:(BOOL)highlighted {
    
    if(highlighted) {
        self.backgroundColor = self.highlightedColor;
    } else {
        self.backgroundColor = self.normalColor;
    }
    [super setHighlighted:highlighted];
}

-(void) setSelected:(BOOL)selected {
    
    if(selected) {
        self.backgroundColor = self.highlightedColor;
    } else {
        self.backgroundColor = self.normalColor;
    }
    [super setSelected:selected];
}

@end
