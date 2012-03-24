//
//  VeloParisAppDelegate.m
//  VeloParis
//
//  Created by CocoaBob on 10-4-1.
//  Copyright CocoaBob 2010. All rights reserved.
//
#define DEGREES_TO_RADIANS(__ANGLE) ((__ANGLE) * M_PI / 180.0)
#define RADIANS_TO_DEGREES(__RADIANS) ((__RADIANS) * 180 / M_PI)

#import "AppDelegate_iPhone.h"

@interface AppDelegate_iPhone()

- (void)saveLocationLatitude:(double)latitude Longitude:(double)longitude;

@end


@implementation AppDelegate_iPhone

@synthesize window,mFavoriteList;

- (void)awakeFromNib{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(addAnnotationsNotification:)
												 name:@"addAnnotationsNotification" 
											   object:nil];
	
	//Why retain? If not, these images will be release when the application goes into background
	mPinGreen = [[UIImage imageNamed:@"pinGreen.png"] retain];
	mPinYellowGreen = [[UIImage imageNamed:@"pinYellowGreen.png"] retain];
	mPinYellow = [[UIImage imageNamed:@"pinYellow.png"] retain];
	mPinOrange = [[UIImage imageNamed:@"pinOrange.png"] retain];
	mPinRed = [[UIImage imageNamed:@"pinRed.png"] retain];
	mPinPurple = [[UIImage imageNamed:@"pinPurple.png"] retain];
	mFavoriteOn = [[UIImage imageNamed:@"FavoriteOn.png"] retain];
	mFavoriteOff = [[UIImage imageNamed:@"FavoriteOff.png"] retain];
	
	mOperationsCountForMap = 0;
	mOperationsCountForTable = 0;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[mLocationManager release];
    [window release];
	[latestThreadTime release];
	[mAllStationAnnotationData release];
	[mUserHeadingView release];
	[mPinGreen release];
	[mPinYellowGreen release];
	[mPinYellow release];
	[mPinOrange release];
	[mPinRed release];
	[mPinPurple release];
	[mFavoriteOn release];
	[mFavoriteOff release];
	[mRequestStationStatusOperationQueue release];
	[mRequestVisibleStationStatusOperationQueue release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if (![[NSUserDefaults standardUserDefaults] boolForKey:kIsNotFirstTimeLaunch]) {
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionary]];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kIsNotFirstTimeLaunch];
		[self saveLocationLatitude:48.856660f Longitude:2.350996f];//Paris
	}
	
	mRequestStationStatusOperationQueue = [[NSOperationQueue alloc] init];
	[mRequestStationStatusOperationQueue setMaxConcurrentOperationCount:10];
	
	mRequestVisibleStationStatusOperationQueue = [[NSOperationQueue alloc] init];
	[mRequestStationStatusOperationQueue setMaxConcurrentOperationCount:2];
	
	mLocationManager = [[CLLocationManager alloc] init];
	[mLocationManager setDelegate:self];
	[mLocationManager setHeadingFilter:1];
	
	self.mFavoriteList = [[self getFavorites] mutableCopy];
	if (!self.mFavoriteList) {
		self.mFavoriteList = [[NSMutableArray alloc] init];
	}
	
	double latitude = [[[NSUserDefaults standardUserDefaults] valueForKey:kLastLocationLatitude] doubleValue];
	double longitude = [[[NSUserDefaults standardUserDefaults] valueForKey:kLastLocationLongitude] doubleValue];
	
	CLLocationCoordinate2D coordinate;
	
	coordinate.latitude = latitude;
	coordinate.longitude = longitude;
	
	[self setMapLocation:coordinate distance:300 animated:NO];
	
	[mMapView setShowsUserLocation:YES];
	[mMapView setMapType:[[NSUserDefaults standardUserDefaults] integerForKey:kMapType]];
	
	[mMapTypeSwitch setSelectedSegmentIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kMapType]];
	
	[mTableView setDataSource:self];
	[window makeKeyAndVisible];
	
	[self addAnnotations];
	
	return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
	if (mDidAddAllAnnotations && mNeedsUpdateRealTimeStatus) {
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadRequestVisibleAnnotations:) object:mMapView];
//		[theOp setThreadPriority:0.01f];
		[mRequestVisibleStationStatusOperationQueue addOperation:theOp];
		[theOp release];
	}
	
	[self doLocateSelf:self];
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	NSArray *allAnnotations = [[NSArray alloc]initWithArray:[mMapView annotations]];
	for (StationAnnotation *stationAnnotation in allAnnotations)
	{
		if (![stationAnnotation isKindOfClass:[MKUserLocation class]]) {
			[stationAnnotation setIsRequested:NO];
		}
	}
	[allAnnotations release];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
	[mMapView setCenterCoordinate:newLocation.coordinate animated:YES];
	[mLocationManager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
	[mLocationManager stopUpdatingLocation];
	[mLocationManager stopUpdatingHeading];
	mIsHeading = NO;
	[mUserHeadingView setHidden:YES];
	[[mMapView viewForAnnotation:[mMapView userLocation]] setTransform:CGAffineTransformIdentity];
	/*
	 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:[NSString stringWithFormat:@"%@",NSLocalizedString(@"LocationManagerErrorMessage",nil)] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	 [alert show];
	 [alert release];
	 */
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading{
	float headingAccuracy = [newHeading trueHeading];
	if (headingAccuracy > 0) {
		//CGAffineTransform mapTransform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(headingAccuracy)*-1);//如果你想整个屏幕一起跟着旋转
		CGAffineTransform pinTransform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(headingAccuracy));
		//[mMapView viewForAnnotation:[mMapView userLocation]].transform = pinTransform;
		mUserHeadingView.transform = pinTransform;
		[mUserHeadingView setHidden:NO];
		
		/*如果你想整个屏幕一起跟着旋转
		 for (UIView *subView in [mMapView subviews]) {
		 //NSLog(@"%@",[subView description]);
		 if(![[[subView class] description] isEqualToString:@"UIImageView"]){
		 subView.transform = mapTransform;
		 }
		 }
		 
		 for (StationAnnotation *annotation in [mAllStationAnnotationData allValues]) {
		 [mMapView viewForAnnotation:annotation].transform = pinTransform;
		 }
		 */
	}
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager{//遇到电磁干扰时，是否弹出按8字形摆动iPhone校准指南针的界面。
	return YES;
}

#pragma mark -
#pragma mark Variables

- (UIImageView *)userHeadingView{
	if (!mUserHeadingView) {
		UIImage *imageUserHeading = [UIImage imageNamed:@"UserHeading.png"];
		mUserHeadingView = [[UIImageView alloc] initWithImage:imageUserHeading];
		[mUserHeadingView setHidden:YES];
	}
	return mUserHeadingView;
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
	[self saveLocationLatitude:mapView.centerCoordinate.latitude Longitude:mapView.centerCoordinate.longitude];
	if (mDidAddAllAnnotations) {
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadRequestVisibleAnnotations:) object:mapView];
		[mRequestVisibleStationStatusOperationQueue addOperation:theOp];
		[theOp release];
	}
	/*如果你想整个屏幕都转动的话，需要在UserLocation离开屏幕中心时停止旋转屏幕……我找不到更好的算法了……
	 CLLocationCoordinate2D centerCoordinate = [mMapView centerCoordinate];
	 CLLocationCoordinate2D userCoordinate = [mMapView userLocation].coordinate;
	 if (centerCoordinate.latitude != userCoordinate.latitude &&
	 centerCoordinate.longitude != userCoordinate.longitude) {
	 [mUserHeadingView setHidden:YES];
	 [mLocationManager stopUpdatingHeading];
	 }
	 for (UIView *subView in [mMapView subviews]) {
	 if(![[[subView class] description] isEqualToString:@"UIImageView"]){
	 subView.transform = CGAffineTransformIdentity;
	 }
	 }
	 
	 for (StationAnnotation *annotation in [mAllStationAnnotationData allValues]) {
	 [mMapView viewForAnnotation:annotation].transform = CGAffineTransformIdentity;
	 }
	 */
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	if([annotation isKindOfClass:[StationAnnotation class]]){//[annotation isKindOfClass:[StationAnnotation class]]//[annotation isKindOfClass:[MKUserLocation class]]
		StationAnnotation *oneStationAnnotation = (StationAnnotation *)annotation;
		PinAnnotationView *pinAnnotationView = [(PinAnnotationView *) [mMapView dequeueReusableAnnotationViewWithIdentifier:@"PinAnnotationView"] retain];
		if (!pinAnnotationView) {
			pinAnnotationView = [[PinAnnotationView alloc] initWithAnnotation:oneStationAnnotation reuseIdentifier:@"PinAnnotationView"];
			[pinAnnotationView setImage:mPinPurple];
			
			UIButton *leftCalloutAccessoryView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
			if ([self isInFavoriteList:[oneStationAnnotation stationID]]) {
				[leftCalloutAccessoryView setImage:mFavoriteOn forState:UIControlStateNormal];
			}
			else {
				[leftCalloutAccessoryView setImage:mFavoriteOff forState:UIControlStateNormal];
			}
			[leftCalloutAccessoryView addTarget:self action:@selector(doSwitchFavoriteButton:) forControlEvents:UIControlEventTouchUpInside];
			[pinAnnotationView setLeftCalloutAccessoryView:leftCalloutAccessoryView];
			[leftCalloutAccessoryView release];
		}
		else {
			[pinAnnotationView setAnnotation:oneStationAnnotation];
		}
		
		return [pinAnnotationView autorelease];
	}
	
	return nil;//Return nil to show the MKUserLocation
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
	NSString *stationID = [(StationAnnotation *)[view annotation] stationID];
	if ([self isInFavoriteList:stationID]) {
		[(UIButton *)control setImage:mFavoriteOn forState:UIControlStateNormal];
	}
	else {
		[(UIButton *)control setImage:mFavoriteOff forState:UIControlStateNormal];
	}
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views{
	if ([views count]>1) {
		mDidAddAllAnnotations = YES;
		if ([[mSuperView subviews]lastObject] == mTableView) {
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadRequestAnnotationsForTable:) object:self.mFavoriteList];
			[mRequestVisibleStationStatusOperationQueue addOperation:theOp];
			[theOp release];
		}
		else if ([[mSuperView subviews]lastObject] == mMapView) {
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadRequestVisibleAnnotations:) object:mapView];
			[mRequestVisibleStationStatusOperationQueue addOperation:theOp];
			[theOp release];
		}
		
		[self reloadTable];
	}
	
	UIView *userLocationView = [mMapView viewForAnnotation:[mMapView userLocation]];
	if (userLocationView) {
		UIImageView *imageView = [self userHeadingView];
		[imageView setFrame:CGRectMake(userLocationView.frame.origin.x + (userLocationView.frame.size.width - imageView.frame.size.width)/2, userLocationView.frame.origin.y + (userLocationView.frame.size.height - imageView.frame.size.height)/2, imageView.frame.size.width, imageView.frame.size.height)];
		[userLocationView addSubview:imageView];
		mDidAddUserLocationAnnotation = YES;
	}
}

