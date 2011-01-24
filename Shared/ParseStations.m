//
//  ParseStations.m
//  VeloParis
//
//  Created by Mengke WANG on 4/2/10.
//  Copyright 2010 CocoaBob. All rights reserved.
//

#import "ParseStations.h"

#import "SynthesizeSingleton.h"

@implementation ParseStations

SYNTHESIZE_SINGLETON_FOR_CLASS(ParseStations);

- (NSArray *)parseXMLFromData:(NSData *)data parseError:(NSError **)error;
{
	mStations = [[NSMutableArray alloc] init];
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	[parser setDelegate:self];
	
	[parser parse];
	
	[parser release];
	
	return mStations;
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
	attributes:(NSDictionary *)attributeDict{
	if([elementName isEqualToString:@"marker"]) {
		mStation = attributeDict;
	}
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName{
	if([elementName isEqualToString:@"marker"]) {
		[mStations addObject:mStation];
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	/*
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:[NSString stringWithFormat:@"%@\n%@",NSLocalizedString(@"ParseErrorMessage",nil),[parseError localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
	*/
}

- (void)dealloc
{
	[mStations release];
	[super dealloc];
}
@end
