//
//  ParseStation.h
//  VeloParis
//
//  Created by Mengke WANG on 4/2/10.
//  Copyright 2010 CocoaBob. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParseStation : NSObject <NSXMLParserDelegate>{
	NSMutableDictionary *mStation;
    NSMutableString		*mNodeName;
	NSString			*mKey;
	NSString			*mValue;
}

- (NSDictionary *)parseXMLFromData:(NSData *)data parseError:(NSError **)error;

@end
