//
//  PhotoEditViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-05-26.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "CenterViewController.h"
#import "Datastore.h"
#import "PhotoEditViewController.h"
#import "SearchResultCell.h"

#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <Parse/Parse.h>

#define SEARCH_RESULTS_CELL_HEIGHT 60.0
#define SLIDE_TIMING 0.4
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

@interface PhotoEditViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UITextViewDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UILabel *topBarLabel;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UITextView *commentTextView;
@property (nonatomic, strong) PFFile *photoFile;
@property (nonatomic, assign) UIBackgroundTaskIdentifier fileUploadBackgroundTaskId;
@property (nonatomic, assign) UIBackgroundTaskIdentifier photoPostBackgroundTaskId;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UITableViewController *searchResultsTableViewController;
@property (nonatomic, strong) NSMutableArray *searchResultsArray;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (retain, nonatomic) UIView *switchView;
@property (retain, nonatomic) UIView *sliderView;
@property (assign, nonatomic) BOOL sliderOn;
@property (retain, nonatomic) UIImageView *pinImage;

@end

@implementation PhotoEditViewController

- (id)initWithImage:(UIImage *)aImage {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        if (!aImage) {
            return nil;
        }
        
        self.image = aImage;
        self.fileUploadBackgroundTaskId = UIBackgroundTaskInvalid;
        self.photoPostBackgroundTaskId = UIBackgroundTaskInvalid;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:self.topBar];
    
    UIFont *montserratSmall = [UIFont fontWithName:@"Montserrat" size:14.0f];
    
    self.topBarLabel = [[UILabel alloc] init];
    self.topBarLabel.text = @"Photo Details";
    UIFont *montserratMed = [UIFont fontWithName:@"Montserrat" size:16.0f];
    [self.topBarLabel setTextColor:[UIColor whiteColor]];
    self.topBarLabel.font = montserratMed;
    CGSize size = [self.topBarLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratMed}];
    self.topBarLabel.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, STATUS_BAR_HEIGHT + (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT - size.height) / 2.0, size.width, size.height);
    [self.topBar addSubview:self.topBarLabel];
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, STATUS_BAR_HEIGHT, 80.0, TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT)];
    self.cancelButton.titleLabel.font = montserratSmall;
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.cancelButton];
    
    self.shareButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80.0, STATUS_BAR_HEIGHT, 80.0, TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT)];
    self.shareButton.titleLabel.font = montserratSmall;
    [self.shareButton setTitle:@"Share" forState:UIControlStateNormal];
    [self.shareButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.shareButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateDisabled];
    [self.shareButton setEnabled:NO];
    [self.shareButton addTarget:self action:@selector(shareButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.shareButton];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"BackgroundLeather.png"]];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    
    UIImageView *photoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.width)];
    [photoImageView setBackgroundColor:[UIColor whiteColor]];
    [photoImageView setImage:self.image];
    [photoImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [self.scrollView addSubview:photoImageView];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    self.enterLocation = [[UIButton alloc] initWithFrame:CGRectMake(0.0, photoImageView.frame.origin.y + photoImageView.frame.size.height, self.view.frame.size.width, 60.0)];
    [self.enterLocation addTarget:self action:@selector(addLocationClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.enterLocation.titleLabel.font = montserratMed;
    self.pinImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PinIcon"]];
    self.pinImage.contentMode = UIViewContentModeScaleAspectFit;
    [self.scrollView addSubview:self.pinImage];
    if (self.place) {
        [self.enterLocation setTitle:[NSString stringWithFormat:@"%@", self.place.name] forState:UIControlStateNormal];
        size = [self.enterLocation.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratMed}];
        self.pinImage.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0 - 30.0, self.enterLocation.frame.origin.y + (self.enterLocation.frame.size.height - 25.0) / 2, 25.0, 25.0);
        [self.shareButton setEnabled:YES];
    } else {
        if (sharedDataManager.currentCommitmentPlace) {
            self.place = sharedDataManager.currentCommitmentPlace;
            [self.enterLocation setTitle:[NSString stringWithFormat:@"%@", self.place.name] forState:UIControlStateNormal];
            size = [self.enterLocation.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratMed}];
            self.pinImage.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0 - 30.0, self.enterLocation.frame.origin.y + (self.enterLocation.frame.size.height - 25.0) / 2, 25.0, 25.0);
            [self.shareButton setEnabled:YES];
        } else {
            [self.enterLocation setTitle:@"Add Location" forState:UIControlStateNormal];
            size = [self.enterLocation.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratMed}];
            self.pinImage.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0 - 30.0, self.enterLocation.frame.origin.y + (self.enterLocation.frame.size.height - 25.0) / 2, 25.0, 25.0);
        }
    }

    [self.enterLocation setTitleColor:UIColorFromRGB(0x8e0528) forState:UIControlStateNormal];
    [self.scrollView addSubview:self.enterLocation];
    
    self.commentTextView = [[UITextView alloc] initWithFrame:CGRectMake(15.0, self.enterLocation.frame.origin.y + self.enterLocation.frame.size.height, self.view.frame.size.width - 30.0, 30.0)];
    self.commentTextView.tag = 0.0;
    self.commentTextView.delegate = self;
    [[self.commentTextView layer] setBorderColor:UIColorFromRGB(0xc8c8c8).CGColor];
    [[self.commentTextView layer] setBorderWidth:0.5];
    [[self.commentTextView layer] setCornerRadius:4.0];
    self.commentTextView.font = montserratSmall;
    self.commentTextView.textColor = UIColorFromRGB(0xc8c8c8);
    self.commentTextView.text = @"Add a comment...";
    [self.scrollView addSubview:self.commentTextView];
    
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.bounds.size.width, photoImageView.frame.origin.y + photoImageView.frame.size.height + self.enterLocation.frame.size.height + self.commentTextView.frame.size.height + 20.0)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self shouldUploadImage:self.image];
    
    self.switchView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 83.0, self.commentTextView.frame.origin.y + self.commentTextView.frame.size.height + 10.0, 68.0, 34.0)];
    [self.switchView setBackgroundColor:[UIColor whiteColor]];
    self.switchView.layer.borderColor = UIColorFromRGB(0xc8c8c8).CGColor;
    self.switchView.layer.cornerRadius = 5.0;
    self.switchView.layer.borderWidth = 1.0;
    [self.scrollView addSubview:self.switchView];
    
    self.sliderView = [[UIView alloc] initWithFrame:CGRectMake(2.0, 2.0, 30.0, 34.0 - 4.0)];
    [self.sliderView setBackgroundColor:UIColorFromRGB(0x8e0528)];
    self.sliderView.layer.cornerRadius = 5.0;
    [self.switchView addSubview:self.sliderView];
    
    UIButton *lockButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 34.0, 34.0)];
    [lockButton setImage:[UIImage imageNamed:@"Lock.png"] forState:UIControlStateNormal];
    [lockButton setImageEdgeInsets:UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0)];
    [lockButton addTarget:self action:@selector(lockTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.switchView addSubview:lockButton];
    
    UIView *sliderSeparator = [[UIView alloc] initWithFrame:CGRectMake(34.0, 0.0, 1.0, self.switchView.frame.size.height)];
    [sliderSeparator setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.switchView addSubview:sliderSeparator];
    
    UIButton *globeButton = [[UIButton alloc] initWithFrame:CGRectMake(34.0, 0.0, 34.0, 34.0)];
    [globeButton setImage:[UIImage imageNamed:@"Globe.png"] forState:UIControlStateNormal];
    [globeButton setImageEdgeInsets:UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0)];
    [globeButton addTarget:self action:@selector(globeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.switchView addSubview:globeButton];
}

