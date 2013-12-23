//
//  RightPanelViewController.m
//  Tether
//
//  Created by Laura Smith on 12/12/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Datastore.h"
#import "Notification.h"
#import "NotificationCell.h"
#import "RightPanelViewController.h"

#import <Parse/Parse.h>

#define CELL_HEIGHT 100.0
#define PANEL_WIDTH 60.0

@interface RightPanelViewController () <UITableViewDataSource, UITableViewDelegate>
@property (retain, nonatomic) NSMutableArray *notificationsArray;
@property (nonatomic, strong) UITableView *notificationsTableView;
@property (nonatomic, strong) UITableViewController *notificationsTableViewController;
@end

@implementation RightPanelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.notificationsArray = [[NSMutableArray alloc] init];
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.notificationsTableView = [[UITableView alloc] initWithFrame:CGRectMake(PANEL_WIDTH, 0, self.view.frame.size.width - PANEL_WIDTH, self.view.frame.size.height)];
    [self.notificationsTableView setDataSource:self];
    [self.notificationsTableView setDelegate:self];
    [self.view addSubview:self.notificationsTableView];
    
    self.notificationsTableViewController = [[UITableViewController alloc] init];
    self.notificationsTableViewController.tableView = self.notificationsTableView;
}

-(void)loadNotifications {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.notificationsArray = [[NSMutableArray alloc] init];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Invitation"];
    
    if (sharedDataManager.facebookId) {
        [query whereKey:@"recipientID" equalTo:sharedDataManager.facebookId];
        
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                for (PFObject *invitation in objects) {
                    Notification *notification = [[Notification alloc] init];
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
                }
            }
            NSSortDescriptor *timeDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO];
            [self.notificationsArray sortUsingDescriptors:[NSArray arrayWithObjects:timeDescriptor, nil]];
            [self.notificationsTableView reloadData];
        }];
    }
}

#pragma mark UITableViewDataSource Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
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
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
