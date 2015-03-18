//
//  YVBUtilities.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 2/28/15.
//  Copyright (c) 2015 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "YVBUtilities.h"

#import "NSDate+Utilities.h"

@implementation YVBUtilities

+(NSArray *)weeklyAverageForData:(NSArray *)dataArray perDate:(NSArray *)dateArray{
	float bufferData = 0.0, average = 0.0;
	BOOL isSameWeek = NO;

	NSDate *beginningDate = nil, *currentDate = nil;
	NSUInteger daysFound = 0, i = 0;

	NSMutableArray *averages = [NSMutableArray arrayWithCapacity:[dataArray count]];
	
	for (i = 0; i < [dataArray count]; i++){
		currentDate = [dateArray objectAtIndex:i];

		if (beginningDate == nil) {
			beginningDate = currentDate;
		}

		isSameWeek = [beginningDate isSameWeekAsDate:currentDate];

		if (isSameWeek) {
			bufferData += [[dataArray objectAtIndex:i] floatValue];
			daysFound ++;
		}

		// check if it's the last element, because otherwise
		// the average for that week will not be added to the output
		if (!isSameWeek || i==[dataArray count]-1) {
			average = bufferData/daysFound;

			// repeat the average value as many times as days you've found
			while (daysFound) {
				[averages addObject:[NSNumber numberWithFloat:average]];
				daysFound --;
			}

			// if the last element is in a separate week
			// just add the value to the averages array
			if (i < [dataArray count]-1) {
				beginningDate = currentDate;
				bufferData = [[dataArray objectAtIndex:i] longLongValue];
				daysFound = 1;
			}
			else if (!isSameWeek){
				[averages addObject:[NSNumber numberWithFloat:[[dataArray objectAtIndex:i] longLongValue]]];
			}
		}
	}
	// add some sort of assertion
	NSAssert([averages count] == [dataArray count] &&
			 [averages count] == [dateArray count],
			 @"Input data and averages must have the same shape averages:%lu dates:%lu data:%lu",
			 [averages count], [dateArray count], [dataArray count]);

	return (NSArray *)averages;
}

@end