-(void)lockTapped {
    self.sliderOn = NO;
    [self setupSlider];
}

-(void)globeTapped {
    self.sliderOn = YES;
    [self setupSlider];
}

-(void)setupSlider {
    CGRect frame;
    if (self.sliderOn) {
        frame = CGRectMake(36.0, 2.0, 30.0, 30.0);
    } else {
        frame = CGRectMake(2.0, 2.0, 30.0, 30.0);
    }
    
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.sliderView.frame = frame;
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (BOOL)shouldUploadImage:(UIImage *)anImage {
    NSData *imageData = UIImageJPEGRepresentation(anImage, 1.0f);
    self.photoFile = [PFFile fileWithData:imageData];
    
    // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
    self.fileUploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
    }];

    [self.photoFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [[UIApplication sharedApplication] endBackgroundTask:self.fileUploadBackgroundTaskId];
    }];
    
    return YES;
}

- (void)keyboardWillShow:(NSNotification *)note {
    CGRect keyboardFrameEnd = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize scrollViewContentSize = self.scrollView.bounds.size;
    scrollViewContentSize.height += keyboardFrameEnd.size.height;
    [self.scrollView setContentSize:scrollViewContentSize];
    
    CGPoint scrollViewContentOffset = self.scrollView.contentOffset;
    // Align the bottom edge of the photo with the keyboard
    scrollViewContentOffset.y = scrollViewContentOffset.y + TOP_BAR_HEIGHT + keyboardFrameEnd.size.height*3.0f - [UIScreen mainScreen].bounds.size.height;
    
    [UIView animateWithDuration:0.3
                     animations:^{
        [self.scrollView setContentOffset:scrollViewContentOffset];
                     }];
}

