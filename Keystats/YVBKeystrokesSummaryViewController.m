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

-(void)updateWithTotalValue:(NSString *)total todayValue:(NSString *)today
		 lastSevenDaysValue:(NSString *)lastSevenDaysValue
	 andLastThirtyDaysValue:(NSString *)lastThirtyDaysValue{
	NSNumber *todayNumber = [__formatter numberFromString:today];
	NSInteger current = [todayNumber integerValue];

	// we pretend the latest point is up to date by retrieving the current
	// value of the todayCountLabel
	[__keystrokesData replaceObjectAtIndex:[__keystrokesData count]-1
								withObject:todayNumber];

	// update the values of the labels
	[_totalCountLabel setStringValue:total];
	[_todayCountLable setStringValue:today];
	[_lastSevenDaysCountLabel setStringValue:lastSevenDaysValue];
	[_lastThirtyDaysCountLabel setStringValue:lastThirtyDaysValue];

	// plotting logic:
	// check whether or not we need to update the plot
	if (__canDrawPlot) {
		if (current > __knownMax) {
			[self _updatePlot];
			__previous = current;
		}
		// guarantee that we are updating at least every 30 keystrokes
		if (current-__previous > (__knownMax*0.033 > 30 ? __knownMax*0.033 : 30) ) {
			[__graph reloadData];
			__previous = current;
		}
	}
}

-(void)updateDailyKeystrokesPlot:(NSArray *)data{
	__datesData = [NSMutableArray arrayWithArray:[[data objectAtIndex:0] copy]];
	__keystrokesData = [NSMutableArray arrayWithArray:[[data objectAtIndex:1] copy]];
	
	// every time we are asked to update the values let's force a hard restart
	__previous = 0;

	// HT: http://stackoverflow.com/a/1857392/379593
	NSUInteger today = [[NSCalendar currentCalendar] ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:[NSDate date]];

	// ensure that the series we are ploitting include information for the current day
	NSUInteger indexOfToday = [__datesData indexOfObjectPassingTest:
	 ^BOOL(id obj, NSUInteger idx, BOOL *stop){
		 NSUInteger dayToCompare = [[NSCalendar currentCalendar] ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:obj];
		 if (today == dayToCompare) {
			 return YES;
		 }
		 return NO;
	 }];

	// add an empty entry if today's date is not saved already
	// this way the plot updating routine will work seamlessly
	if(indexOfToday == NSNotFound){
		[__datesData addObject:[NSDate date]];
		[__keystrokesData addObject:[NSNumber numberWithLongLong:0]];

		// be consistent and remove the extra object
		[__datesData removeObjectAtIndex:0];
		[__keystrokesData removeObjectAtIndex:0];
	}

	// convenience variable to check in other places whether
	// or not we are drawing the keystrokes per day plot
	__canDrawPlot = [__datesData count] > 5;

	if (__canDrawPlot) {
		// remove the "loading" label
		[_dailyKeystrokesLabel setStringValue:@""];
		[self _updatePlot];

		if (![__plotTimer isValid]){
			[__plotTimer fire];
		}
	}
	else{
		[_dailyKeystrokesLabel setStringValue:@"Not Enough Data To Display Plot"];
	}
}

