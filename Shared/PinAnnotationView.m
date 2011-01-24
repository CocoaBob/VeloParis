//
//  PinAnnotationView.m
//  VeloParis
//
//  Created by CocoaBob on 10-4-3.
//  Copyright 2010 CocoaBob. All rights reserved.
//

#import "PinAnnotationView.h"

@implementation PinAnnotationView

- (BOOL)canShowCallout{
	return YES;
}

- (CGPoint)centerOffset{
	return CGPointMake(5, -9);
}

-(CGPoint)calloutOffset{
	return CGPointMake(-5, -1);
}

@end
