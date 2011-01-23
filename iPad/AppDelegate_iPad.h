//
//  VeloParisAppDelegate.h
//  VeloParis
//
//  Created by CocoaBob on 10-4-1.
//  Copyright CocoaBob 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "StationAnnotation.h"
#import "ConnectionDelegate.h"
#import "PinAnnotationView.h"
#import "CustomizedTableCell.h"

@interface AppDelegate_iPad : NSObject <UIApplicationDelegate,CLLocationManagerDelegate,UISearchBarDelegate ,UITableViewDelegate,UITableViewDataSource> {
	UIWindow						*window;
	IBOutlet UIView					*mSuperView;
	IBOutlet MKMapView				*mMapView;
	IBOutlet UITableView			*mFavoritesTableView;
	IBOutlet UITableView			*mTableView;
	IBOutlet UIView					*mSettingView;
	IBOutlet UISegmentedControl		*mMapTypeSwitch;
	IBOutlet UISegmentedControl		*mRefreshCacheButton;
	IBOutlet UIBarButtonItem		*mZoomInButton;
	IBOutlet UIBarButtonItem		*mZoomOutButton;
	IBOutlet UIBarButtonItem		*mLocateSelfButton;
	IBOutlet UIBarButtonItem		*mSettingButton;
	IBOutlet UIBarButtonItem		*mFavoritesButton;
	
	CLLocationManager				*mLocationManager;
	UIImage							*mPinGreen;
	UIImage							*mPinYellowGreen;
	UIImage							*mPinYellow;
	UIImage							*mPinOrange;
	UIImage							*mPinRed;
	UIImage							*mPinPurple;
	NSInteger						mRequestCount;
	NSInteger						mRequestCountForTable;
	NSDate							*latestThreadTime;
	NSDate							*latestTableThreadTime;
	UIImage							*mFavoriteOn;
	UIImage							*mFavoriteOff;
	NSMutableArray					*mFavoriteList;
	NSMutableDictionary				*mAllStationAnnotationData;
	BOOL							mDidAddAllAnnotations;
	BOOL							mDidAddUserLocationAnnotation;
	UIView							*mMKOverlayView;
	UIView							*mMKMapLevelView;
	UIImageView						*mUserHeadingView;
	BOOL							mHasAddedUserHeading;
	BOOL							mIsHeading;
	
	NSOperationQueue				*mRequestStationStatusOperationQueue;
	NSOperationQueue				*mRequestVisibleStationStatusOperationQueue;
	
	BOOL							mNeedsUpdateRealTimeStatus;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) NSMutableArray *mFavoriteList;

- (IBAction)doSegmentedControlAction:(id)sender;
- (IBAction)doLocateSelf:(id)sender;
- (IBAction)doZoomIn:(id)sender;
- (IBAction)doZoomOut:(id)sender;
- (IBAction)doSwitchView:(id)sender;
- (IBAction)doSwitchFavoriteButton:(id)sender;

- (NSArray *)getFavorites;
- (void)saveFavorites;
- (void)addFavorite:(NSString *)stationID;
- (void)removeFavorite:(NSString *)stationID;
- (BOOL)isInFavoriteList:(NSString *)stationID;
- (void)reloadTable;

- (void)saveLocationLatitude:(double)latitude Longitude:(double)longitude;
- (void)setMapLocation:(CLLocationCoordinate2D)coordinate distance:(double)distance animated:(BOOL)animated;
- (void)addAnnotations;
//- (NSArray *)findVisibleAnnotations:(MKCoordinateRegion)currentRegion;
- (void)threadRequestVisibleAnnotations:(MKMapView *)mapView;
- (void)threadRequestAnnotationsForTable:(NSArray *)annotationArray;
@end



