//
//  MessageViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-04-25.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "Message.h"
#import "MessageCell.h"
#import "MessageThread.h"
#import "MessageViewController.h"

#define BOTTOM_BAR_HEIGHT 50.0
#define MIN_CELL_HEIGHT 60.0
#define MESSAGE_FIELD_HEIGHT 25.0
#define MESSAGE_FIELD_WIDTH 200.0
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

@interface MessageViewController () <UITableViewDataSource, UITableViewDelegate>

@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UILabel * nameLabel;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UIView * bottomBar;
@property (retain, nonatomic) UITextView * textView;
@property (nonatomic, strong) UITableView *messagesTableView;
@property (nonatomic, strong) UITableViewController *messagesTableViewController;

@end

@implementation MessageViewController

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
    
    [self.view setBackgroundColor:[UIColor whiteColor]];

    // top bar setup
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, self.view.frame.size.width,TOP_BAR_HEIGHT)];
    self.topBar.layer.backgroundColor = UIColorFromRGB(0x8e0528).CGColor;
    [self.view addSubview:self.topBar];
    
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, (TOP_BAR_HEIGHT - 31.0 + STATUS_BAR_HEIGHT) / 2.0, 32.0, 31.0)];
    [self.backButton setImageEdgeInsets:UIEdgeInsetsMake(10.0, 5.0, 10.0, 20.0)];
    [self.backButton setImage:triangleImage forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(closeMessageView) forControlEvents:UIControlEventTouchDown];
    [self.topBar addSubview:self.backButton];
    
    // name labels setup
    UIFont *montserratBold = [UIFont fontWithName:@"Montserrat-Bold" size:14.0f];
    NSString *names = @"";
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    for (NSString *friendName in self.thread.participantNames) {
        if (![friendName isEqualToString:sharedDataManager.name]) {
            if ([names isEqualToString:@""]) {
                names = friendName;
            } else {
                names = [NSString stringWithFormat:@"%@, %@", names,friendName];
            }
        }
    }
    
    self.nameLabel = [[UILabel alloc] init];
    [self.nameLabel setTextColor:[UIColor whiteColor]];
    self.nameLabel.font = montserratBold;
    [self.nameLabel setText:names];
    CGSize size = [self.nameLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratBold}];
    self.nameLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, (TOP_BAR_HEIGHT - size.height + STATUS_BAR_HEIGHT) / 2.0, size.width, size.height);
    [self.topBar addSubview:self.nameLabel];
    
    // bottom bar setup
    self.bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - BOTTOM_BAR_HEIGHT, self.view.frame.size.width,BOTTOM_BAR_HEIGHT)];
    self.bottomBar.layer.backgroundColor = UIColorFromRGB(0xf8f8f8).CGColor;
    [self.view addSubview:self.bottomBar];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake((self.bottomBar.frame.size.width - MESSAGE_FIELD_WIDTH) / 2.0,(self.bottomBar.frame.size.height - MESSAGE_FIELD_HEIGHT) / 2.0, MESSAGE_FIELD_WIDTH, MESSAGE_FIELD_HEIGHT)];
    [self.bottomBar addSubview:self.textView];
    
    self.messagesArray = [[NSMutableArray alloc] init];
    
    for (id key in self.thread.messages) {
        Message *message = [self.thread.messages objectForKey:key];
        [self.messagesArray addObject:message];
    }
    
    NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    [self.messagesArray sortUsingDescriptors:[NSArray arrayWithObjects:dateDescriptor, nil]];
    
    self.messagesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT)];
    [self.messagesTableView setDataSource:self];
    [self.messagesTableView setDelegate:self];
    [self.messagesTableView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.messagesTableView];
    self.messagesTableView.showsVerticalScrollIndicator = NO;
    
    self.messagesTableViewController = [[UITableViewController alloc] init];
    self.messagesTableViewController.tableView = self.messagesTableView;
    [self.messagesTableView reloadData];
}

-(void)closeMessageView {
    if ([self.delegate respondsToSelector:@selector(closeMessageView)]) {
        [self.delegate closeMessageView];
    }
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return MIN_CELL_HEIGHT;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.messagesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell *cell = [[MessageCell alloc] init];
    [cell setMessage:[self.messagesArray objectAtIndex:indexPath.row]];
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
