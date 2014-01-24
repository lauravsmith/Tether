//
//  InviteViewController.h
//  Tether
//
//  Created by Laura Smith on 12/19/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "Friend.h"
#import "Place.h"
#import <UIKit/UIKit.h>

@protocol InviteViewControllerDelegate;

@interface InviteViewController : UIViewController
@property (nonatomic, weak) id<InviteViewControllerDelegate> delegate;
@property (retain, nonatomic) Place *place;
@property (retain, nonatomic) UIView * topBarView;
@property (retain, nonatomic) UILabel *placeLabel;
@property (retain, nonatomic) UISearchBar *searchBar;
@property (retain, nonatomic) UIView *searchBarBackgroundView;
@property (retain, nonatomic) UIButton *sendButton;
@property (retain, nonatomic) NSMutableDictionary *friendsInvitedDictionary;
-(void)addFriend:(Friend *)friend;
-(void)layoutFriendsInvitedView;
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar;
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar;
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol InviteViewControllerDelegate <NSObject>
-(void)closeInviteView;
@end