-(void)_updatePlot{
	// this code was based in the DatePlot example from CorePlot
	NSDate *refDate = [__datesData objectAtIndex:0];
	NSTimeInterval totalDateRange = [[__datesData objectAtIndex:[__datesData count]-1] timeIntervalSinceDate:refDate];
	double maxKeystrokes = [[__keystrokesData valueForKeyPath:@"@max.intValue"] doubleValue];

	// we use ceil here to create a number with a small "padding"
	maxKeystrokes = ceil(maxKeystrokes + (0.11*maxKeystrokes));

	// __knownMax sets when we have to reload the full plot
	__knownMax = maxKeystrokes;

	CPTColor *dataColor = [CPTColor colorWithComponentRed:CPTFloat(93.0f/255.0f)
													green:CPTFloat(130.0f/255.0f)
													 blue:CPTFloat(176.0f/255.0f)
													alpha:CPTFloat(1.0f)];
	CPTColor *fillingColor = [CPTColor colorWithComponentRed:CPTFloat(93.0f/255.0f)
													   green:CPTFloat(130.0f/255.0f)
														blue:CPTFloat(176.0f/255.0f)
													   alpha:CPTFloat(0.5)];

	CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
	[textStyle setFontSize:12.0f];
	[textStyle setColor:[CPTColor darkGrayColor]];

	CPTMutableTextStyle *smallTextStyle = [CPTMutableTextStyle textStyle];
	[smallTextStyle setFontSize:10.0f];
	[smallTextStyle setColor:[CPTColor darkGrayColor]];

	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
	[lineStyle setLineWidth:1.5];
	[lineStyle setLineColor:dataColor];

	// Create graph from theme
	__graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame:CGRectZero];
	[__graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
	[__graph setFill:[CPTFill fillWithColor:[CPTColor clearColor]]];
	[[__graph plotAreaFrame] setFill:[CPTFill fillWithColor:[CPTColor clearColor]]];
	[[__graph plotAreaFrame] setBorderLineStyle:nil];

	[__graph setPaddingLeft:0];
	[__graph setPaddingTop:0];
	[__graph setPaddingBottom:0];
	[__graph setPaddingRight:0];

	[[__graph plotAreaFrame] setPaddingLeft:45];
	[[__graph plotAreaFrame] setPaddingTop:15];
	[[__graph plotAreaFrame] setPaddingRight:2];
	[[__graph plotAreaFrame] setPaddingBottom:20];

	[__graph setTitle:@"Keystrokes Per Day"];
	[__graph setTitleDisplacement:CGPointMake(0, 5)];
	[__graph setTitleTextStyle:textStyle];

	[__graph setDelegate:self];

	[_dailyKeystrokesView setHostedGraph:__graph];

	// Setup scatter plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)__graph.defaultPlotSpace;

	float padding = totalDateRange/[__datesData count];
	CPTMutablePlotRange *xPlotRange = [CPTMutablePlotRange plotRangeWithLocation:CPTDecimalFromDouble(-padding*0.6) length:CPTDecimalFromDouble(totalDateRange+(1.2*padding))];

	[plotSpace setXRange:xPlotRange];
	[plotSpace setYRange:[CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(maxKeystrokes)]];

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
	// the padding added when maxKeystrokes is created is used by this value which
	// is rounded down so we can guarantee that all the lines will fit
	[yLeft setMajorIntervalLength:CPTDecimalFromDouble(floor(maxKeystrokes/6))];
	[yLeft setOrthogonalCoordinateDecimal:CPTDecimalFromFloat(-padding*0.6)];
	[yLeft setLabelFormatter:keystrokesFormatter];
	[yLeft setLabelTextStyle:textStyle];
	[yLeft setLabelOffset:-2];

	// We need a right axis to make the poot look symmetrical
	CPTXYAxis *yRight = [[CPTXYAxis alloc] init];
	[yRight setPlotSpace:plotSpace];
	[yRight setMajorTickLineStyle:majorGridLineStyle];
	[yRight setMinorTickLineStyle:minorGridLineStyle];
	[yRight setMinorTicksPerInterval:4];
	[yRight setMajorIntervalLength:CPTDecimalFromDouble(floor(maxKeystrokes/6))];
	[yRight setOrthogonalCoordinateDecimal:CPTDecimalFromFloat(totalDateRange+(padding*0.6))];
	[yRight setLabelFormatter:nil];
	[yRight setCoordinate:CPTCoordinateY];
	[yRight setAxisLineStyle:majorGridLineStyle];

	CPTXYAxis *xBottom = [[CPTXYAxis alloc] init];
	[xBottom setPlotSpace:plotSpace];
	[xBottom setMajorTickLineStyle:majorGridLineStyle];
	[xBottom setMinorTickLineStyle:minorGridLineStyle];
	[xBottom setMajorIntervalLength:CPTDecimalFromDouble(totalDateRange/[__datesData count])];
	[xBottom setOrthogonalCoordinateDecimal:CPTDecimalFromFloat(0)];
	[xBottom setCoordinate:CPTCoordinateX];
	[xBottom setAxisLineStyle:majorGridLineStyle];
	[xBottom setLabelFormatter:timeFormatter];
	[xBottom setLabelTextStyle:textStyle];
	[xBottom setLabelOffset:-5];
	[xBottom setLabelAlignment:CPTAlignmentMiddle];

	[[__graph axisSet] setAxes:@[yLeft, yRight, xBottom]];

	CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
	[symbolLineStyle setLineColor:dataColor];

	CPTPlotSymbol *symbol = [CPTPlotSymbol ellipsePlotSymbol];
	[symbol setSize:CGSizeMake(5, 5)];
	[symbol setFill:[CPTFill fillWithColor:dataColor]];
	[symbol setLineStyle:symbolLineStyle];

	// set the datasource
	CPTBarPlot *barPlot = [CPTBarPlot tubularBarPlotWithColor:fillingColor horizontalBars:NO];
	[barPlot setIdentifier:@"Keystrokes Plot"];
	[barPlot setDelegate:self];
	[barPlot setBarWidth:CPTDecimalFromCGFloat(padding*0.8)];
	[barPlot setFill:[CPTFill fillWithColor:fillingColor]];
	[barPlot setBarCornerRadius:0];

	[barPlot setLineStyle:symbolLineStyle];
	[barPlot setDataSource:self];

	[__graph addPlot:barPlot];
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
	return [__keystrokesData count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
	NSNumber *dataPoint = @0;
	NSDate *start, *end;

	switch (fieldEnum) {
		case CPTScatterPlotFieldX:
			start = [__datesData objectAtIndex:0];
			end = [__datesData objectAtIndex:index];
			dataPoint = [NSNumber numberWithDouble:[end timeIntervalSinceDate:start]];
			break;
		case CPTScatterPlotFieldY:
			dataPoint = [__keystrokesData objectAtIndex:index];
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

	static CPTPlotSpaceAnnotation *symbolTextAnnotation;

	if ( symbolTextAnnotation ) {
		[__graph.plotAreaFrame.plotArea removeAnnotation:symbolTextAnnotation];
		symbolTextAnnotation=nil;
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


@end