- (void)keyboardWillHide:(NSNotification *)note {
    CGRect keyboardFrameEnd = [[note.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize scrollViewContentSize = self.scrollView.bounds.size;
    scrollViewContentSize.height -= keyboardFrameEnd.size.height;
    [UIView animateWithDuration:0.3
                     animations:^{
                              [self.scrollView setContentSize:scrollViewContentSize];
                     }];
}

- (void)addLocationClicked:(id)sender {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    self.searchResultsArray = [[NSMutableArray alloc] init];
    
    for (id key in sharedDataManager.placesDictionary) {
        Place *place = [sharedDataManager.placesDictionary objectForKey:key];
        [self.searchResultsArray addObject:place];
    }
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    [self.searchResultsTableView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.searchResultsTableView];
    self.searchResultsTableView.showsVerticalScrollIndicator = NO;
    [self.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    
    [UIView animateWithDuration:SLIDE_TIMING*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.searchResultsTableView setFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void)cancelButtonAction:(id)sender {
    if ([self.delegate respondsToSelector:@selector(closePhotoEditView)]) {
        [self.delegate closePhotoEditView];
    }
}

- (void)shareButtonAction:(id)sender {
    [self resignFirstResponder];
    
    [self.delegate closePhotoEditView];
    
    if ([self.delegate respondsToSelector:@selector(confirmPosting:)]) {
        [self.delegate confirmPosting:@"Posting your photo"];
    }
    
    NSString *trimmedComment = [self.commentTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // Make sure there were no errors creating the image files
    if (!self.photoFile) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
        [alert show];
        return;
    }
    
    // create a photo object
    PFObject *photo = [PFObject objectWithClassName:@"Photo"];
    [photo setObject:[PFUser currentUser] forKey:@"user"];
    [photo setObject:self.photoFile forKey:@"photoFile"];
    
    // photos are public, but may only be modified by the user who uploaded them
    PFACL *photoACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [photoACL setPublicReadAccess:YES];
    photo.ACL = photoACL;
    
    // Request a background execution task to allow us to finish uploading the photo even if the app is backgrounded
    self.photoPostBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
    }];
    
    // Save the Photo PFObject
    [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            
            PFObject *activity = [PFObject objectWithClassName:@"Activity"];
            [activity setObject:photo forKey:@"photo"];
            [activity setObject:[PFUser currentUser] forKey:@"user"];
            Datastore *sharedDataManager = [Datastore sharedDataManager];
            [activity setObject:sharedDataManager.facebookId forKey:@"facebookId"];
            [activity setObject:@"photo" forKey:@"type"];
            if (![trimmedComment isEqualToString:@""] && self.commentTextView.tag != 0) {
                [activity setObject:trimmedComment forKey:@"content"];
            }
            [activity setObject:self.place.placeId forKey:@"placeId"];
            [activity setObject:self.place.name forKey:@"placeName"];
            if (self.place.city) {
                [activity setObject:self.place.city forKey:@"city"];
            }
            
            if (self.place.state) {
                [activity setObject:self.place.state forKey:@"state"];
            }
            
            [activity setObject:[PFGeoPoint geoPointWithLatitude:self.place.coord.latitude
                                                         longitude:self.place.coord.longitude] forKey:@"coordinate"];
            [activity setObject:[NSDate date] forKey:@"date"];
            
            if (self.place.owner) {
                [activity setObject:self.place.owner forKey:@"owner"];
            }
            
            if (self.place.memo) {
                if (![self.place.memo isEqualToString:@""]) {
                    [activity setObject:self.place.memo forKey:@"memo"];
                }
            } else {
                [activity setObject:@"" forKey:@"memo"];
            }
            
            if (self.place.isPrivate) {
                [activity setObject:[NSNumber numberWithBool:self.place.isPrivate] forKey:@"privatePlace"];
            }
            
            if (!self.sliderOn) {
                [activity setObject:[NSNumber numberWithBool:YES] forKey:@"private"];
            }
            
            [activity saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    if ([self.delegate respondsToSelector:@selector(reloadActivity)]) {
                        [self.delegate reloadActivity];
                    }
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
                    [alert show];
                }
            }];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't post your photo" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
            [alert show];
        }
        [[UIApplication sharedApplication] endBackgroundTask:self.photoPostBackgroundTaskId];
    }];
}