#pragma mark -
#pragma mark Actions

- (IBAction)doLocateSelf:(id)sender{
	CGPoint userLocationPoint = [mMapView convertCoordinate:[mMapView userLocation].coordinate toPointToView:mMapView];
	if ([mLocationManager locationServicesEnabled]) {
		[mLocationManager startUpdatingLocation];
	}
	if ([mLocationManager headingAvailable] && mDidAddUserLocationAnnotation) {
		if (userLocationPoint.x > 159.0f && userLocationPoint.x < 161.0f &&
			userLocationPoint.y > 207.0f && userLocationPoint.y < 209.0f){
			if (!mIsHeading) {
				[mLocationManager startUpdatingHeading];
				mIsHeading = YES;
			}
			else {
				[mLocationManager stopUpdatingHeading];
				mIsHeading = NO;
				[mUserHeadingView setHidden:YES];
				[[mMapView viewForAnnotation:[mMapView userLocation]] setTransform:CGAffineTransformIdentity];
			}
		}
	}
}

- (IBAction)doZoomIn:(id)sender{
	MKCoordinateRegion region = mMapView.region;
	region.span.latitudeDelta=region.span.latitudeDelta * 0.4;
	region.span.longitudeDelta=region.span.longitudeDelta * 0.4;
	[mMapView setRegion:region animated:YES];
}

