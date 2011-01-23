//
//  ConnectionDelegate.m
//  VeloParis
//
//  Created by Mengke WANG on 4/2/10.
//  Copyright 2010 CocoaBob. All rights reserved.
//

#import "ConnectionDelegate.h"
#import "SynthesizeSingleton.h"


@implementation ConnectionDelegate

SYNTHESIZE_SINGLETON_FOR_CLASS(ConnectionDelegate);

- (void)dealloc{
	[receivedData release];
	[super dealloc];
}

- (NSMutableData *)receivedData{
	if (!receivedData) {
		receivedData = [[NSMutableData alloc] init];
	}
	return receivedData;
}

- (void)getAllStations{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSString *queryString = @"http://www.velib.paris.fr/service/carto";
	NSURL *url = [NSURL URLWithString:queryString];
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	[req setHTTPMethod:@"GET"];
	[NSURLConnection connectionWithRequest:req delegate:self];
}

#pragma mark -
#pragma mark NSURLConnection

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	[self.receivedData setLength:0];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.receivedData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	NSArray *parsedArray = [[ParseStations sharedParseStations] parseXMLFromData:self.receivedData parseError:nil];
	
	[NSThread detachNewThreadSelector:@selector(threadParseAnnotations:) toTarget:self withObject:parsedArray];
}

#pragma mark -
#pragma mark Methods

- (StationAnnotation *)createAnnotationFromDic:(NSDictionary *)oneStation{
	double latitude = [[oneStation valueForKey:@"lat"] doubleValue];
	double longitude = [[oneStation valueForKey:@"lng"] doubleValue];
	if (latitude && longitude) {
		CLLocationCoordinate2D coordinate;
		coordinate.latitude = latitude;
		coordinate.longitude = longitude;
		StationAnnotation *stationAnnotation = [[StationAnnotation alloc] initWithCoords:coordinate];
		[stationAnnotation setStationID:[oneStation valueForKey:@"number"]];
		[stationAnnotation setTitle:[oneStation valueForKey:@"name"]];
		return [stationAnnotation autorelease];
	}
	return nil;
}

- (void)threadParseAnnotations:(NSArray *)allStationsData{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableDictionary *allStationAnnotationData = [[NSMutableDictionary alloc] init];
	
	for (NSDictionary *oneStation in allStationsData) {
		StationAnnotation *oneStationAnnotation = [self createAnnotationFromDic:oneStation];
		if (oneStationAnnotation) {
			[allStationAnnotationData setObject:oneStationAnnotation forKey:[oneStation valueForKey:@"number"]];
		}
	}

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"AllStationAnnotationsDic.bin"];

	if ([NSKeyedArchiver archiveRootObject:allStationAnnotationData toFile:path]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"addAnnotationsNotification" object:nil];
	}
	[allStationAnnotationData release];
	
	[pool release];
	[NSThread exit];
}

@end
