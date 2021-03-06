//
//  YVBKeystrokesSummaryView.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 1/7/14.
//  Copyright (c) 2014 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>

@class KeystatsSettings;

@interface YVBKeystrokesSummaryViewController : NSViewController<CPTPlotDataSource, CPTBarPlotDelegate, CPTScatterPlotDelegate, CALayerDelegate>{
	IBOutlet NSTextField * __weak totalCountLabel;
	IBOutlet NSTextField * __weak todayCountLabel;
	IBOutlet NSTextField * __weak lastSevenDaysCountLabel;
	IBOutlet NSTextField * __weak lastThirtyDaysCountLabel;
	IBOutlet NSTextField * __weak earliestDateLabel;
	IBOutlet CPTGraphHostingView * __weak dailyKeystrokesView;
	IBOutlet NSTextField * __weak dailyKeystrokesLabel;

	@private
	NSMutableArray *__datesData;
	NSMutableArray *__keystrokesData;
	NSArray *__averageData;
	CPTXYGraph *__graph;
	NSInteger __previous;
	NSInteger __knownMax;
	NSNumberFormatter *__formatter;
	BOOL __canDrawPlot;
	NSTimer *__plotTimer;
	KeystatsSettings *__settings;
	NSColor *_plotColor;

}

@property (nonatomic, weak) IBOutlet NSTextField * totalCountLabel;
@property (nonatomic, weak) IBOutlet NSTextField * todayCountLabel;
@property (nonatomic, weak) IBOutlet NSTextField * lastSevenDaysCountLabel;
@property (nonatomic, weak) IBOutlet NSTextField * lastThirtyDaysCountLabel;
@property (nonatomic, weak) IBOutlet NSTextField * earliestDateLabel;
@property (nonatomic, weak) IBOutlet CPTGraphHostingView * dailyKeystrokesView;
@property (nonatomic, weak) IBOutlet NSTextField * dailyKeystrokesLabel;

-(id)init;
-(void)updateWithTotalValue:(NSString *)total todayValue:(NSString *)today
		 lastSevenDaysValue:(NSString *)lastSevenDaysValue
	 andLastThirtyDaysValue:(NSString *)lastThirtyDaysValue;
-(void)updateDailyKeystrokesPlot:(NSArray *)data;

@end