- (IBAction)doZoomOut:(id)sender{
	MKCoordinateRegion region = mMapView.region;
	region.span.latitudeDelta=region.span.latitudeDelta * 1.3;
	region.span.longitudeDelta=region.span.longitudeDelta * 1.3;
	[mMapView setRegion:region animated:YES];
}

- (IBAction)doSwitchView:(id)sender{
	[UIView beginAnimations:@"animationID" context:nil];
	[UIView setAnimationDuration:0.3f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationRepeatAutoreverses:NO];
	if ([[mSuperView subviews]lastObject]!=mMapView) {
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:mSuperView cache:YES];
		if (mDidAddAllAnnotations) {
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadRequestVisibleAnnotations:) object:mMapView];
			[mRequestVisibleStationStatusOperationQueue addOperation:theOp];
			[theOp release];
		}
		[mSuperView bringSubviewToFront:mMapView];
		[mZoomOutButton setEnabled:YES];
		[mZoomInButton setEnabled:YES];
		[mLocateSelfButton setEnabled:YES];
		[mSettingButton setEnabled:YES];
		[mFavoritesButton setEnabled:YES];
	}
	else if(![sender isKindOfClass:[AppDelegate_iPhone class]]){
		switch ([sender tag]) {
			case 0:
				[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:mSuperView cache:YES];
				if (mDidAddAllAnnotations) {
					NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadRequestAnnotationsForTable:) object:self.mFavoriteList];
					[mRequestVisibleStationStatusOperationQueue addOperation:theOp];
					[theOp release];
				}
				[self reloadTable];
				[mSettingButton setEnabled:NO];
				[mFavoritesButton setEnabled:YES];
				[mSuperView bringSubviewToFront:mTableView];
				break;
			case 1:
				[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:mSuperView cache:YES];
				[mSettingButton setEnabled:YES];
				[mFavoritesButton setEnabled:NO];
				[mSuperView bringSubviewToFront:mSettingView];
				break;
			default:
				break;
		}
		[mZoomOutButton setEnabled:NO];
		[mZoomInButton setEnabled:NO];
		[mLocateSelfButton setEnabled:NO];
	}
	
	[UIView commitAnimations];
}

