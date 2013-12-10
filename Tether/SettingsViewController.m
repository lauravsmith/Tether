//
//  SettingsViewController.m
//  Tether
//
//  Created by Laura Smith on 11/28/2013.
//  Copyright (c) 2013 Laura Smith. All rights reserved.
//

#import "AppDelegate.h"
#import "SettingsViewController.h"

#define BORDER_WIDTH 4.0
#define PADDING 15.0
#define TABLE_VIEW_HEIGHT 140.0

static NSString *kGeoNamesAccountName = @"lsmit87";

@interface SettingsViewController () <ILGeoNamesLookupDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (retain, nonatomic) UIButton * settingsButton;
@property (retain, nonatomic) UIView * topBarView;
@property (retain, nonatomic) UILabel * settingsLabel;
@property (retain, nonatomic) UITextField *cityTextField;
@property (retain, nonatomic) UIButton * logoutButton;
@property (retain, nonatomic) UISwitch * setLocationSwitch;
@property (retain, nonatomic) UIView * whiteLineView;
@property (retain, nonatomic) UIView * whiteLineView2;
@property (retain, nonatomic) UILabel * defaultCityLabel;
@property (retain, nonatomic) UILabel * locationSwitchLabel;
@property (retain, nonatomic) NSUserDefaults * userDetails;
@property (retain, nonatomic) UISwitch * goingOutSwitch;
@property (retain, nonatomic) UILabel * goingOutLabel;
@property (retain, nonatomic) UILabel * yesLabel;
@property (retain, nonatomic) UILabel * noLabel;
@property (retain, nonatomic) UITableView * searchResultsTableView;
@property (retain, nonatomic) UITableViewController * searchResultsTableViewController;
@property (nonatomic, retain) NSMutableArray *searchResults;

@end

@implementation SettingsViewController

