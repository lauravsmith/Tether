//
//  FriendsListViewController.m
//  Tether
//
//  Created by Laura Smith on 12/11/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Friend.h"
#import "FriendsListViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#define BORDER_WIDTH 4.0
#define CELL_HEIGHT 60.0
#define NAME_LABEL_OFFSET_X 70.0
#define PROFILE_PICTURE_OFFSET_X 10.0
#define PROFILE_PICTURE_SIZE 50.0

@interface FriendsListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) UITableView * friendsTableView;
@property (retain, nonatomic) UITableViewController * friendsTableViewController;
@end

@implementation FriendsListViewController

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
	// Do any additional setup after loading the view.
    
    //set up friends going out table view
    self.friendsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.friendsTableView setSeparatorColor:[UIColor whiteColor]];
    [self.friendsTableView setBackgroundColor:UIColorFromRGB(0xD6D6D6)];
    [self.friendsTableView setDataSource:self];
    [self.friendsTableView setDelegate:self];
    self.friendsTableView.showsVerticalScrollIndicator = NO;
    
    [self.view addSubview:self.friendsTableView];
    
    self.friendsTableViewController = [[UITableViewController alloc] init];
    self.friendsTableViewController.tableView = self.friendsTableView;
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
        return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.friendsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    Friend *friend = [self.friendsArray objectAtIndex:indexPath.row];
    UILabel *friendNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(NAME_LABEL_OFFSET_X, 0, 300, 40)];
    friendNameLabel.text = friend.name;
    [cell addSubview:friendNameLabel];
    FBProfilePictureView *friendProfilePictureView = [[FBProfilePictureView alloc] initWithProfileID:(NSString *)friend.friendID pictureCropping:FBProfilePictureCroppingSquare];
    
    friendProfilePictureView.clipsToBounds = YES;
    friendProfilePictureView.frame = CGRectMake(PROFILE_PICTURE_OFFSET_X, (cell.frame.size.height - PROFILE_PICTURE_SIZE) / 2, PROFILE_PICTURE_SIZE, PROFILE_PICTURE_SIZE);
    friendProfilePictureView.layer.cornerRadius = 24.0;
    friendProfilePictureView.clipsToBounds = YES;
    [friendProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [friendProfilePictureView.layer setBorderWidth:BORDER_WIDTH];
    [cell addSubview:friendProfilePictureView];
    
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