- (IBAction)doSegmentedControlAction:(id)sender{
	if (sender == mMapTypeSwitch) {
		switch (((UISegmentedControl *)sender).selectedSegmentIndex)
		{
			case 0:
			{
				mMapView.mapType = MKMapTypeStandard;
				[[NSUserDefaults standardUserDefaults] setInteger:MKMapTypeStandard forKey:kMapType];
				break;
			} 
			case 1:
			{
				mMapView.mapType = MKMapTypeSatellite;
				[[NSUserDefaults standardUserDefaults] setInteger:MKMapTypeSatellite forKey:kMapType];
				break;
			} 
			default:
			{
				mMapView.mapType = MKMapTypeHybrid;
				[[NSUserDefaults standardUserDefaults] setInteger:MKMapTypeHybrid forKey:kMapType];
				break;
			} 
		}
	}
	else if(sender == mRefreshCacheButton){
		[mMapView removeAnnotations:[mMapView annotations]];
		[[ConnectionDelegate sharedConnectionDelegate] getAllStations];
	}
	[self doSwitchView:self];
}

- (IBAction)doSwitchFavoriteButton:(id)sender{
	PinAnnotationView *pinAnnotationView = (PinAnnotationView *)[[sender superview] superview];
	StationAnnotation *stationAnnotation = (StationAnnotation *)[pinAnnotationView annotation];
	NSString *stationID = [stationAnnotation stationID];
	
	if ([self isInFavoriteList:stationID]) {
		[self removeFavorite:stationID];
		[(UIButton *)sender setImage:mFavoriteOff forState:UIControlStateNormal];
	}
	else {
		[self addFavorite:stationID];
		[(UIButton *)sender setImage:mFavoriteOn forState:UIControlStateNormal];
	}
}