#pragma mark UITableViewDelegate

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, SEARCH_RESULTS_CELL_HEIGHT)];
    self.searchBar.delegate = self;
    [self.searchBar becomeFirstResponder];
    [self searchBarTextDidBeginEditing:self.searchBar];
    return self.searchBar;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SEARCH_RESULTS_CELL_HEIGHT;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return SEARCH_RESULTS_CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.searchResultsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.searchResultsArray count]) {
        UIImageView *foursquareImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"poweredByFoursquare"]];
        foursquareImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, SEARCH_RESULTS_CELL_HEIGHT);
        foursquareImageView.contentMode = UIViewContentModeScaleAspectFit;
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        [cell addSubview:foursquareImageView];
        return cell;
    }
    SearchResultCell *cell = [[SearchResultCell alloc] init];
    Place *p = [self.searchResultsArray objectAtIndex:indexPath.row];
    cell.place = p;
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:18];
    UIFont *montserratSubLabelFont = [UIFont fontWithName:@"Montserrat" size:12];
    UILabel *placeNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20.0)];
    placeNameLabel.text = p.name;
    placeNameLabel.font = montserrat;
    [cell addSubview:placeNameLabel];
    UILabel *placeAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30.0, self.view.frame.size.width, 15.0)];
    placeAddressLabel.text = p.address;
    placeAddressLabel.font = montserratSubLabelFont;
    [cell addSubview:placeAddressLabel];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.place = [self.searchResultsArray objectAtIndex:indexPath.row];
    
    [UIView animateWithDuration:SLIDE_TIMING*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.searchResultsTableView setFrame:CGRectMake(0.0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
                     }
                     completion:^(BOOL finished) {
                     }];
    
    [self.enterLocation setTitle:[NSString stringWithFormat:@"%@", self.place.name] forState:UIControlStateNormal];
    UIFont *montserratMed = [UIFont fontWithName:@"Montserrat" size:16.0f];
    CGSize size = [self.enterLocation.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserratMed}];
    self.pinImage.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0 - 30.0, self.enterLocation.frame.origin.y + (self.enterLocation.frame.size.height - 25.0) / 2, 25.0, 25.0);
    [self.shareButton setEnabled:YES];
    [self.searchBar resignFirstResponder];
}

