//
//  TethrButton.h
//  Tether
//
//  Created by Laura Smith on 3/12/2014.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TethrButton : UIButton

@property (nonatomic, strong, readonly) UIColor *normalColor;
@property (nonatomic, strong, readonly) UIColor *highlightedColor;

- (void)setNormalColor:(UIColor *)normalColor;
- (void)setHighlightedColor:(UIColor *)highlightedColor;

@end