#pragma mark -
#pragma mark Methods

- (void)addFavorite:(NSString *)stationID{
	if (![self.mFavoriteList containsObject:stationID]) {
		[self.mFavoriteList addObject:stationID];
		[self saveFavorites];
	}
}

- (void)removeFavorite:(NSString *)stationID{
	if ([self.mFavoriteList containsObject:stationID]) {
		[self.mFavoriteList removeObject:stationID];
		[self saveFavorites];
	}
}

- (BOOL)isInFavoriteList:(NSString *)stationID{
	return [self.mFavoriteList containsObject:stationID];
}

- (void)saveLocationLatitude:(double)latitude Longitude:(double)longitude{
	NSNumber *locationLatitude = [NSNumber numberWithDouble:latitude];
	NSNumber *locationLongitude = [NSNumber numberWithDouble:longitude];
	[[NSUserDefaults standardUserDefaults] setValue:locationLatitude forKey:kLastLocationLatitude];
	[[NSUserDefaults standardUserDefaults] setValue:locationLongitude forKey:kLastLocationLongitude];
}

- (void)setMapLocation:(CLLocationCoordinate2D)coordinate distance:(double)distance animated:(BOOL)animated{
	[self saveLocationLatitude:coordinate.latitude Longitude:coordinate.longitude ];
	MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, distance, distance); 
    MKCoordinateRegion adjustedRegion = [mMapView regionThatFits:viewRegion];
	[mMapView setRegion:adjustedRegion animated:animated];
}

- (void)addAnnotations{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"AllStationAnnotationsDic.bin"];
	
	if (mAllStationAnnotationData) {
		[mAllStationAnnotationData release];
		mAllStationAnnotationData= nil;
	}
	
	mAllStationAnnotationData = [[NSKeyedUnarchiver unarchiveObjectWithFile:path] retain];
	
	if (mAllStationAnnotationData) {
		mDidAddAllAnnotations = NO;
		NSArray *oldAnnotations = [mMapView annotations];
		if (oldAnnotations) {
			[mMapView removeAnnotations:oldAnnotations];
		}
		
		[mMapView performSelectorOnMainThread:@selector(addAnnotations:) withObject:[mAllStationAnnotationData allValues] waitUntilDone:YES];

		//Refresh pins
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadRequestVisibleAnnotations:) object:mMapView];
		[mRequestVisibleStationStatusOperationQueue addOperation:theOp];
		[theOp release];
	}
	else {
		[[ConnectionDelegate sharedConnectionDelegate] getAllStations];
	}
	
}

- (void)setAnnotationView:(StationAnnotation *)stationAnnotation strAvailable:(NSString *)strAvailable strFree:(NSString *)strFree strTotal:(NSString *)strTotal{	
	[stationAnnotation setSubtitle:[NSString stringWithFormat:@" %@ / %@",strAvailable,strTotal]];
	
	PinAnnotationView *pinAnnotationView = (PinAnnotationView *)[mMapView viewForAnnotation:stationAnnotation];
	
	float numFree = [strFree floatValue];
	float numAvailable = [strAvailable floatValue];
	float ratio = numAvailable / (numAvailable + numFree);
	[stationAnnotation setRatio:ratio];
	[stationAnnotation setNumAvailable:numAvailable];
	if (pinAnnotationView) {
		if (numAvailable < 2) {
			[pinAnnotationView performSelectorOnMainThread:@selector(setImage:) withObject:mPinRed waitUntilDone:NO];
		}
		else if(ratio < 0.25f) {
			[pinAnnotationView performSelectorOnMainThread:@selector(setImage:) withObject:mPinOrange waitUntilDone:NO];
		}
		else if(ratio >= 0.25f && ratio < 0.50f) {
			[pinAnnotationView performSelectorOnMainThread:@selector(setImage:) withObject:mPinYellow waitUntilDone:NO];
		}
		else if(ratio >= 0.50f && ratio < 1.0f) {
			[pinAnnotationView performSelectorOnMainThread:@selector(setImage:) withObject:mPinYellowGreen waitUntilDone:NO];
		}
		else{
			[pinAnnotationView performSelectorOnMainThread:@selector(setImage:) withObject:mPinGreen waitUntilDone:NO];
		}
	}
	else {
		NSLog(@"not created yet");
	}
}