#pragma mark SearchBarDelegate methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [UIView animateWithDuration:SLIDE_TIMING*1.2
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.searchResultsTableView setFrame:CGRectMake(0.0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self loadPlacesForSearch:searchBar.text];
}

// Search foursquare data call
- (void)loadPlacesForSearch:(NSString*)search {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    NSString *today = [formatter stringFromDate:[NSDate date]];
    
    NSString *urlString1 = @"https://api.foursquare.com/v2/venues/search?near=";
    NSString *urlString2 = @"&query=";
    NSString *urlString3 = @"&limit=50&client_id=VLMUFMIAUWTTEVXXFQEQNKFDMCOFYEHTZU1U53IPQCI1PONX&client_secret=RH1CZUW0WWVM5LIEGZNFLU133YZX1ZMESAJ4PWNSDDSFMGYS&v=";
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    NSString *joinString=[NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",urlString1,[userDetails objectForKey:@"city"] ,@"%20",[userDetails objectForKey:@"state"],urlString2, search, urlString3, today];
    joinString = [joinString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    NSURL *url = [NSURL URLWithString:joinString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *jsonDict = (NSDictionary *) responseObject;
        [self processSearchResults:jsonDict forSearch:search];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failure");
        [self processSearchResults:nil forSearch:search];
    }];
    [operation start];
}

- (void)processSearchResults:(NSDictionary *)json forSearch:(NSString*)search {
    self.searchResultsArray = [[NSMutableArray alloc] init];
    NSDictionary *response = [json objectForKey:@"response"];
    NSArray *venues = [response objectForKey:@"venues"];
    
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    
    for (Place *place in sharedDataManager.placesArray) {
        if (place.name ) {
            if ([[place.name lowercaseString] rangeOfString:[search lowercaseString]].location != NSNotFound) {
                [self.searchResultsArray addObject:place];
            }
        }
    }
    
    for (NSDictionary *venue in venues) {
        Place *newPlace = [[Place alloc] init];
        newPlace.placeId = [venue objectForKey:@"id"];
        if (![sharedDataManager.placesDictionary objectForKey:newPlace.placeId]) {
            newPlace.name = [venue objectForKey:@"name"];
            CLLocationCoordinate2D location = CLLocationCoordinate2DMake([(NSString*)[[venue objectForKey:@"location"] objectForKey:@"lat"] doubleValue], [[[venue objectForKey:@"location"] objectForKey:@"lng"] doubleValue]);
            newPlace.coord = location;
            NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
            newPlace.city = [userDetails objectForKey:@"city"];
            newPlace.state = [userDetails objectForKey:@"state"];
            NSDictionary *locationDetails = [venue objectForKey:@"location"];
            newPlace.address = [locationDetails objectForKey:@"address"];
            
            [self.searchResultsArray addObject:newPlace];
        }
    }
    
    [self.searchResultsTableView reloadData];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchResultsTableView.hidden = NO;
}

#pragma mark - UITextViewDelegate 

- (BOOL) textViewShouldBeginEditing:(UITextView *)textView
{
    if (self.commentTextView.tag == 0) {
        self.commentTextView.text = @"";
        self.commentTextView.textColor = [UIColor blackColor];
        self.commentTextView.tag = 1;
    }
    
    return YES;
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    if ([self.commentTextView isFirstResponder]) {
        if (self.lastContentOffset > self.scrollView.contentOffset.y)
            [self.view endEditing:YES];
        
        self.lastContentOffset = self.scrollView.contentOffset.x;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
