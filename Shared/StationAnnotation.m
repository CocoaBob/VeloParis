//
//  StationMark.m
//  VeloParis
//
//  Created by Mengke WANG on 4/2/10.
//  Copyright 2010 CocoaBob. All rights reserved.
//

#import "StationAnnotation.h"


@implementation StationAnnotation

@synthesize coordinate,subtitle,title,stationID;

-(id)initWithCoords:(CLLocationCoordinate2D)coords{
	self = [super init];

	coordinate = coords;

	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
	if (self) {
		coordinate.latitude = [coder decodeDoubleForKey:@"latitude"];
		coordinate.longitude = [coder decodeDoubleForKey:@"longitude"];
		title = [[coder decodeObjectForKey:@"title"] retain];
		stationID = [[coder decodeObjectForKey:@"stationID"] retain];
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeDouble:coordinate.latitude forKey:@"latitude"];
	[coder encodeDouble:coordinate.longitude forKey:@"longitude"];
    [coder encodeObject:title forKey:@"title"];
    [coder encodeObject:stationID forKey:@"stationID"];
}

- (void) dealloc{
	[stationID release];
	[title release];
	[subtitle release];
	[super dealloc];
}

- (BOOL)isRequested{
	return mIsRequested;
}

- (void)setIsRequested:(BOOL)isRequested{
	mIsRequested = isRequested;
}

- (BOOL)isRunning{
	return mIsRunning;
}

- (void)setIsRunning:(BOOL)isRunning{
	mIsRunning = isRunning;
}

- (void)setRatio:(float)ratio{
	mRatio = ratio;
}

- (float)ratio{
	return mRatio;
}

- (void)setNumAvailable:(int)numAvailable{
	mNumAvailable = numAvailable;
}

- (int)numAvailable{
	return mNumAvailable;
}

@end
