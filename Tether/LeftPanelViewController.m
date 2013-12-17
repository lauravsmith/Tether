//
//  LeftPanelViewController.m
//  Tether
//
//  Created by Laura Smith on 11/20/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "FriendCell.h"
#import "LeftPanelViewController.h"

#define NAME_OFFSET_X 80.0
#define NAME_OFFSET_Y 20.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define CELL_HEIGHT 70
#define SECOND_TABLE_OFFSET_Y 350.0
#define TABLE_HEIGHT 400.0
#define PANEL_WIDTH 60
#define PADDING 10
#define PROFILE_PICTURE_BORDER_WIDTH 4.0

@interface LeftPanelViewController ()<UITableViewDelegate, UITableViewDataSource, FriendCellDelegate>

@property (nonatomic, strong) UITableView *friendsGoingOutTableView;
@property (nonatomic, strong) UITableViewController *friendsGoingOutTableViewController;
@property (nonatomic, strong) UITableView *friendsNotGoingOutTableView;
@property (nonatomic, strong) UITableViewController *friendsNotGoingOutTableViewController;
@property (nonatomic, strong) UITableView *friendsUndecidedTableView;
@property (nonatomic, strong) UITableViewController *friendsUndecidedTableViewController;
@property (retain, nonatomic) UIScrollView * scrollView;

@end

@implementation LeftPanelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)loadView {
    CGRect fullScreenRect=[[UIScreen mainScreen] applicationFrame];
    self.scrollView=[[UIScrollView alloc] initWithFrame:fullScreenRect];
    self.scrollView.scrollEnabled = YES;
    [self.scrollView setBackgroundColor:[UIColor whiteColor]];
    [self.scrollView setBounces:NO];
    self.view= _scrollView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView.contentOffset = CGPointMake(0, 0);
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    //set up friends going out table view
    self.friendsGoingOutTableView = [[UITableView alloc] init];
    [self.friendsGoingOutTableView setSeparatorColor:[UIColor whiteColor]];
    [self.friendsGoingOutTableView setBackgroundColor:UIColorFromRGB(0xD6D6D6)];
    [self.friendsGoingOutTableView setDataSource:self];
    [self.friendsGoingOutTableView setDelegate:self];
    [self.friendsGoingOutTableView setBounces:NO];

    [self.view addSubview:self.friendsGoingOutTableView];
    
    self.friendsGoingOutTableViewController = [[UITableViewController alloc] init];
    self.friendsGoingOutTableViewController.tableView = self.friendsGoingOutTableView;
    [self.friendsGoingOutTableView reloadData];
    
    //set up friends not going out table view
    self.friendsNotGoingOutTableView = [[UITableView alloc] init];
    [self.friendsNotGoingOutTableView setSeparatorColor:[UIColor whiteColor]];
    [self.friendsNotGoingOutTableView setBackgroundColor:UIColorFromRGB(0xD6D6D6)];
    [self.friendsNotGoingOutTableView setDataSource:self];
    [self.friendsNotGoingOutTableView setDelegate:self];
    [self.friendsNotGoingOutTableView setBounces:NO];
    
    [self.view addSubview:self.friendsNotGoingOutTableView];
    
    self.friendsNotGoingOutTableViewController = [[UITableViewController alloc] init];
    self.friendsNotGoingOutTableViewController.tableView = self.friendsNotGoingOutTableView;
    [self.friendsNotGoingOutTableView reloadData];
    
    //set up friends not going out table view
    self.friendsUndecidedTableView = [[UITableView alloc] init];
    [self.friendsUndecidedTableView setSeparatorColor:[UIColor whiteColor]];
    [self.friendsUndecidedTableView setBackgroundColor:UIColorFromRGB(0xD6D6D6)];
    [self.friendsUndecidedTableView setDataSource:self];
    [self.friendsUndecidedTableView setDelegate:self];
    [self.friendsUndecidedTableView setBounces:NO];
    
    [self.view addSubview:self.friendsUndecidedTableView];
    
    self.friendsUndecidedTableViewController = [[UITableViewController alloc] init];
    self.friendsUndecidedTableViewController.tableView = self.friendsUndecidedTableView;
    [self.friendsUndecidedTableView reloadData];
}