- (void)threadSetAnnotationSubTitle:(StationAnnotation *)stationAnnotation{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	mOperationsCountForMap += 1;
	
	NSData *responseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.velib.paris.fr/service/stationdetails/%@",[stationAnnotation stationID]]]];
	if (responseData) {
		ParseStation *parser = [[ParseStation alloc] init];
		NSDictionary *infoDic = [parser parseXMLFromData:responseData parseError:nil];
		[self setAnnotationView:stationAnnotation strAvailable:[infoDic valueForKey:@"available"] strFree:[infoDic valueForKey:@"free"] strTotal:[infoDic valueForKey:@"total"]];
		[stationAnnotation setIsRequested:YES];//Avoid being requested again
		[parser release];
	}
	
	mOperationsCountForMap -= 1;
	if (mOperationsCountForMap <= 0) {
		mOperationsCountForMap = 0;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		[mMapView setNeedsDisplay];
	}
}

- (void)threadRequestVisibleAnnotations:(MKMapView *)mapView{
	MKCoordinateRegion currentRegion = mapView.region;
	CLLocationCoordinate2D currentCenter = currentRegion.center;
	MKCoordinateSpan currentSpan = currentRegion.span;
	
	double latitudeRadius = currentSpan.latitudeDelta/2;
	double longitudeRadius = currentSpan.longitudeDelta/2;
	
	[mRequestStationStatusOperationQueue cancelAllOperations];
	NSArray *allAnnotations = [[NSArray alloc]initWithArray:[mMapView annotations]];
	for (StationAnnotation *stationAnnotation in allAnnotations)
	{
		if (![stationAnnotation isKindOfClass:[MKUserLocation class]] &&
			![stationAnnotation isRequested] &&
			stationAnnotation.coordinate.latitude >= currentCenter.latitude - latitudeRadius&&
			stationAnnotation.coordinate.latitude <= currentCenter.latitude + latitudeRadius &&
			stationAnnotation.coordinate.longitude >= currentCenter.longitude - longitudeRadius&&
			stationAnnotation.coordinate.longitude <= currentCenter.longitude + longitudeRadius) {
			
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadSetAnnotationSubTitle:) object:stationAnnotation];
			[mRequestStationStatusOperationQueue addOperation:theOp];
			[theOp release];
		}
	}
	
	[allAnnotations release];
}

- (void)threadSetAnnotationSubTitleForTable:(StationAnnotation *)stationAnnotation{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	mOperationsCountForTable += 1;
	
	NSData *responseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.velib.paris.fr/service/stationdetails/%@",[stationAnnotation stationID]]]];
	if (responseData) {
		ParseStation *parser = [[ParseStation alloc] init];
		NSDictionary *infoDic = [parser parseXMLFromData:responseData parseError:nil];
		[self setAnnotationView:stationAnnotation strAvailable:[infoDic valueForKey:@"available"] strFree:[infoDic valueForKey:@"free"] strTotal:[infoDic valueForKey:@"total"]];
		[stationAnnotation setIsRequested:YES];//Avoid being requested again
		[parser release];
	}
	
	mOperationsCountForTable -= 1;
	if (mOperationsCountForTable <= 0) {
		mOperationsCountForTable = 0;
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		[self performSelectorOnMainThread:@selector(reloadTable) withObject:nil waitUntilDone:NO];
	}
}

