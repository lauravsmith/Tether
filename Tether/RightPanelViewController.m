//
//  RightPanelViewController.m
//  Tether
//
//  Created by Laura Smith on 12/12/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Constants.h"
#import "Datastore.h"
#import "Notification.h"
#import "NotificationCell.h"
#import "RightPanelViewController.h"

#import <Parse/Parse.h>

#define CELL_HEIGHT 70.0
#define PADDING 10.0
#define PANEL_WIDTH 45.0
#define PROFILE_PICTURE_SIZE 28.0
#define SPINNER_SIZE 30.0
#define STATUS_BAR_HEIGHT 20.0

@interface RightPanelViewController () <NotificationCellDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *notificationsTableView;
@property (nonatomic, strong) UITableViewController *notificationsTableViewController;
@property (retain, nonatomic) UIRefreshControl * refreshControl;
@property (retain, nonatomic) UIView * deleteConfirmationView;
@property (retain, nonatomic) UILabel * deleteConfirmationLabel;
@property (retain, nonatomic) UIActivityIndicatorView * activityIndicatorView;
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
                sharedDataManager.bestFriendSet = [[NSMutableSet alloc] init];
                self.notificationsArray = [[NSMutableArray alloc] init];
                for (PFObject *invitation in objects) {
                    Notification *notification = [[Notification alloc] init];
                    
                    notification.parseObject = invitation;
                    
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
                        }
                    }
                    
                    if ([invitation objectForKey:@"placeName"]) {
                        notification.placeName = [invitation objectForKey:@"placeName"];
                    }
                    
                    if ([invitation objectForKey:@"city"]) {
                        notification.city = [invitation objectForKey:@"city"];
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
                    if ([notification.type isEqualToString:@"invitation"] || [notification.type isEqualToString:@"acceptance"] || [notification.type isEqualToString:@"status"] || [notification.type isEqualToString:@"newUser"] || [notification.type isEqualToString:@"receipt"]) {
                         [self.notificationsArray addObject:notification];
                    }

                    if ([notification.type isEqualToString:@"invitation"]) {
                        [sharedDataManager.bestFriendSet addObject:notification.sender.friendID];
                        if ([today compare:notification.time] == NSOrderedAscending) {
                            [sharedDataManager.todaysNotificationsArray addObject:notification];
                        }
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
    if ([hour intValue] > 5) {
        [components setHour:5.0];
        return [calendar dateFromComponents:components];
    } else { // if before 6am, start from yesterday's date
        NSDateComponents* deltaComps = [[NSDateComponents alloc] init];
        [deltaComps setDay:-1.0];
        [components setHour:5.0];
        return [calendar dateByAddingComponents:deltaComps toDate:[calendar dateFromComponents:components] options:0];
    }
}

-(void)confirmDelete {
    self.deleteConfirmationView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 200.0) / 2.0, (self.view.frame.size.height - 100.0) / 2.0, 200.0, 100.0)];
    [self.deleteConfirmationView setBackgroundColor:[UIColor whiteColor]];
    self.deleteConfirmationView.alpha = 0.8;
    self.deleteConfirmationView.layer.cornerRadius = 10.0;
    
    self.deleteConfirmationLabel = [[UILabel alloc] init];
    self.deleteConfirmationLabel.text = @"Deleting notifications...";
    self.deleteConfirmationLabel.textColor = UIColorFromRGB(0x8e0528);
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    self.deleteConfirmationLabel.font = montserrat;
    CGSize size = [self.deleteConfirmationLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.deleteConfirmationLabel.frame = CGRectMake((self.deleteConfirmationView.frame.size.width - size.width) / 2.0, (self.deleteConfirmationView.frame.size.height - size.height) / 2.0, size.width, size.height);
    [self.deleteConfirmationView addSubview:self.deleteConfirmationLabel];
    
    [self.view addSubview:self.deleteConfirmationView];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.deleteConfirmationView.frame.size.width - SPINNER_SIZE) / 2.0, self.deleteConfirmationLabel.frame.origin.y + self.deleteConfirmationLabel.frame.size.height + 2.0, SPINNER_SIZE, SPINNER_SIZE)];
    self.activityIndicatorView.color = UIColorFromRGB(0x8e0528);
    [self.deleteConfirmationView addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
    
    self.view.userInteractionEnabled = NO;
    [self performSelector:@selector(dismissConfirmation) withObject:Nil afterDelay:1.0];
}

