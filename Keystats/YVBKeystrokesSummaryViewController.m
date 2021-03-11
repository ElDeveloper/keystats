//
//  YVBKeystrokesSummaryView.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 1/7/14.
//  Copyright (c) 2014 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "YVBKeystrokesSummaryViewController.h"

#import "NSDate+Utilities.h"
#import "YVBUtilities.h"
#import "KeystatsSettings.h"

@implementation YVBKeystrokesSummaryViewController

@synthesize totalCountLabel = _totalCountLabel;
@synthesize todayCountLabel = _todayCountLable;
@synthesize lastSevenDaysCountLabel = _lastSevenDaysCountLabel;
@synthesize lastThirtyDaysCountLabel = _lastThirtyDaysCountLabel;
@synthesize earliestDateLabel = _earliestDateLabel;
@synthesize dailyKeystrokesView = _dailyKeystrokesView;
@synthesize dailyKeystrokesLabel = _dailyKeystrokesLabel;

-(id)init{
	if (self = [super initWithNibName:@"YVBKeystrokesSummaryView"
							   bundle:[NSBundle bundleForClass:[self class]]]) {
		// any other custom initializations should go here
		__previous = 0;
		__knownMax = 0;

		__formatter = [[NSNumberFormatter alloc] init];
		[__formatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[__formatter setGroupingSize:3];
		[__formatter setHasThousandSeparators:YES];
		[__formatter setThousandSeparator:@","];

		__datesData = nil;
		__keystrokesData = nil;

		__canDrawPlot = NO;

        __settings = [KeystatsSettings sharedController];
        _plotColor = [__settings color];

		// we will reload the data every 20 minutes if this gets
		// fired, meaning if there's enough data to be plotted
		__plotTimer = [NSTimer timerWithTimeInterval:1200
											  target:__graph
											selector:@selector(reloadData)
											userInfo:nil
											 repeats:YES];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if ([keyPath isEqualToString:@"color"]) {
		_plotColor = [change objectForKey:@"new"];

        [self _drawKeystrokesPlotWithCachedData];
	}
}

-(void)updateWithTotalValue:(NSString *)total todayValue:(NSString *)today
		 lastSevenDaysValue:(NSString *)lastSevenDaysValue
	 andLastThirtyDaysValue:(NSString *)lastThirtyDaysValue{
	NSNumber *todayNumber = [__formatter numberFromString:today];
	NSInteger current = [todayNumber integerValue];
    
	// we pretend the latest point is up to date by retrieving the current
	// value of the todayCountLabel
    NSInteger count = [__keystrokesData count];
    if (count) {
        [__keystrokesData replaceObjectAtIndex:count-1
                                    withObject:todayNumber];
    }

	// update the values of the labels
	[_totalCountLabel setStringValue:total];
	[_todayCountLable setStringValue:today];
	[_lastSevenDaysCountLabel setStringValue:lastSevenDaysValue];
	[_lastThirtyDaysCountLabel setStringValue:lastThirtyDaysValue];

	// plotting logic:
	// check whether or not we need to update the plot
	if (__canDrawPlot) {
		__averageData = [[YVBUtilities weeklyAverageForData:__keystrokesData
													perDate:__datesData] copy];

		if (current > __knownMax) {
			[self _createPlot];
			__previous = current;
		}
		// guarantee that we are updating at least every 30 keystrokes
		if (current-__previous > (__knownMax*0.033 > 30 ? __knownMax*0.033 : 30) ) {
			[__graph reloadData];
			__previous = current;
		}
	}
}

-(void)_drawKeystrokesPlotWithCachedData {
    // This method relies on the __datesData and __keystrokesData private properties.
    // Both of these are updated by the data manager.
    //
    // every time we are asked to update the values let's force a hard restart
    __previous = 0;

    // figure out if we have today in the array
    NSUInteger indexOfToday = [__datesData indexOfObjectPassingTest:
     ^BOOL(id obj, NSUInteger idx, BOOL *stop){
         return [(NSDate *)obj isToday];
     }];

    // add an empty entry if today's date is not saved already,
    // this way the plot updating routine will work seamlessly
    if(indexOfToday == NSNotFound){
        [__datesData addObject:[NSDate todayWithoutTime]];
        [__keystrokesData addObject:[NSNumber numberWithLongLong:0]];

        // be consistent and remove the extra object
        [__datesData removeObjectAtIndex:0];
        [__keystrokesData removeObjectAtIndex:0];
    }

    // calculate the average once we've settled in on the values
    // we will use for the keystrokes and the dates
    __averageData = [[YVBUtilities weeklyAverageForData:__keystrokesData
                                                perDate:__datesData] copy];

    // convenience variable to check in other places whether
    // or not we are drawing the keystrokes per day plot
    __canDrawPlot = [__datesData count] > 2;

    if (__canDrawPlot) {
        // remove the "loading" label
        [_dailyKeystrokesLabel setStringValue:@""];
        [self _createPlot];

        if (![__plotTimer isValid]){
            [__plotTimer fire];
        }
    }
    else{
        [_dailyKeystrokesLabel setStringValue:@"Not Enough Data To Display Plot"];
    }
}

-(void)updateDailyKeystrokesPlot:(NSArray *)data{
	__datesData = [NSMutableArray arrayWithArray:[[data objectAtIndex:0] copy]];
	__keystrokesData = [NSMutableArray arrayWithArray:[[data objectAtIndex:1] copy]];

    [self _drawKeystrokesPlotWithCachedData];
}

-(void)_createPlot{
	// this code was based in the DatePlot example from CorePlot
	NSDate *refDate = [__datesData objectAtIndex:0];
	NSTimeInterval totalDateRange = [[__datesData objectAtIndex:[__datesData count]-1] timeIntervalSinceDate:refDate];
	double maxKeystrokes = [[__keystrokesData valueForKeyPath:@"@max.intValue"] doubleValue];

	// divide the total number of seconds by the number of seconds in a day
	NSUInteger numberOfDaysToDisplay = totalDateRange/(D_DAY);

	// determines the spacing between bars, we need this information in several
	// places to correctly fit the plot and have nice spacing
	float padding = totalDateRange/numberOfDaysToDisplay;

	// we use ceil here to create a number with a small "padding"
	maxKeystrokes = ceil(maxKeystrokes + (0.11*maxKeystrokes));

	// we set the tick locations manually because:
	//  * we've found that daylight savings screw the location of each date
	//  * cleaning date objects for them to be comparable didn't prove very reliable
	//  * we can guarantee that ticks will be located at the center of every bar
	//  * this is the cleanest way to guarantee the previous point
	NSMutableSet *dateTicks = [[NSMutableSet alloc] init];
	NSTimeInterval interval = 0;
	NSDate *currentDate = nil;
	NSInteger distanceInDays = 0;
	for (NSUInteger t = 0; t < [__datesData count]; t++) {
		currentDate = [__datesData objectAtIndex:t];

		// for more information on this rationale see:
		// numberForPlot:field:recordIndex:
		interval = [currentDate timeIntervalSinceDate:refDate];
		[dateTicks addObject:[NSDecimalNumber numberWithDouble:interval]];

		// don't raise an exception for trying to acces size+1 in the dates array
		if (t != [__datesData count]-1){
			distanceInDays = [currentDate distanceInDaysToDate:[__datesData objectAtIndex:t+1]];

			if(distanceInDays != 1){
				for (int i = 1; i < [currentDate distanceInDaysToDate:[__datesData objectAtIndex:t+1]]; i++) {
					[dateTicks addObject:[NSDecimalNumber numberWithDouble:interval + D_DAY*i]];
				}
			}
		}
	}

	// __knownMax sets when we have to reload the full plot
	__knownMax = maxKeystrokes;

	CPTColor *dataColor = [CPTColor colorWithComponentRed:[_plotColor redComponent]
													green:[_plotColor greenComponent]
													 blue:[_plotColor blueComponent]
													alpha:CPTFloat(1.0f)];
	CPTColor *fillingColor = [CPTColor colorWithComponentRed:[_plotColor redComponent]
													   green:[_plotColor greenComponent]
														blue:[_plotColor blueComponent]
													   alpha:CPTFloat(0.5)];

	CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
	[textStyle setFontSize:12.0f];
	[textStyle setColor:[CPTColor darkGrayColor]];

	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	[lineStyle setLineWidth:1.0f];
	[lineStyle setLineColor:dataColor];

	__graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];
	[__graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
	[__graph setFill:[CPTFill fillWithColor:[CPTColor clearColor]]];
	[[__graph plotAreaFrame] setFill:[CPTFill fillWithColor:[CPTColor clearColor]]];
	[[__graph plotAreaFrame] setBorderLineStyle:nil];

	// make it so the graph uses exactly the same space as the view it is
	// contained in
	[__graph setPaddingLeft:0];
	[__graph setPaddingTop:0];
	[__graph setPaddingBottom:0];
	[__graph setPaddingRight:0];

	// we need these paddings to make the labels fit nicely
	[[__graph plotAreaFrame] setPaddingLeft:45];
	[[__graph plotAreaFrame] setPaddingTop:15];
	[[__graph plotAreaFrame] setPaddingRight:2];
	[[__graph plotAreaFrame] setPaddingBottom:20];

	[__graph setTitle:@"Keystrokes Per Day"];
	[__graph setTitleDisplacement:CGPointMake(0, 5)];
	[__graph setTitleTextStyle:textStyle];

	[__graph setDelegate:self];

	[_dailyKeystrokesView setHostedGraph:__graph];

	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)__graph.defaultPlotSpace;

	// we need to fit the bars in the plot space, thus we have to add padding to the total range
	[plotSpace setXRange:[CPTMutablePlotRange plotRangeWithLocation:[NSNumber numberWithFloat:(-padding*0.6)]
															 length:[NSNumber numberWithFloat:(totalDateRange+(1.2*padding))]]];
	[plotSpace setYRange:[CPTPlotRange plotRangeWithLocation:[NSNumber numberWithFloat:0.0]
													  length:[NSNumber numberWithFloat:maxKeystrokes]]];

	CPTMutableLineStyle *minorGridLineStyle = [[CPTMutableLineStyle alloc] init];
	[minorGridLineStyle setLineWidth:0.5];
	[minorGridLineStyle setLineColor:[CPTColor lightGrayColor]];

	CPTMutableLineStyle *majorGridLineStyle = [[CPTMutableLineStyle alloc] init];
	[majorGridLineStyle setLineWidth:1.5];
	[majorGridLineStyle setLineColor:[CPTColor lightGrayColor]];

	// the x axis formats the first letter of the day of the week
	NSDateFormatter * dayOfWeekFormatter = [[NSDateFormatter alloc] init];
	[dayOfWeekFormatter setDateFormat:@"EEEEE"];
	CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dayOfWeekFormatter];
	[timeFormatter setReferenceDate:refDate];

	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)__graph.axisSet;

	// the y axis has keystrokes per day
	NSNumberFormatter *keystrokesFormatter = [[NSNumberFormatter alloc] init];
	[keystrokesFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[keystrokesFormatter setUsesGroupingSeparator:YES];

	CPTXYAxis *yLeft = [axisSet yAxis];
	[yLeft setMajorGridLineStyle:majorGridLineStyle];
	[yLeft setMajorTickLineStyle:majorGridLineStyle];
	[yLeft setMinorTickLineStyle:minorGridLineStyle];
	[yLeft setMajorIntervalLength:[NSNumber numberWithFloat:floor(maxKeystrokes/6)]];
	[yLeft setOrthogonalPosition:[NSNumber numberWithFloat:(-padding*0.6)]];
	[yLeft setLabelFormatter:keystrokesFormatter];
	[yLeft setLabelTextStyle:textStyle];
	[yLeft setLabelOffset:-2];

	// We need a right axis to make the plot look symmetrical, it's essentially
	// the same as the left Y axis but with no labels
	CPTXYAxis *yRight = [[CPTXYAxis alloc] init];
	[yRight setPlotSpace:plotSpace];
	[yRight setMajorTickLineStyle:majorGridLineStyle];
	[yRight setMinorTickLineStyle:minorGridLineStyle];
	[yRight setMinorTicksPerInterval:4];
	[yRight setMajorIntervalLength:[NSNumber numberWithFloat:floor(maxKeystrokes/6)]];
	[yRight setOrthogonalPosition:[NSNumber numberWithFloat:totalDateRange+(padding*0.6)]];
	[yRight setLabelFormatter:nil];
	[yRight setCoordinate:CPTCoordinateY];
	[yRight setAxisLineStyle:majorGridLineStyle];

	CPTXYAxis *xBottom = [[CPTXYAxis alloc] init];
	[xBottom setPlotSpace:plotSpace];
	[xBottom setMajorTickLineStyle:majorGridLineStyle];
	[xBottom setMinorTickLineStyle:minorGridLineStyle];
	[xBottom setLabelingPolicy:CPTAxisLabelingPolicyLocationsProvided];
	[xBottom setMajorTickLocations:dateTicks];
	[xBottom setOrthogonalPosition:[NSNumber numberWithFloat:0]];
	[xBottom setCoordinate:CPTCoordinateX];
	[xBottom setAxisLineStyle:majorGridLineStyle];
	[xBottom setLabelFormatter:timeFormatter];
	[xBottom setLabelTextStyle:textStyle];
	[xBottom setLabelOffset:-5];
	[xBottom setLabelAlignment:CPTAlignmentMiddle];

	[[__graph axisSet] setAxes:@[yLeft, yRight, xBottom]];

	CPTBarPlot *barPlot = [CPTBarPlot tubularBarPlotWithColor:fillingColor horizontalBars:NO];
	[barPlot setIdentifier:@"Keystrokes Plot"];
	[barPlot setDelegate:self];
	[barPlot setBarWidth:[NSNumber numberWithFloat:(padding * 0.8)]];
	[barPlot setFill:[CPTFill fillWithColor:fillingColor]];
	[barPlot setBarCornerRadius:0];
	[barPlot setLineStyle:lineStyle];
	[barPlot setDataSource:self];

	CPTMutableLineStyle *dashedLineStyle = [lineStyle copy];
	[dashedLineStyle setDashPattern:@[@3, @3]];
	[dashedLineStyle setLineWidth:1.5f];

	CPTScatterPlot *linePlot = [[CPTScatterPlot alloc] init];
	[linePlot setDataLineStyle:dashedLineStyle];
	[linePlot setIdentifier:@"Keystrokes Average Plot"];
	[linePlot setDataSource:self];
	[linePlot setDelegate:self];
	[linePlot setInterpolation:CPTScatterPlotInterpolationHistogram];

	[__graph addPlot:barPlot];
	[__graph addPlot:linePlot];
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
	NSString *identifier = (NSString *)[plot identifier];
	NSUInteger count = 0;

	if ([identifier isEqualToString:@"Keystrokes Plot"]) {
		count = [__keystrokesData count];
	}
	else if ([identifier isEqualToString:@"Keystrokes Average Plot"]){
		count = [__averageData count];
	}

	return count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
	NSNumber *dataPoint = @0;
	NSDate *start, *end;
	NSString *identifier = (NSString *)[plot identifier];

	switch (fieldEnum) {
		case CPTScatterPlotFieldX:
			if ([identifier isEqualToString:@"Keystrokes Plot"]) {
				start = [__datesData objectAtIndex:0];
				end = [__datesData objectAtIndex:index];
				dataPoint = [NSNumber numberWithDouble:[end timeIntervalSinceDate:start]];
			}
			else if ([identifier isEqualToString:@"Keystrokes Average Plot"]){
				start = [__datesData objectAtIndex:0];
				end = [__datesData objectAtIndex:index];

				// deal with the fact that the bar plot appears on screen from half a day before
				// the first day in the array and up to half a day after the last day in the array
				if (index == 0) {
					dataPoint = [NSNumber numberWithDouble:[end timeIntervalSinceDate:start]-(D_DAY/2)];
				}
				else if (index == [self numberOfRecordsForPlot:plot]-1) {
					dataPoint = [NSNumber numberWithDouble:[end timeIntervalSinceDate:start]+(D_DAY/2)];
				}
				else {
					dataPoint = [NSNumber numberWithDouble:[end timeIntervalSinceDate:start]];
				}
			}
			break;
		case CPTScatterPlotFieldY:
			if ([identifier isEqualToString:@"Keystrokes Plot"]) {
				dataPoint = [__keystrokesData objectAtIndex:index];
			}
			else if ([identifier isEqualToString:@"Keystrokes Average Plot"]){
				dataPoint = [__averageData objectAtIndex:index];
			}
			break;
		default:
			dataPoint = @0;
			break;
	}

	return dataPoint;
}