@synthesize searchResults;
@synthesize delegate;
@synthesize geocoder;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userDetails = [NSUserDefaults standardUserDefaults];
    [self.view setBackgroundColor:UIColorFromRGB(0xD6D6D6)];
    
    self.topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 70.0)];
    self.topBarView.backgroundColor = UIColorFromRGB(0xF3F3F3);
    [self.view addSubview:self.topBarView];
    
    self.topBarView.layer.masksToBounds = NO;
    self.topBarView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.topBarView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
    self.topBarView.layer.shadowOpacity = 0.5f;
    
    UIImage *gearImage = [UIImage imageNamed:@"Gear"];
    self.settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 40.0, 20.0, 30, 30)];
    [self.settingsButton setImage:gearImage forState:UIControlStateNormal];
    [self.view addSubview:self.settingsButton];
    [self.settingsButton addTarget:self action:@selector(handleCloseSettings:) forControlEvents:UIControlEventTouchDown];
    
    self.settingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, (self.topBarView.frame.size.height + 10.0 - 40.0) / 2, 200.0, 40.0)];
    self.settingsLabel.text = @"Me";
    [self.settingsLabel setTextColor:[UIColor whiteColor]];
    UIFont *champagne = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:30];
    self.settingsLabel.font = champagne;
    [self.topBarView addSubview:self.settingsLabel];
    
    self.userProfilePictureView.layer.cornerRadius = 24.0;
    self.userProfilePictureView.clipsToBounds = YES;
    [self.userProfilePictureView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
    [self.userProfilePictureView.layer setBorderWidth:BORDER_WIDTH];
    self.userProfilePictureView.frame = CGRectMake(10.0, 100.0, 50.0, 50.0);
    [self.view addSubview:self.userProfilePictureView];
    
    self.logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(100.0, 100.0, 100.0, 50.0)];
    [self.logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
    [self.logoutButton setTitleColor:UIColorFromRGB(0x770051) forState:UIControlStateNormal];
    UIFont *smallChampagneFont = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:28];
    self.logoutButton.titleLabel.font = smallChampagneFont;
    [self.logoutButton addTarget:self action:@selector(logoutButtonWasPressed:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.logoutButton];
    
    // white line separator
    self.whiteLineView = [[UIView alloc] initWithFrame:CGRectMake(0, self.topBarView.frame.size.height + 100.0, self.view.frame.size.width, 2.0)];
    [self.whiteLineView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.whiteLineView];
    
    self.defaultCityLabel = [[UILabel alloc] init];
    self.defaultCityLabel.text = @"Default City";
    self.defaultCityLabel.font = smallChampagneFont;
    self.defaultCityLabel.textColor = [UIColor whiteColor];
    CGSize textLabelSize = [self.defaultCityLabel.text sizeWithAttributes:@{NSFontAttributeName: smallChampagneFont}];
    self.defaultCityLabel.frame = CGRectMake(PADDING, self.whiteLineView.frame.origin.y + PADDING, textLabelSize.width, textLabelSize.height);
    [self.view addSubview:self.defaultCityLabel];
    
    self.locationSwitchLabel = [[UILabel alloc] init];
    self.locationSwitchLabel.text = @"Use current location?";
    UIFont *subheadingFont = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:16];
    self.locationSwitchLabel.font = subheadingFont;
    self.locationSwitchLabel.textColor = [UIColor whiteColor];
    CGSize locationSwitchLabelSize = [self.locationSwitchLabel.text sizeWithAttributes:@{NSFontAttributeName: subheadingFont}];
    self.locationSwitchLabel.frame = 
    CGRectMake(PADDING, self.defaultCityLabel.frame.origin.y + self.defaultCityLabel.frame.size.height + PADDING, locationSwitchLabelSize.width, locationSwitchLabelSize.height);
    [self.view addSubview:self.locationSwitchLabel];
    
    self.noLabel = [[UILabel alloc] init];
    self.noLabel.text = @"No";
    UIFont *switchLabelFont = [UIFont fontWithName:@"Champagne&Limousines-Bold" size:25];
    self.noLabel.font = switchLabelFont;
    self.noLabel.textColor = [UIColor whiteColor];
    CGSize noLabelSize = [self.noLabel.text sizeWithAttributes:@{NSFontAttributeName: switchLabelFont}];
    self.noLabel.frame = CGRectMake(PADDING, self.locationSwitchLabel.frame.origin.y + self.locationSwitchLabel.frame.size.height + PADDING, noLabelSize.width, noLabelSize.height);
    [self.view addSubview:self.noLabel];
    
    self.setLocationSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(self.noLabel.frame.origin.x + self.noLabel.frame.size.width + 2.0, self.locationSwitchLabel.frame.origin.y + self.locationSwitchLabel.frame.size.height + PADDING, 50.0, 20.0)];
    [self.setLocationSwitch setOnTintColor:UIColorFromRGB(0xF3F3F3)];
    [self.setLocationSwitch addTarget:self action:@selector(locationSwitchChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.setLocationSwitch];
    self.setLocationSwitch.on = [self.userDetails boolForKey:@"useCurrentLocation"];
    
    self.yesLabel = [[UILabel alloc] init];
    self.yesLabel.text = @"Yes";
    self.yesLabel.font = switchLabelFont;
    self.yesLabel.textColor = [UIColor whiteColor];
    CGSize yesLabelSize = [self.yesLabel.text sizeWithAttributes:@{NSFontAttributeName: switchLabelFont}];
    self.yesLabel.frame = CGRectMake(self.setLocationSwitch.frame.origin.x + self.setLocationSwitch.frame.size.width + 2.0, self.locationSwitchLabel.frame.origin.y + self.locationSwitchLabel.frame.size.height + PADDING, yesLabelSize.width, yesLabelSize.height);
    [self.view addSubview:self.yesLabel];
    
    self.cityTextField = [[UITextField  alloc] initWithFrame:CGRectMake(PADDING, self.setLocationSwitch.frame.origin.y + self.setLocationSwitch.frame.size.height + PADDING, self.view.frame.size.width - PADDING * 2, 30.0)];
    self.cityTextField.delegate = self;
    NSString *location = [NSString stringWithFormat:@"%@,%@",[self.userDetails objectForKey:@"city"], [self.userDetails objectForKey:@"state"]];
    self.cityTextField.text = [location uppercaseString];
    UIFont *textViewFont = [UIFont fontWithName:@"Champagne&Limousines-Italic" size:18];
    self.cityTextField.font = textViewFont;
    self.cityTextField.textColor = UIColorFromRGB(0x770051);
    self.cityTextField.layer.cornerRadius = 5.0;
    [self.cityTextField setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.cityTextField];
    self.cityTextField.enabled = !self.setLocationSwitch.on;
    self.cityTextField .clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.cityTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    //city search
    self.geocoder = [[ILGeoNamesLookup alloc] initWithUserID:kGeoNamesAccountName];
    self.geocoder.delegate = self;
    
    self.searchResultsTableView = [[UITableView alloc] initWithFrame:CGRectMake(PADDING, self.whiteLineView.frame.origin.y + 45, self.cityTextField.frame.size.width, TABLE_VIEW_HEIGHT)];
    [self.searchResultsTableView setBackgroundColor:[UIColor whiteColor]];
    [self.searchResultsTableView setDataSource:self];
    [self.searchResultsTableView setDelegate:self];
    self.searchResultsTableView.hidden = YES;
    
    [self.view addSubview:self.searchResultsTableView];
    
    self.searchResultsTableViewController = [[UITableViewController alloc] init];
    self.searchResultsTableViewController.tableView = self.searchResultsTableView;
    [self.searchResultsTableView reloadData];
    
    self.whiteLineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, self.cityTextField.frame.origin.y + self.cityTextField.frame.size.height + PADDING, self.view.frame.size.width, 2.0)];
    [self.whiteLineView2 setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.whiteLineView2];
    
    self.goingOutLabel = [[UILabel alloc] init];
    self.goingOutLabel.text = @"Going out?";
    self.goingOutLabel.font = subheadingFont;
    self.goingOutLabel.textColor = [UIColor whiteColor];
    locationSwitchLabelSize = [self.goingOutLabel.text sizeWithAttributes:@{NSFontAttributeName: subheadingFont}];
    self.goingOutLabel.frame =
    CGRectMake(PADDING, self.whiteLineView2.frame.origin.y + self.whiteLineView2.frame.size.height + PADDING, locationSwitchLabelSize.width, locationSwitchLabelSize.height);
    [self.view addSubview:self.goingOutLabel];
    
    UILabel *noLabel2 = [[UILabel alloc] init];
    noLabel2.text = @"No";
    noLabel2.font = switchLabelFont;
    noLabel2.textColor = [UIColor whiteColor];
    noLabel2.frame = CGRectMake(PADDING, self.goingOutLabel.frame.origin.y + self.goingOutLabel.frame.size.height + PADDING, noLabelSize.width, noLabelSize.height);
    [self.view addSubview:noLabel2];
    
    self.goingOutSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(self.noLabel.frame.origin.x + self.noLabel.frame.size.width + 2.0, self.goingOutLabel.frame.origin.y + self.goingOutLabel.frame.size.height + PADDING, 50.0, 20.0)];
    [self.goingOutSwitch setOnTintColor:UIColorFromRGB(0xF3F3F3)];
    [self.goingOutSwitch addTarget:self action:@selector(locationSwitchChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.goingOutSwitch];
    self.goingOutSwitch.on = [self.userDetails boolForKey:@"status"];
    
    UILabel *yesLabel2 = [[UILabel alloc] init];
    yesLabel2.text = @"Yes";
    yesLabel2.font = switchLabelFont;
    yesLabel2.textColor = [UIColor whiteColor];
    yesLabel2.frame = CGRectMake(self.goingOutSwitch.frame.origin.x + self.goingOutSwitch.frame.size.width + 2.0, self.goingOutLabel.frame.origin.y + self.goingOutLabel.frame.size.height + PADDING, yesLabelSize.width, yesLabelSize.height);
    [self.view addSubview:yesLabel2];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
    // when the view slides in, its significant enough that a screen change notification should be posted
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (NSMutableArray *)searchResults
{
	if(!searchResults)
		searchResults = [[NSMutableArray alloc] init];
	
	return searchResults;
}

- (void)locationSwitchChange:(UISwitch *)theSwitch {
    if (theSwitch == self.setLocationSwitch) {
        [self.userDetails setBool:theSwitch.on forKey:@"useCurrentLocation"];
        self.cityTextField.enabled = !self.setLocationSwitch.on;
    } else {
        [self.userDetails setBool:theSwitch.on forKey:@"status"];
        if ([self.delegate respondsToSelector:@selector(updateStatus)]) {
            [self.delegate updateStatus];
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGRect frame = self.cityTextField.frame;
                         frame.origin.y = self.whiteLineView.frame.origin.y + self.whiteLineView.frame.size.height + PADDING;
                         self.cityTextField.frame = frame;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                            self.searchResultsTableView.hidden = NO;
                         }
                     }];

    self.locationSwitchLabel.hidden = true;
    self.setLocationSwitch.hidden = true;
    self.yesLabel.hidden = true;
    self.noLabel.hidden = true;
}

