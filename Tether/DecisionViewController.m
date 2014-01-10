//
//  DecisionViewController.m
//  Tether
//
//  Created by Laura Smith on 11/24/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "DecisionViewController.h"
#import "CenterViewController.h"

@interface DecisionViewController ()

@end

@implementation DecisionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILabel *questionLabel = [[UILabel alloc] init];
    questionLabel.text = @"Are you going out?";
    questionLabel.textColor = [UIColor whiteColor];
    UIFont *champagne = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:25];
    questionLabel.font = champagne;
    CGSize size = [questionLabel.text sizeWithAttributes:@{NSFontAttributeName:champagne}];
    questionLabel.frame = CGRectMake((self.view.frame.size.width - size.width)/ 2, 100.0, size.width, size.height);
    [self.view addSubview:questionLabel];
    
    UIButton *yesButton = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 100.0)/ 2, 200.0, 100.0, 50.0)];
    champagne = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:45];
    yesButton.titleLabel.font = champagne;
    [yesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [yesButton setTitle:@"YES" forState:UIControlStateNormal];
    [yesButton addTarget:self action:@selector(handleYesButton:) forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview:yesButton];
    
    UIButton *noButton = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 100.0)/ 2, 300.0, 100.0, 50.0)];
    noButton.titleLabel.font = champagne;
    [noButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [noButton setTitle:@"NO" forState:UIControlStateNormal];
    [noButton addTarget:self action:@selector(handleNoButton:) forControlEvents:UIControlEventTouchDown];
    
    [self.view addSubview:noButton];
    
    self.view.backgroundColor = UIColorFromRGB(0x8e0528);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)handleYesButton:(id)sender{
    if ([self.delegate respondsToSelector:@selector(handleChoice:)]) {
        [self.delegate handleChoice:YES];
    }
}

-(IBAction)handleNoButton:(id)sender{
    if ([self.delegate respondsToSelector:@selector(handleChoice:)]) {
        [self.delegate handleChoice:NO];
    }
}

@end
