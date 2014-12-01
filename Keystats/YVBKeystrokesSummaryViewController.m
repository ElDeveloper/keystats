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

-(void)updateDailyKeystrokesPlot:(NSArray *)data{
	__datesData = [[data objectAtIndex:0] copy];
	__keystrokesData = [[data objectAtIndex:1]  copy];

	if ([__datesData count] > 5) {
		[_dailyKeystrokesLabel setStringValue:@""];
		[self _updatePlot];
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
	[[__graph plotAreaFrame] setPaddingRight:20];
	[[__graph plotAreaFrame] setPaddingBottom:20];

	[__graph setTitle:@"Keystrokes Per Day"];
	[__graph setTitleDisplacement:CGPointMake(0, 5)];
	[__graph setTitleTextStyle:textStyle];

	[__graph setDelegate:self];

	[_dailyKeystrokesView setHostedGraph:__graph];

	// Setup scatter plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)__graph.defaultPlotSpace;
	plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(totalDateRange)];
	plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0) length:CPTDecimalFromDouble(maxKeystrokes)];

	CPTMutableLineStyle *minorGridLineStyle = [[CPTMutableLineStyle alloc] init];
	[minorGridLineStyle setLineWidth:0.5];
	[minorGridLineStyle setLineColor:[CPTColor lightGrayColor]];

	CPTMutableLineStyle *majorGridLineStyle = [[CPTMutableLineStyle alloc] init];
	[majorGridLineStyle setLineWidth:1.5];
	[majorGridLineStyle setLineColor:[CPTColor lightGrayColor]];

	// the x axis has dates
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MMM dd"];

	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)__graph.axisSet;
	CPTXYAxis *x = [axisSet xAxis];
	[x setMajorGridLineStyle:majorGridLineStyle];
	[x setMajorTickLineStyle:majorGridLineStyle];
	[x setMinorTickLineStyle:minorGridLineStyle];
	[x setMajorIntervalLength:CPTDecimalFromFloat(totalDateRange/4)];
	[x setOrthogonalCoordinateDecimal:CPTDecimalFromDouble(0)];
	CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
	[timeFormatter setReferenceDate:refDate];
	[x setLabelFormatter:timeFormatter];
	[x setLabelTextStyle:textStyle];
	[x setLabelAlignment:CPTAlignmentMiddle];

	// the y axis has keystrokes per day
	NSNumberFormatter *keystrokesFormatter = [[NSNumberFormatter alloc] init];
	[keystrokesFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[keystrokesFormatter setUsesGroupingSeparator:YES];

	CPTXYAxis *y = [axisSet yAxis];
	[y setMajorGridLineStyle:majorGridLineStyle];
	[y setMajorTickLineStyle:majorGridLineStyle];
	[y setMinorTickLineStyle:minorGridLineStyle];
	// the padding added when maxKeystrokes is created is used by this value which
	// is rounded down so we can guarantee that all the lines will fit
	[y setMajorIntervalLength:CPTDecimalFromDouble(floor(maxKeystrokes/6))];
	[y setOrthogonalCoordinateDecimal:CPTDecimalFromFloat(0.0f)];
	[y setLabelFormatter:keystrokesFormatter];
	[y setLabelTextStyle:textStyle];
	[y setLabelOffset:-2];

	CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
	[symbolLineStyle setLineColor:dataColor];

	CPTPlotSymbol *symbol = [CPTPlotSymbol ellipsePlotSymbol];
	[symbol setSize:CGSizeMake(5, 5)];
	[symbol setFill:[CPTFill fillWithColor:dataColor]];
	[symbol setLineStyle:symbolLineStyle];

	// set the datasource
	CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
	[dataSourceLinePlot setIdentifier:@"Keystrokes Plot"];
	[dataSourceLinePlot setPlotSymbol:symbol];
	[dataSourceLinePlot setAreaFill:[CPTFill fillWithColor:fillingColor]];
	[dataSourceLinePlot setAreaBaseValue:CPTDecimalFromInt(0)];
	[dataSourceLinePlot setDelegate:self];
	[dataSourceLinePlot	setPlotSymbolMarginForHitDetection:5];

	CPTMutableLineStyle *lineStyle = [[dataSourceLinePlot dataLineStyle] mutableCopy];
	[lineStyle setLineWidth:1.5];
	[lineStyle setLineColor:dataColor];
	[dataSourceLinePlot setDataLineStyle:lineStyle];
	[dataSourceLinePlot setDataSource:self];
	[__graph addPlot:dataSourceLinePlot];
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

#pragma mark - CPTScatterPlotDelegate
-(void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)index{

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

	NSString *annotationText = [NSString stringWithFormat:@"%@ - %@", [dateFormatter stringFromDate:[__datesData objectAtIndex:index] ] ,
																	   [keystrokesFormatter stringFromNumber:[__keystrokesData objectAtIndex:index]]];

	[__graph setTitle:annotationText];
	[__graph performSelector:@selector(setTitle:) withObject:@"Keystrokes Per Day" afterDelay:1.5];

}


@end
