//
//  CustomizedTableCell.m
//  VeloParis
//
//  Created by CocoaBob on 10-4-6.
//  Copyright 2010 CocoaBob. All rights reserved.
//

#import "CustomizedTableCell.h"


@implementation CustomizedTableCell

@synthesize mLeftLabel,mRightLabel,mMiddleLabel,mDistanceLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		CGRect contentRect = [self.contentView bounds];
		CGRect labelFrame = CGRectMake(contentRect.origin.x + 4, contentRect.origin.y,240, contentRect.size.height - 16);
		mLeftLabel = [[UILabel alloc] initWithFrame:labelFrame];
		[mLeftLabel setBackgroundColor:[UIColor clearColor]];
		[mRightLabel setTextAlignment:UITextAlignmentLeft];
        [mLeftLabel setAdjustsFontSizeToFitWidth:YES];
		[mLeftLabel setFont:[UIFont systemFontOfSize:16]];
		[self.contentView addSubview:mLeftLabel];
		
		labelFrame = CGRectMake(contentRect.origin.x + 2 + 160, contentRect.origin.y + contentRect.size.height - 18 , 148, 18);
		mMiddleLabel = [[UILabel alloc] initWithFrame:labelFrame];
		[mMiddleLabel setBackgroundColor:[UIColor clearColor]];
		[mMiddleLabel setTextAlignment:UITextAlignmentRight];
        [mMiddleLabel setAdjustsFontSizeToFitWidth:YES];
		[mMiddleLabel setFont:[UIFont systemFontOfSize:14]];
		[self.contentView addSubview:mMiddleLabel];
		
		labelFrame = CGRectMake(contentRect.origin.x + 10, contentRect.origin.y + contentRect.size.height - 18 , 150, 18);
		mDistanceLabel = [[UILabel alloc] initWithFrame:labelFrame];
		[mDistanceLabel setBackgroundColor:[UIColor clearColor]];
		[mDistanceLabel setTextAlignment:UITextAlignmentLeft];
        [mDistanceLabel setAdjustsFontSizeToFitWidth:YES];
		[mDistanceLabel setTextColor:[UIColor grayColor]];
		[mDistanceLabel setFont:[UIFont systemFontOfSize:14]];
		[self.contentView addSubview:mDistanceLabel];
		
		labelFrame = CGRectMake(contentRect.origin.x + 3 + mLeftLabel.frame.size.width + 3, contentRect.origin.y, contentRect.size.width - contentRect.origin.x - 3 - mLeftLabel.frame.size.width - 3 - 10, contentRect.size.height - 16);
		mRightLabel = [[UILabel alloc] initWithFrame:labelFrame];
		[mRightLabel setBackgroundColor:[UIColor clearColor]];
		[mRightLabel setTextAlignment:UITextAlignmentLeft];
        [mRightLabel setAdjustsFontSizeToFitWidth:YES];
		[mRightLabel setFont:[UIFont systemFontOfSize:14]];
		[self.contentView addSubview:mRightLabel];
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}


- (void)dealloc {
	[mMiddleLabel release];
	[mLeftLabel release];
	[mRightLabel release];
	[mDistanceLabel release];
    [super dealloc];
}


@end
