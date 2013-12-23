//
//  MainViewController.h
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "ViewController.h"

@interface MainViewController : ViewController
@property (strong, nonatomic) NSMutableDictionary *friendsDictionary;
-(void)pollDatabase;
- (void)movePanelLeft;
@end
