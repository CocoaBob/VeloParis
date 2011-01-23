//
//  StationMark.h
//  VeloParis
//
//  Created by Mengke WANG on 4/2/10.
//  Copyright 2010 CocoaBob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface StationAnnotation : NSObject <NSCoding,MKAnnotation>{
	CLLocationCoordinate2D coordinate;
	NSString *subtitle;
	NSString *title;	
	NSString *stationID;
	BOOL	mIsRequested;
	BOOL	mIsRunning;
	float	mRatio;
	int		mNumAvailable;
}

@property (nonatomic,readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic,retain) NSString *stationID;
@property (nonatomic,retain) NSString *subtitle;
@property (nonatomic,retain) NSString *title;

- (id)initWithCoords:(CLLocationCoordinate2D)coords;
- (BOOL)isRequested;
- (void)setIsRequested:(BOOL)isRequested;
- (BOOL)isRunning;
- (void)setIsRunning:(BOOL)isRunning;
- (void)setRatio:(float)ratio;
- (float)ratio;
- (void)setNumAvailable:(int)numAvailable;
- (int)numAvailable;
@end