- (void)threadRequestAnnotationsForTable:(NSArray *)stationIDArray{
	[mRequestStationStatusOperationQueue cancelAllOperations];
	for (NSString *stationID in stationIDArray)
	{
		StationAnnotation *stationAnnotation = [mAllStationAnnotationData valueForKey:stationID];
		
		if (![stationAnnotation isKindOfClass:[MKUserLocation class]] &&
			![stationAnnotation isRequested]) {
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(threadSetAnnotationSubTitleForTable:) object:stationAnnotation];
			[mRequestStationStatusOperationQueue addOperation:theOp];
			[theOp release];
		}
	}
}

- (NSArray *)getFavorites{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"favorites.plist"];
	return [NSArray arrayWithContentsOfFile:path];
}

- (void)saveFavorites{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"favorites.plist"];
	[self.mFavoriteList writeToFile:path atomically:YES];
}

- (void)reloadTable{
	[mTableView reloadData];
	[mTableView setNeedsDisplay];
}

#pragma mark -
#pragma mark Notifications

- (void)addAnnotationsNotification:(NSNotification *)notification{
	[self addAnnotations];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (mAllStationAnnotationData) {
		return [self.mFavoriteList count];
	}
	else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    CustomizedTableCell *cell = (CustomizedTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[CustomizedTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	else {
		[[cell mMiddleLabel] setHidden:NO];
		[[cell mRightLabel] setHidden:NO];
	}
	
	NSString *stationID = [self.mFavoriteList objectAtIndex:indexPath.row];
	StationAnnotation *stationAnnotation = [mAllStationAnnotationData valueForKey:stationID];
	NSString *subTitle = [stationAnnotation subtitle];
	cell.mLeftLabel.text = [NSString stringWithFormat:@"%@",[[[stationAnnotation title] componentsSeparatedByString:@" - "] lastObject]];
	cell.mMiddleLabel.text = subTitle?[NSString stringWithFormat:@" %@",subTitle]:@"";
    cell.mRightLabel.text = [NSString stringWithFormat:@"  %@",stationID];
	CLLocation *location = [[CLLocation alloc] initWithLatitude:stationAnnotation.coordinate.latitude longitude:stationAnnotation.coordinate.longitude];
	CLLocation *userLocation = [mLocationManager location];
	cell.mDistanceLabel.text = userLocation?[NSString stringWithFormat:@"Distance %0.2f km",[userLocation getDistanceFrom:location]/1000]:@"";
	[location release];
    
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSString *stationID = [self.mFavoriteList objectAtIndex:indexPath.row];
		StationAnnotation *stationAnnotation = [mAllStationAnnotationData valueForKey:stationID];
		PinAnnotationView *pinAnnotationView = (PinAnnotationView *)[mMapView viewForAnnotation:stationAnnotation];
		[(UIButton *)[pinAnnotationView leftCalloutAccessoryView] setImage:mFavoriteOff forState:UIControlStateNormal];
		[self.mFavoriteList removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self saveFavorites];
	} 
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *stationID = [self.mFavoriteList objectAtIndex:indexPath.row];
	StationAnnotation *stationAnnotation = [mAllStationAnnotationData valueForKey:stationID];
	[self setMapLocation:stationAnnotation.coordinate distance:200 animated:NO];
	[self doSwitchView:self];
	[mMapView selectAnnotation:stationAnnotation animated:YES];
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	//- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	CustomizedTableCell *tableCell = (CustomizedTableCell *)[tableView cellForRowAtIndexPath:indexPath];
	[[tableCell mMiddleLabel] setHidden:YES];
	[[tableCell mRightLabel] setHidden:YES];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath{
	CustomizedTableCell *tableCell = (CustomizedTableCell *)[tableView cellForRowAtIndexPath:indexPath];
	[[tableCell mMiddleLabel] setHidden:NO];
	[[tableCell mRightLabel] setHidden:NO];
}
@end