-(void)textFieldDidChange:(UITextField*)textField {
//    self.searchDisplayController.searchBar.prompt = NSLocalizedStringFromTable(@"ILGEONAMES_SEARCHING", @"ILGeoNames", @"");
	[self.searchResults removeAllObjects];
	
	// Delay the search 1 second to minimize outstanding requests
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(delayedSearch:) withObject:textField.text afterDelay:1.0];
}

- (void)delayedSearch:(NSString*)searchString
{
	[self.geocoder cancel];
	[self.geocoder search:searchString
						maxRows:20
					   startRow:0
					   language:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handleCloseSettings:(id)sender {
    if ([self.delegate respondsToSelector:@selector(closeSettings)]) {
        [self.delegate closeSettings];
    }
}

-(IBAction)logoutButtonWasPressed:(id)sender {
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate logoutPressed];
}

-(void)closeSearchResultsTableView {
    [self.searchResults removeAllObjects];
    self.searchResultsTableView.hidden = YES;
    [self.searchResultsTableView reloadData];
    
    self.locationSwitchLabel.hidden = NO;
    self.setLocationSwitch.hidden = NO;
    self.yesLabel.hidden = NO;
    self.noLabel.hidden = NO;
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGRect frame = self.cityTextField.frame;
                         frame.origin.y = self.setLocationSwitch.frame.origin.y + self.setLocationSwitch.frame.size.height + PADDING;
                         self.cityTextField.frame = frame;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             
                         }
                     }];
    [self.cityTextField resignFirstResponder];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    return [self.searchResults count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
	NSDictionary	*geoname = [self.searchResults objectAtIndex:indexPath.row];
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

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self.geocoder cancel];
	self.geocoder.delegate = nil;
	
	[self geoNamesSearchControllerdidFinishWithResult:[self.searchResults objectAtIndex:indexPath.row]];
}

- (void)geoNamesSearchControllerdidFinishWithResult:(NSDictionary*)result
{
	NSLog(@"didFinishWithResult: %@", result);
//	[self.controller dismissModalViewControllerAnimated:YES];
	
	if(result) {
		double latitude = [[result objectForKey:kILGeoNamesLatitudeKey] doubleValue];
		double longitude = [[result objectForKey:kILGeoNamesLongitudeKey] doubleValue];
        self.cityTextField.text =[result objectForKey:kILGeoNamesAlternateNameKey];
        [self closeSearchResultsTableView];
	}
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
		[self.searchResults setArray:geoNames];
	}
	else {

		[self.searchResults removeAllObjects];
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

@end
