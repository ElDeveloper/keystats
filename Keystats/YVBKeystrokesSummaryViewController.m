//
//  YVBKeystrokesSummaryView.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 1/7/14.
//  Copyright (c) 2014 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "YVBKeystrokesSummaryViewController.h"

@implementation YVBKeystrokesSummaryViewController

@synthesize totalCountLabel = _totalCountLabel;
@synthesize todayCountLabel = _todayCountLable;
@synthesize lastSevenDaysCountLabel = _lastSevenDaysCountLabel;
@synthesize lastThirtyDaysCountLabel = _lastThirtyDaysCountLabel;

-(id)init{
	if (self = [super initWithNibName:@"YVBKeystrokesSummaryView"
							   bundle:[NSBundle bundleForClass:[self class]]]) {
		// any other custom initializations should go here

	}
	return self;
}

-(void)updateWithTotalValue:(NSString *)total todayValue:(NSString *)today
		 lastSevenDaysValue:(NSString *)lastSevenDaysValue
	 andLastThirtyDaysValue:(NSString *)lastThirtyDaysValue{

	// update the values of the labels
	[_totalCountLabel setStringValue:total];
	[_todayCountLable setStringValue:today];
	[_lastSevenDaysCountLabel setStringValue:lastSevenDaysValue];
	[_lastThirtyDaysCountLabel setStringValue:lastThirtyDaysValue];
}

@end
