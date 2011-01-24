//
//  ConnectionDelegate.h
//  VeloParis
//
//  Created by Mengke WANG on 4/2/10.
//  Copyright 2010 CocoaBob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParseStation.h"
#import "ParseStations.h"
#import "StationAnnotation.h"

@interface ConnectionDelegate : NSObject {
	NSMutableData	*receivedData;
}

+ (ConnectionDelegate *)sharedConnectionDelegate;
- (void)getAllStations;
- (void)threadParseAnnotations:(NSArray *)allStationsData;
@end
