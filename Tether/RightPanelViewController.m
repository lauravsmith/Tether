//
//  RightPanelViewController.m
//  Tether
//
//  Created by Laura Smith on 12/12/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Constants.h"
#import "Datastore.h"
#import "Notification.h"
#import "NotificationCell.h"
#import "RightPanelViewController.h"

#import <Parse/Parse.h>

#define CELL_HEIGHT 80.0
#define PANEL_WIDTH 60.0
#define STATUS_BAR_HEIGHT 20.0

@interface RightPanelViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *notificationsTableView;
@property (nonatomic, strong) UITableViewController *notificationsTableViewController;
@property (retain, nonatomic) UIRefreshControl * refreshControl;
@end

@implementation RightPanelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.notificationsArray = [[NSMutableArray alloc] init];
        [self.view setAlpha:0.8];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *backgroundImage = [UIImage imageNamed:@"BlackTexture"];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:backgroundImageView];
    
    self.notificationsTableView = [[UITableView alloc] initWithFrame:CGRectMake(PANEL_WIDTH, 0, self.view.frame.size.width - PANEL_WIDTH, self.view.frame.size.height)];
    [self.notificationsTableView setDataSource:self];
    [self.notificationsTableView setDelegate:self];
    [self.notificationsTableView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.notificationsTableView];
    self.notificationsTableView.contentOffset = CGPointMake(0.0, -20.0);
    self.notificationsTableView.showsVerticalScrollIndicator = NO;
    
    self.notificationsTableViewController = [[UITableViewController alloc] init];
    self.notificationsTableViewController.tableView = self.notificationsTableView;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [self.notificationsTableView addSubview:self.refreshControl];
    self.notificationsTableViewController.refreshControl = self.refreshControl;
}

-(void)refresh {
    [self.refreshControl beginRefreshing];
    [self performSelector:@selector(endRefresh:) withObject:self.refreshControl afterDelay:1.0f];
    [self loadNotifications];
}

- (void)endRefresh:(UIRefreshControl *)refresh
{
    [refresh performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:NO];
}

-(void)loadNotifications {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    NSLog(@"PARSE QUERY: POLLING NOTIFICATIONS");
    
    PFQuery *query = [PFQuery queryWithClassName:kNotificationClassKey];
    
    if (sharedDataManager.facebookId) {
        NSDate *today = [self getStartTime];
        [query whereKey:@"recipientID" equalTo:sharedDataManager.facebookId];
        query.cachePolicy = kPFCachePolicyNetworkElseCache;
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                sharedDataManager.todaysNotificationsArray = [[NSMutableArray alloc] init];
                self.notificationsArray = [[NSMutableArray alloc] init];
                for (PFObject *invitation in objects) {
                    Notification *notification = [[Notification alloc] init];
                    if ([invitation objectForKey:kNotificationTypeKey]) {
                        notification.type = [invitation objectForKey:kNotificationTypeKey];
                    }
                    
                    if ([invitation objectForKey:@"messageHeader"]) {
                        notification.messageHeader = [invitation objectForKey:@"messageHeader"];
                    }
                    
                    if ([invitation objectForKey:@"message"]) {
                        notification.message = [invitation objectForKey:@"message"];
                    }
                    
                    if ([invitation objectForKey:@"sender"]) {
                        NSString *friendId =[invitation objectForKey:@"sender"];
                        Friend *friend = [[Friend alloc] init];
                        if ([sharedDataManager.tetherFriendsDictionary objectForKey:friendId]) {
                            friend = [sharedDataManager.tetherFriendsDictionary objectForKey:friendId];
                            notification.sender = friend;
                        }
                    }
                    
                    if (invitation.createdAt) {
                        notification.time = invitation.createdAt;
                    }
                    
                    if ([invitation objectForKey:@"placeId"]) {
                        notification.placeId = [invitation objectForKey:@"placeId"];
                        Place *place = [[Place alloc] init];
                        if ([sharedDataManager.placesDictionary objectForKey:notification.placeId]) {
                            place = [sharedDataManager.placesDictionary objectForKey:notification.placeId];
                            notification.place = place;
                            notification.placeName = place.name;
                        } else if ([invitation objectForKey:@"placeName"]) {
                            notification.placeName = [invitation objectForKey:@"placeName"];
                        }
                    }
                    
                    if ([invitation objectForKey:@"allRecipients"]) {
                        NSMutableArray *recipientIds = [invitation objectForKey:@"allRecipients"];
                        notification.allRecipients = [[NSMutableArray alloc] init];
                        for (id recipientId in recipientIds) {
                            if (![recipientId isEqualToString:sharedDataManager.facebookId] &&
                                [sharedDataManager.tetherFriendsDictionary objectForKey:recipientId]) {
                                Friend *friend = [[Friend alloc] init];
                                friend = [sharedDataManager.tetherFriendsDictionary objectForKey:recipientId];
                                [notification.allRecipients addObject:friend];
                            }
                        }
                    }
                    [self.notificationsArray addObject:notification];

                    if ([notification.type isEqualToString:@"invitation"] && [today compare:notification.time] == NSOrderedAscending) {
                        [sharedDataManager.todaysNotificationsArray addObject:notification];
                    }
                }
            }
            NSSortDescriptor *timeDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO];
            [self.notificationsArray sortUsingDescriptors:[NSArray arrayWithObjects:timeDescriptor, nil]];
            [self.notificationsTableView reloadData];
        }];
    }
}

-(NSDate*)getStartTime{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH"];
    NSDate *now = [NSDate date];
    NSString *hour = [formatter stringFromDate:[NSDate date]];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:now];
    
    // if after 6am, start from today's date
    if ([hour intValue] > 6) {
        [components setHour:6.0];
        return [calendar dateFromComponents:components];
    } else { // if before 6am, start from yesterday's date
        NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
        [deltaComps setDay:-1.0];
        [components setHour:6.0];
        return [calendar dateByAddingComponents:deltaComps toDate:[calendar dateFromComponents:components] options:0];
    }
}


#pragma mark UITableViewDataSource Methods

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
    NotificationCell *cell = (NotificationCell*)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    CGSize size = [cell.messageHeaderLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    CGSize sizeTime = [cell.timeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    return MAX(CELL_HEIGHT, size.height + sizeTime.height);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.notificationsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NotificationCell *cell = [[NotificationCell alloc] init];
    
    if ([self.notificationsArray count] > 0) {
        cell.notification = [self.notificationsArray objectAtIndex:indexPath.row];
        [cell loadNotification];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIImage *backgroundImage = [UIImage imageNamed:@"BlackTexture"];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, STATUS_BAR_HEIGHT);
    [self.view addSubview:backgroundImageView];
    return backgroundImageView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