-(void)dismissConfirmation {
    [self.activityIndicatorView stopAnimating];
    self.deleteConfirmationLabel.text = @"Deleted";
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:16.0f];
    self.deleteConfirmationLabel.font = montserrat;
    CGSize size = [self.deleteConfirmationLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.deleteConfirmationLabel.frame = CGRectMake((self.deleteConfirmationView.frame.size.width - size.width) / 2.0, (self.deleteConfirmationView.frame.size.height - size.height) / 2.0, size.width, size.height);
    
    [UIView animateWithDuration:0.2
                          delay:0.5
                        options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                            self.deleteConfirmationView.alpha = 0.2;
                        } completion:^(BOOL finished) {
                            [self.deleteConfirmationView removeFromSuperview];
                            self.view.userInteractionEnabled = YES;
                        }];
}

#pragma mark NotificationCellDelegate Methods

-(void)goToPlace:(id)placeId {
    
    if ([self.delegate respondsToSelector:@selector(openPageForPlaceWithId:)]) {
        [self.delegate openPageForPlaceWithId:placeId];
    }
}

-(void)deleteNotifications {
    for (Notification *notification in self.notificationsArray) {
        [notification.parseObject deleteInBackground];
    }

    [self confirmDelete];
    [self performSelector:@selector(refresh) withObject:self.refreshControl afterDelay:2.0f];
}

-(void)userChangedLocationToCityName:(NSString*)city {
    if([self.delegate respondsToSelector:@selector(userChangedLocationToCityName:)]) {
        [self.delegate userChangedLocationToCityName:city];
    }
}

#pragma mark UITableViewDataSource Methods

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.notificationsArray count]) {
        return CELL_HEIGHT;
    } else {
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
        NotificationCell *cell = (NotificationCell*)[self tableView:tableView cellForRowAtIndexPath:indexPath];
        CGSize sizeTime = [cell.timeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
        
        CGRect rect = [cell.text boundingRectWithSize:CGSizeMake(200.0, 500.f)
                                              options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                              context:nil];
        
        return MAX(CELL_HEIGHT, rect.size.height + sizeTime.height + 1.0 + PADDING);
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.notificationsArray count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.notificationsArray count]) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width - PANEL_WIDTH, CELL_HEIGHT)];
        UILabel *clearNotificationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
        clearNotificationsLabel.text = @"Clear activity feed";
        if ([self.notificationsArray count] == 0) {
            clearNotificationsLabel.text = @"Activity feed";
        }
        
        [clearNotificationsLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:20.0f];
        [clearNotificationsLabel setFont:montserrat];
        CGSize size = [clearNotificationsLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
        clearNotificationsLabel.frame = CGRectMake((self.view.frame.size.width - PANEL_WIDTH - size.width) / 2.0, (CELL_HEIGHT - size.height) / 2.0, size.width, size.height);
        clearNotificationsLabel.textAlignment = NSTextAlignmentCenter;
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell addSubview:clearNotificationsLabel];
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        return cell;
    } else {
        NotificationCell *cell = [[NotificationCell alloc] init];
        cell.delegate = self;
        
        if ([self.notificationsArray count] > 0) {
            cell.notification = [self.notificationsArray objectAtIndex:indexPath.row];
            [cell loadNotification];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, STATUS_BAR_HEIGHT)];
    return view;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.notificationsArray count] && [self.notificationsArray count] > 0) {
        [self deleteNotifications];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
