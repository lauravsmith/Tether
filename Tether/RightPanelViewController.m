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
#import "MessageThread.h"
#import "MessageThreadCell.h"
#import "Notification.h"
#import "NotificationCell.h"
#import "RightPanelViewController.h"

#import <Parse/Parse.h>

#define CELL_HEIGHT 80.0
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
@property (retain, nonatomic) NSMutableDictionary * messageThreadDictionary;
@property (retain, nonatomic) UIActivityIndicatorView * activityIndicatorView;
@end

@implementation RightPanelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.notificationsArray = [[NSMutableArray alloc] init];
        self.messageThreadDictionary = [[NSMutableDictionary alloc] init];
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
    [self.notificationsTableView setBackgroundView:backgroundImageView];
    [self.view addSubview:self.notificationsTableView];
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
//    [self loadNotifications];
}

- (void)endRefresh:(UIRefreshControl *)refresh
{
    [refresh performSelectorOnMainThread:@selector(endRefreshing) withObject:nil waitUntilDone:NO];
}

-(void)loadNotifications {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    PFQuery *query = [PFQuery queryWithClassName:@"MessageParticipant"];
    [query whereKey:@"facebookId" equalTo:sharedDataManager.facebookId];
    [query includeKey:@"threadId"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *participants, NSError *error) {
        if (!error) {
            for (PFObject *participant in participants) {
                // This does not require a network access.
                PFObject *threadObject = [participant objectForKey:@"threadId"];
                NSLog(@"recent message: %@", [threadObject objectForKey:@"recentMessage"]);
                
                MessageThread *thread = [[MessageThread alloc] init];
                thread.threadId = threadObject.objectId;
                thread.recentMessageDate = threadObject.updatedAt;
                thread.recentMessage = [threadObject objectForKey:@"recentMessage"];
                thread.participantIds = [NSMutableSet setWithArray:[threadObject objectForKey:@"participantIds"]];
                thread.participantNames = [NSMutableSet setWithArray:[threadObject objectForKey:@"participantNames"]];
                
                [self.messageThreadDictionary setObject:thread forKey:thread.threadId];
            }
            
            for(id key in self.messageThreadDictionary) {
                [self.notificationsArray addObject:[self.messageThreadDictionary objectForKey:key]];
            }
            
            NSSortDescriptor *dateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"recentMessageDate" ascending:NO];
            [self.notificationsArray sortUsingDescriptors:[NSArray arrayWithObjects:dateDescriptor, nil]];
            
            [self.notificationsTableView reloadData];
            
            // TODO: message thread dictionary to array -> sory by date, use Message Thread cells
        }
    }];
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
    return CELL_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.notificationsArray count]) {
        return CELL_HEIGHT;
    } else {
//        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:12.0f];
//        NotificationCell *cell = (NotificationCell*)[self tableView:tableView cellForRowAtIndexPath:indexPath];
//        CGSize sizeTime = [cell.timeLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
//        
//        CGRect rect = [cell.text boundingRectWithSize:CGSizeMake(200.0, 500.f)
//                                              options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
//                                              context:nil];
//        
//        return MAX(CELL_HEIGHT, rect.size.height + sizeTime.height + 1.0 + PADDING);
        return CELL_HEIGHT;
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.notificationsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageThreadCell *cell = [[MessageThreadCell alloc] init];
    [cell setMessageThread:[self.notificationsArray objectAtIndex:indexPath.row]];
    return cell;
    
//    if (indexPath.row == [self.notificationsArray count]) {
//        UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width - PANEL_WIDTH, CELL_HEIGHT)];
//        UILabel *clearNotificationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height)];
//        clearNotificationsLabel.text = @"Clear activity feed";
//        if ([self.notificationsArray count] == 0) {
//            clearNotificationsLabel.text = @"Activity feed";
//        }
//        
//        [clearNotificationsLabel setTextColor:UIColorFromRGB(0xc8c8c8)];
//        UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:20.0f];
//        [clearNotificationsLabel setFont:montserrat];
//        CGSize size = [clearNotificationsLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
//        clearNotificationsLabel.frame = CGRectMake((self.view.frame.size.width - PANEL_WIDTH - size.width) / 2.0, (CELL_HEIGHT - size.height) / 2.0, size.width, size.height);
//        clearNotificationsLabel.textAlignment = NSTextAlignmentCenter;
//        [cell setBackgroundColor:[UIColor clearColor]];
//        [cell addSubview:clearNotificationsLabel];
//        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
//        return cell;
//    } else {
//        NotificationCell *cell = [[NotificationCell alloc] init];
//        cell.delegate = self;
//        
//        if ([self.notificationsArray count] > 0) {
//            cell.notification = [self.notificationsArray objectAtIndex:indexPath.row];
//            [cell loadNotification];
//        }
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//        return cell;
//    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.notificationsTableView.frame.size.width, CELL_HEIGHT)];
 
    UIImage *backgroundImage = [UIImage imageNamed:@"BlackTexture"];
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundImageView.frame = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
    [view addSubview:backgroundImageView];
    
    UILabel *messageLabel = [[UILabel alloc] init];
    messageLabel.text = @"Messages";
    
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:18.0f];
    [messageLabel setFont:montserrat];
    messageLabel.textColor = [UIColor whiteColor];
    CGSize size = [messageLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    messageLabel.frame = CGRectMake((self.view.frame.size.width - PANEL_WIDTH - size.width) / 2.0, (CELL_HEIGHT - size.height + STATUS_BAR_HEIGHT) / 2.0, size.width, size.height);
    [view addSubview:messageLabel];
    
    UIButton *newMessageButton = [[UIButton alloc] initWithFrame:CGRectMake(view.frame.size.width - 41.0, 25.0, 40.0, 40.0)];
    [newMessageButton setImage:[UIImage imageNamed:@"PlusSign"] forState:UIControlStateNormal];
//    [newMessageButton addTarget:self action:@selector(newMessage:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:newMessageButton];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(20.0, view.frame.size.height - 0.5, self.notificationsTableView.frame.size.width - 20.0, 0.5)];
    separator.backgroundColor = UIColorFromRGB(0xc8c8c8);
    [view addSubview:separator];
    
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