-(void)updateFriendsList {
    [self.friendsGoingOutTableView reloadData];
    [self.friendsNotGoingOutTableView reloadData];
    [self.friendsUndecidedTableView reloadData];
    [self resizeTableViews];
}

-(void)resizeTableViews {
    self.friendsGoingOutTableView.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, MIN(TABLE_HEIGHT, self.friendsGoingOutTableView.contentSize.height));
    NSLog(@"Resizing tables");
    
    self.friendsNotGoingOutTableView.frame = CGRectMake(0, self.friendsGoingOutTableView.frame.origin.y + self.friendsGoingOutTableView.frame.size.height, self.view.frame.size.width, MIN(TABLE_HEIGHT, self.friendsNotGoingOutTableView.contentSize.height));
    
    self.friendsUndecidedTableView.frame = CGRectMake(0, self.friendsNotGoingOutTableView.frame.origin.y + self.friendsNotGoingOutTableView.frame.size.height, self.view.frame.size.width, MIN(MAX(TABLE_HEIGHT, self.view.frame.size.height - self.friendsNotGoingOutTableView.frame.size.height - self.friendsGoingOutTableView.frame.size.height), self.friendsUndecidedTableView.contentSize.height));
}

#pragma mark UITableViewDataSource Methods

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70.0)];
    [header setBackgroundColor:[UIColor whiteColor]];
    UILabel *goingOutLabel = [[UILabel alloc] initWithFrame:header.frame];
    UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 0, 50.0, 30.0)];
    UIFont *champagneBold = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:18.0f];
    goingOutLabel.font = champagneBold;
   if (tableView == self.friendsGoingOutTableView) {
       goingOutLabel.text = @"Going Out";
       countLabel.text = [NSString stringWithFormat:@"(%lu)",(unsigned long)[sharedDataManager.tetherFriendsGoingOut count]];
   } else if (tableView == self.friendsNotGoingOutTableView) {
       goingOutLabel.text = @"Not Going Out";
       countLabel.text = [NSString stringWithFormat:@"(%lu)",(unsigned long)[sharedDataManager.tetherFriendsNotGoingOut count]];
   } else {
       goingOutLabel.text = @"Undecided";
       countLabel.text = [NSString stringWithFormat:@"(%lu)",(unsigned long)[sharedDataManager.tetherFriendsUndecided count]];
   }
    CGSize textLabelSize = [goingOutLabel.text sizeWithAttributes:@{NSFontAttributeName: champagneBold}];
    CGSize numberLabelSize = [countLabel.text sizeWithAttributes:@{NSFontAttributeName: champagneBold}];
    goingOutLabel.frame = CGRectMake(10.0, (header.frame.size.height - textLabelSize.height) / 2.0 , textLabelSize.width, textLabelSize.height);
    countLabel.frame = CGRectMake(goingOutLabel.frame.origin.x + goingOutLabel.frame.size.width + PADDING, goingOutLabel.frame.origin.y, numberLabelSize.width, numberLabelSize.height);
    [header addSubview:goingOutLabel];
    [header addSubview:countLabel];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (tableView == self.friendsGoingOutTableView) {
        return [sharedDataManager.tetherFriendsGoingOut count];
    } else if (tableView == self.friendsNotGoingOutTableView) {
        return [sharedDataManager.tetherFriendsNotGoingOut count];
    } else {
        return [sharedDataManager.tetherFriendsUndecided count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    FriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[FriendCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.delegate = self;
    }
    
   if (tableView == self.friendsGoingOutTableView) {
       [cell setFriend:[sharedDataManager.tetherFriendsGoingOut objectAtIndex:indexPath.row]];
   } else if (tableView == self.friendsNotGoingOutTableView) {
       [cell setFriend:[sharedDataManager.tetherFriendsNotGoingOut objectAtIndex:indexPath.row]];
   } else {
       [cell setFriend:[sharedDataManager.tetherFriendsUndecided objectAtIndex:indexPath.row]];
   }
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark FriendCellDelegate methods

-(void)goToPlaceInListView:(id)placeId {
    if ([self.delegate respondsToSelector:@selector(goToPlaceInListView:)]) {
        [self.delegate goToPlaceInListView:placeId];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
