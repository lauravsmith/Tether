//
//  EditProfileViewController.m
//  Tether
//
//  Created by Laura Smith on 2014-06-02.
//  Copyright (c) 2014 Laura Smith. All rights reserved.
//

#import "AppDelegate.h"
#import "CenterViewController.h"
#import "Datastore.h"
#import "EditProfileViewController.h"
#import "ShareViewController.h"

#define LEFT_PADDING 40.0
#define PADDING 20.0
#define SEARCH_RESULTS_CELL_HEIGHT 60.0
#define SEGMENT_HEIGHT 45.0
#define SLIDE_TIMING 0.6
#define STATUS_BAR_HEIGHT 20.0
#define TOP_BAR_HEIGHT 70.0

#define degreesToRadian(x) (M_PI * (x) / 180.0)

static NSString *kGeoNamesAccountName = @"lsmit87";

@interface EditProfileViewController () <ShareViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, ILGeoNamesLookupDelegate, UIGestureRecognizerDelegate>

@property (retain, nonatomic) UIView * topBar;
@property (retain, nonatomic) UIScrollView * scrollView;
@property (nonatomic, strong) UILabel *pageTitleLabel;
@property (retain, nonatomic) UIView * separatorBar;
@property (retain, nonatomic) UIButton *backButton;
@property (retain, nonatomic) UITextField *statusMessageTextField;
@property (retain, nonatomic) UILabel * defaultCityLabel;
@property (retain, nonatomic) UISwitch * setLocationSwitch;
@property (retain, nonatomic) UILabel * cityLabel;
@property (retain, nonatomic) TethrButton *editCityButton;
@property (retain, nonatomic) ShareViewController *shareVC;
@property (retain, nonatomic) UILabel * privateLabel;
@property (retain, nonatomic) UISwitch * privateSwitch;
@property (retain, nonatomic) UIButton * logoutButton;
@property (strong, nonatomic) TethrButton *doneButton;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) UITableViewController *searchResultsTableViewController;
@property (nonatomic, strong) NSMutableArray *searchResultsArray;
@property (nonatomic, retain) ILGeoNamesLookup *geocoder;

@end