#pragma mark - CPTBarPlotDelegate
-(void)barPlot:(CPTBarPlot *)plot barTouchDownAtRecordIndex:(NSUInteger)idx{

	// let's make sure this doesn't happen, otherwise it would error out
	if (__keystrokesData == nil || __datesData == nil) {
		return;
	}

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterFullStyle];

	NSNumberFormatter *keystrokesFormatter = [[NSNumberFormatter alloc] init];
	[keystrokesFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[keystrokesFormatter setUsesGroupingSeparator:YES];

	NSString *annotationText = [NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:[__datesData objectAtIndex:idx] ] ,
																	   [keystrokesFormatter stringFromNumber:[__keystrokesData objectAtIndex:idx]]];

	[__graph setTitle:annotationText];

}

-(void)barPlot:(CPTBarPlot *)plot barTouchUpAtRecordIndex:(NSUInteger)idx{
	[__graph setTitle:@"Keystrokes Per Day"];
}

-(void)scatterPlot:(CPTScatterPlot *)plot dataLineTouchDownWithEvent:(CPTNativeEvent *)event{
	double plotPoint[2];
	[[__graph defaultPlotSpace] doublePrecisionPlotPoint:plotPoint numberOfCoordinates:2 forEvent:event];

	NSNumberFormatter *keystrokesFormatter = [[NSNumberFormatter alloc] init];
	[keystrokesFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[keystrokesFormatter setUsesGroupingSeparator:YES];
	[keystrokesFormatter setMinimumFractionDigits:2];
	[keystrokesFormatter setMaximumFractionDigits:2];

	NSNumber *average = [NSNumber numberWithDouble:plotPoint[1]];
	NSString *averageString = [keystrokesFormatter stringFromNumber:average];

	NSString *annotationText = [NSString stringWithFormat:@"Average Keystrokes For Selected Week: %@", averageString];
	[__graph setTitle:annotationText];
}

-(void)scatterPlot:(CPTScatterPlot *)plot dataLineTouchUpWithEvent:(NSEvent *)event{
	[__graph setTitle:@"Keystrokes Per Day"];
}

@end