@implementation EditProfileViewController

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
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBack:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];

    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, TOP_BAR_HEIGHT)];
    [self.topBar setBackgroundColor:UIColorFromRGB(0x8e0528)];
    [self.view addSubview:self.topBar];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, TOP_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
    [self.scrollView setBackgroundColor:UIColorFromRGB(0xf8f8f8)];
    [self.view addSubview:self.scrollView];
    
    self.pageTitleLabel = [[UILabel alloc] init];
    self.pageTitleLabel.text = @"Edit Profile";
    UIFont *montserrat = [UIFont fontWithName:@"Montserrat" size:14.0f];
    [self.pageTitleLabel setTextColor:[UIColor whiteColor]];
    self.pageTitleLabel.font = montserrat;
    self.pageTitleLabel.adjustsFontSizeToFitWidth = YES;
    CGSize size = [self.pageTitleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    self.pageTitleLabel.frame = CGRectMake(MAX(LEFT_PADDING, (self.view.frame.size.width - size.width) / 2.0), STATUS_BAR_HEIGHT + (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT - size.height) / 2.0, MIN(self.view.frame.size.width - LEFT_PADDING*2, size.width), size.height);
    [self.topBar addSubview:self.pageTitleLabel];
    
    self.doneButton = [[TethrButton alloc] init];
    self.doneButton.titleLabel.font = montserrat;
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    size = [self.doneButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:montserrat}];
    [self.doneButton setFrame:CGRectMake(self.view.frame.size.width - 80.0, STATUS_BAR_HEIGHT + (TOP_BAR_HEIGHT - STATUS_BAR_HEIGHT - 50.0) / 2.0, 80.0, 50.0)];
    [self.doneButton addTarget:self action:@selector(doneClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:self.doneButton];
    
    self.separatorBar = [[UIView alloc] initWithFrame:CGRectMake(0, TOP_BAR_HEIGHT - 1.0, self.view.frame.size.width, 1.0)];
    [self.separatorBar setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [self.topBar addSubview:self.separatorBar];
    
    UIImage *triangleImage = [UIImage imageNamed:@"WhiteTriangle"];
    self.backButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 50.0, TOP_BAR_HEIGHT)];
    [self.backButton setImage:triangleImage forState:UIControlStateNormal];
    [self.backButton setImageEdgeInsets:UIEdgeInsetsMake(17.0, 0.0, 0.0, 32.0)];
    [self.backButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.backButton];
    
    UIView *whiteView = [[UIView alloc] initWithFrame:CGRectMake(0.0, PADDING, self.view.frame.size.width, SEGMENT_HEIGHT*3)];
    [whiteView setBackgroundColor:[UIColor whiteColor]];
    [self.scrollView addSubview:whiteView];
    
    self.statusMessageTextField = [[UITextField alloc] init];
    [self.statusMessageTextField setTextColor:UIColorFromRGB(0x1d1d1d)];
    [self.statusMessageTextField setFont:montserrat];
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (sharedDataManager.statusMessage && ![sharedDataManager.statusMessage isEqualToString:@""]) {
        self.statusMessageTextField.text = sharedDataManager.statusMessage;
    } else {
        self.statusMessageTextField.placeholder = @"Enter a status message";
    }
    self.statusMessageTextField.frame = CGRectMake(PADDING, 0.0, self.view.frame.size.width, SEGMENT_HEIGHT);
    UIImageView *editImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Edit.png"]];
    [whiteView addSubview:editImageView];
    [whiteView addSubview:self.statusMessageTextField];
    
    UIView * separatorBar = [[UIView alloc] initWithFrame:CGRectMake(20.0, SEGMENT_HEIGHT - 1.0, self.view.frame.size.width - 20.0, 1.0)];
    [separatorBar setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [whiteView addSubview:separatorBar];
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    
    //city search
    self.cityLabel = [[UILabel  alloc] init];
    NSString *location = [NSString stringWithFormat:@"%@, %@",[userDetails objectForKey:@"city"], [userDetails objectForKey:@"state"]];
    if ([userDetails objectForKey:@"city"] == NULL || [userDetails objectForKey:@"state"] == NULL) {
        location = @"Enter your city";
    }
    self.cityLabel.text = [location uppercaseString];
    self.cityLabel.font = montserrat;
    size = [self.cityLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.cityLabel.frame = CGRectMake(PADDING, SEGMENT_HEIGHT, size.width, SEGMENT_HEIGHT);
    self.cityLabel.textColor = UIColorFromRGB(0x1d1d1d);
    [whiteView addSubview:self.cityLabel];
    
    self.editCityButton = [[TethrButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80.0, SEGMENT_HEIGHT + (SEGMENT_HEIGHT - 30.0) / 2.0, 60.0, 30.0)];
    [self.editCityButton addTarget:self action:@selector(editCityClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.editCityButton setTitle:@"Edit" forState:UIControlStateNormal];
    [self.editCityButton setNormalColor:UIColorFromRGB(0xc8c8c8)];
    [self.editCityButton setHighlightedColor:UIColorFromRGB(0x8e0528)];
    self.editCityButton.layer.cornerRadius = 1.0;
    [whiteView addSubview:self.editCityButton];
    
    UIView * separatorBar2 = [[UIView alloc] initWithFrame:CGRectMake(20.0, SEGMENT_HEIGHT*2 - 1.0, self.view.frame.size.width - 20.0, 1.0)];
    [separatorBar2 setBackgroundColor:UIColorFromRGB(0xc8c8c8)];
    [whiteView addSubview:separatorBar2];
    
    self.defaultCityLabel = [[UILabel alloc] init];
    self.defaultCityLabel.text = @"Use current location";
    self.defaultCityLabel.font = montserrat;
    self.defaultCityLabel.textColor = UIColorFromRGB(0x1d1d1d);
    CGSize textLabelSize = [self.defaultCityLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.defaultCityLabel.frame = CGRectMake(PADDING, SEGMENT_HEIGHT*2 + (SEGMENT_HEIGHT - textLabelSize.height) / 2.0, textLabelSize.width, textLabelSize.height);
    [whiteView addSubview:self.defaultCityLabel];
    
    self.setLocationSwitch = [[UISwitch alloc] init];
    self.setLocationSwitch.frame = CGRectMake(self.view.frame.size.width - 70.0, SEGMENT_HEIGHT*2 + (SEGMENT_HEIGHT - self.setLocationSwitch.frame.size.height) / 2.0, 0, 0);
    [self.setLocationSwitch setOnTintColor:UIColorFromRGB(0x8e0528)];
    [self.setLocationSwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
    [whiteView addSubview:self.setLocationSwitch];
    
    [self.setLocationSwitch setOn:[userDetails boolForKey:@"useCurrentLocation"]];
    
    UIView *whiteView2 = [[UIView alloc] initWithFrame:CGRectMake(0.0, PADDING*2 + SEGMENT_HEIGHT*3, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [whiteView2 setBackgroundColor:[UIColor whiteColor]];
    [self.scrollView addSubview:whiteView2];
    
    TethrButton *shareButtonLarge = [[TethrButton alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [shareButtonLarge setNormalColor:[UIColor whiteColor]];
    [shareButtonLarge setHighlightedColor:UIColorFromRGB(0xc8c8c8)];
    [shareButtonLarge addTarget:self action:@selector(showShare:) forControlEvents:UIControlEventTouchUpInside];
    [whiteView2 addSubview:shareButtonLarge];
    
    UIButton *shareButton = [[UIButton alloc] init];
    [shareButton setTitle:@"Get your friends on Tethr" forState:UIControlStateNormal];
    shareButton.titleLabel.font = montserrat;
    size = [shareButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    shareButton.frame = CGRectMake(PADDING, (SEGMENT_HEIGHT - size.height) / 2.0, size.width, size.height);
    [shareButton setTitleColor:UIColorFromRGB(0x1d1d1d) forState:UIControlStateNormal];
    [shareButton addTarget:self action:@selector(showShare:) forControlEvents:UIControlEventTouchUpInside];
    [whiteView2 addSubview:shareButton];
    
    UIButton *shareArrowButton = [[UIButton alloc] init];
    [shareArrowButton setImage:[UIImage imageNamed:@"BlackTriangle"] forState:UIControlStateNormal];
    shareArrowButton.frame = CGRectMake(self.view.frame.size.width - 11.0 - PADDING, (SEGMENT_HEIGHT - 7.0) / 2.0, 7.0, 11.0);
    shareArrowButton.transform = CGAffineTransformMakeRotation(degreesToRadian(180));
    [shareArrowButton addTarget:self
                         action:@selector(showShare:)
               forControlEvents:UIControlEventTouchUpInside];
    [whiteView2 addSubview:shareArrowButton];
    
    UIView *whiteView3 = [[UIView alloc] initWithFrame:CGRectMake(0.0, PADDING*3 + SEGMENT_HEIGHT*4, self.view.frame.size.width, SEGMENT_HEIGHT)];
    [whiteView3 setBackgroundColor:[UIColor whiteColor]];
    [self.scrollView addSubview:whiteView3];
    
    self.privateLabel = [[UILabel alloc] init];
    self.privateLabel.text = @"Profile is Private";
    self.privateLabel.font = montserrat;
    self.privateLabel.textColor = UIColorFromRGB(0x1d1d1d);
    textLabelSize = [self.defaultCityLabel.text sizeWithAttributes:@{NSFontAttributeName: montserrat}];
    self.privateLabel.frame = CGRectMake(PADDING, (SEGMENT_HEIGHT - textLabelSize.height) / 2.0, textLabelSize.width, textLabelSize.height);
    [whiteView3 addSubview:self.privateLabel];
    
    self.privateSwitch = [[UISwitch alloc] init];
    self.privateSwitch.frame = CGRectMake(self.view.frame.size.width - 70.0, (SEGMENT_HEIGHT - self.privateSwitch.frame.size.height) / 2.0, 0, 0);
    [self.privateSwitch setOnTintColor:UIColorFromRGB(0x8e0528)];
    [self.privateSwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
    [whiteView3 addSubview:self.privateSwitch];
    PFUser *user = [PFUser currentUser];
    self.privateSwitch.on =[[user objectForKey:@"private"] boolValue];
    
    UIFont *montserratLarge = [UIFont fontWithName:@"Montserrat" size:16];
    self.logoutButton = [[UIButton alloc] init];
    [self.logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:UIColorFromRGB(0x1d1d1d) forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateHighlighted];
    self.logoutButton.titleLabel.font = montserratLarge;
    size = [self.logoutButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: montserratLarge}];
    self.logoutButton.frame = CGRectMake((self.view.frame.size.width - size.width) / 2.0, whiteView3.frame.origin.y + whiteView3.frame.size.height + PADDING*2, size.width, size.height);
    [self.logoutButton addTarget:self action:@selector(logoutButtonWasPressed:) forControlEvents:UIControlEventTouchDown];
    [self.scrollView addSubview:self.logoutButton];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, SEARCH_RESULTS_CELL_HEIGHT)];
    self.searchBar.delegate = self;
    
    //pull city search results from geonames.org
    self.geocoder = [[ILGeoNamesLookup alloc] initWithUserID:kGeoNamesAccountName];
    self.geocoder.delegate = self;
}

-(void)closeView {
    if ([self.delegate respondsToSelector:@selector(closeEditProfileVC)]) {
        [self.delegate closeEditProfileVC];
    }
}

-(void)saveStatusMessage {
    Datastore *sharedDataManager = [Datastore sharedDataManager];
    if (![self.statusMessageTextField.text isEqualToString:sharedDataManager.statusMessage]) {
        sharedDataManager.statusMessage = self.statusMessageTextField.text;
        PFUser *user = [PFUser currentUser];
        [user setObject:self.statusMessageTextField.text forKey:@"statusMessage"];
        [user saveInBackground];
        
        NSString *rawString = [self.statusMessageTextField text];
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *trimmed = [rawString stringByTrimmingCharactersInSet:whitespace];
        if ([trimmed length] != 0) {
            [self saveActivityObjectForStatusUpdate];
        }
    }
}

-(void)saveActivityObjectForStatusUpdate {
    PFObject *activity = [PFObject objectWithClassName:@"Activity"];
    PFUser *user = [PFUser currentUser];
    NSString *content = [NSString stringWithFormat:@"%@: %@", [user objectForKey:@"firstName"], self.statusMessageTextField.text];
    [activity setObject:content forKey:@"content"];
    [activity setObject:@"status" forKey:@"type"];
    [activity setObject:[NSDate date] forKey:@"date"];
    [activity setObject:user forKey:@"user"];
    [activity setObject:[user objectForKey:@"facebookId"] forKey:@"facebookId"];
    [activity setObject:[user objectForKey:@"cityLocation"] forKey:@"city"];
    [activity setObject:[user objectForKey:@"stateLocation"] forKey:@"state"];
    if ([[user objectForKey:@"private"] boolValue]) {
        [activity setObject:[NSNumber numberWithBool:[user objectForKey:@"private"]] forKey:@"private"];
    }
    [activity saveInBackground];
}

#pragma mark switch methods

- (void)switchChange:(UISwitch *)theSwitch {
    if (theSwitch == self.setLocationSwitch) {
        NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
        [userDetails setBool:theSwitch.on forKey:@"useCurrentLocation"];
        [userDetails synchronize];
        if (self.setLocationSwitch.on) {
            if ([self.delegate respondsToSelector:@selector(userChangedSettingsToUseCurrentLocation)]) {
                [self.delegate userChangedSettingsToUseCurrentLocation];
            }
        }
    }
}

#pragma mark button action methods

-(IBAction)editCityClicked:(id)sender {
    self.searchResultsArray = [[NSMutableArray alloc] init];
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - TOP_BAR_HEIGHT)];
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    [self.searchResultsTableView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.searchResultsTableView];
    self.searchResultsTableView.showsVerticalScrollIndicator = NO;
    [self.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    
    [UIView animateWithDuration:SLIDE_TIMING*0.5
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

-(IBAction)doneClicked:(id)sender {
    PFUser *user = [PFUser currentUser];
    [user setObject:[NSNumber numberWithBool:self.privateSwitch.on] forKey:@"private"];
    [user saveInBackground];
    
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
    }];
    
    NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
    [userDetails setBool:self.privateSwitch.on forKey:@"private"];
    [userDetails synchronize];
    
    [self saveStatusMessage];
    [self closeView];
}

-(IBAction)showShare:(id)sender {
    if (!self.shareVC) {
        self.shareVC = [[ShareViewController alloc] init];
        self.shareVC.delegate = self;
        
        [self addChildViewController:self.shareVC];
        [self.shareVC didMoveToParentViewController:self];
        [self.shareVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
        [self.view addSubview:self.shareVC.view];
        
        [UIView animateWithDuration:SLIDE_TIMING
                              delay:0.0
             usingSpringWithDamping:1.0
              initialSpringVelocity:1.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self.shareVC.view setFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                         }
                         completion:^(BOOL finished) {
                         }];
    }
}

-(IBAction)logoutButtonWasPressed:(id)sender {
    [self closeView];
    
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate logoutPressed];
}

#pragma mark UITableViewDelegate

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
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

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row == [self.searchResultsArray count]) {
        cell.isAccessibilityElement = YES;
        cell.textLabel.text = @"";
        cell.detailTextLabel.text =@"Powered by GeoNames";
        return cell;
    }
    
	NSDictionary	*geoname = [self.searchResultsArray objectAtIndex:indexPath.row];
	if(geoname) {
		NSString	*name = [geoname objectForKey:kILGeoNamesNameKey];
		cell.textLabel.text = name;
		NSString	*subString = [geoname objectForKey:kILGeoNamesCountryNameKey];
		if(subString && ![subString isEqualToString:@""]) {
			NSString	*admin1 = [geoname objectForKey:kILGeoNamesAdminName1Key];
			if(admin1 && ![admin1 isEqualToString:@""]) {
				subString = [admin1 stringByAppendingFormat:@", %@", subString];
				NSString *admin2 = [geoname objectForKey:kILGeoNamesAdminName2Key];
				if(admin2 && ![admin2 isEqualToString:@""]) {
					subString = [admin2 stringByAppendingFormat:@", %@", subString];
				}
			}
		}
		else {
			subString = [geoname objectForKey:kILGeoNamesFeatureClassNameKey];
		}
		cell.detailTextLabel.text = subString;
		cell.isAccessibilityElement = YES;
		cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", name, subString];
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == [self.searchResultsArray count]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self.geocoder cancel];
	
	[self geoNamesSearchControllerdidFinishWithResult:[self.searchResultsArray objectAtIndex:indexPath.row]];
}

- (void)geoNamesSearchControllerdidFinishWithResult:(NSDictionary*)result
{
	if(result) {
		double latitude = [[result objectForKey:kILGeoNamesLatitudeKey] doubleValue];
		double longitude = [[result objectForKey:kILGeoNamesLongitudeKey] doubleValue];
        self.cityLabel.text =[[result objectForKey:kILGeoNamesAlternateNameKey] uppercaseString];
        [self closeSearchResultsTableView];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
        NSUserDefaults *userDetails = [NSUserDefaults standardUserDefaults];
        [userDetails setBool:NO forKey:@"useCurrentLocation"];
        [userDetails synchronize];
        self.setLocationSwitch.on = NO;
        
        if ([self.delegate respondsToSelector:@selector(userChangedLocationInSettings:)]) {
            [self.delegate userChangedLocationInSettings:location];
            self.view.userInteractionEnabled = NO;
        }
	}
}

-(void)closeSearchResultsTableView {
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

#pragma mark ShareViewControllerDelegate

-(void)closeShareViewController {
    [UIView animateWithDuration:SLIDE_TIMING
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:1.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.shareVC.view setFrame:CGRectMake(self.view.frame.size.width, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
                     }
                     completion:^(BOOL finished) {
                         [self.shareVC.view removeFromSuperview];
                         [self.shareVC removeFromParentViewController];
                         self.shareVC = nil;
                     }];
}

#pragma mark -
#pragma mark ILGeoNamesLookupDelegate

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler networkIsActive:(BOOL)isActive
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = isActive;
}

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFindGeoNames:(NSArray *)geoNames totalFound:(NSUInteger)total
{
	if ([geoNames count]) {
		[self.searchResultsArray setArray:geoNames];
	}
	else {
		[self.searchResultsArray removeAllObjects];
	}
    
	[self.searchResultsTableView reloadData];
    // when the table view is repopulated, its significant enough that a screen change notification should be posted
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (void)geoNamesLookup:(ILGeoNamesLookup *)handler didFailWithError:(NSError *)error
{
	// TODO error handling
    NSLog(@"ILGeoNamesLookup has failed: %@", [error localizedDescription]);
	self.searchDisplayController.searchBar.prompt = NSLocalizedStringFromTable(@"ILGEONAMES_SEARCH_ERR", @"ILGeoNames", @"");
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
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.searchResultsArray removeAllObjects];
    
    // Delay the search 1 second to minimize outstanding requests
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(delayedSearch:) withObject:self.searchBar.text afterDelay:0.5];
}

- (void)delayedSearch:(NSString*)searchString
{
	[self.geocoder cancel];
	[self.geocoder search:searchString
                  maxRows:20
                 startRow:0
                 language:nil];
}

#pragma mark gesture handlers

-(void)moveBack:(id)sender {
    [[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];
    
    CGPoint velocity = [(UIPanGestureRecognizer*)sender velocityInView:[sender view]];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if(velocity.x > 0) {
            [self closeView];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
