//
//  AppDelegate.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 10/22/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class YVBKeystrokesDataManager;
@class YVBKeystrokesSummaryViewController;
@class YVBKeyLogger;

@interface AppDelegate : NSObject <NSApplicationDelegate>{
	 __block YVBKeystrokesDataManager *dataManager;
	 __block YVBKeystrokesSummaryViewController *summaryView;
	 __block YVBKeyLogger *mainLogger;

	@private
	long long _totalCountValue;
	long long _monthlyCountValue;
	long long _weeklyCountValue;
	long long _todayCountValue;
	BOOL waitingForConfirmation;
	BOOL _knowsEarliestDate;
	NSUInteger __tasksCompleted;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain)  __block  YVBKeystrokesSummaryViewController *summaryView;
@property (atomic, retain)  __block  YVBKeyLogger *mainLogger;
@property (atomic) BOOL waitingForConfirmation;

- (void)copyDatabase;
- (NSURL *)pathForApplicationDatabase;
- (void)computeBufferValuesAndUpdateLabels;
- (bool)applicationIsRunningTests;
- (void)keystatsDidFinishLaunching;
- (void)keyLoggerPerishedNotification:(NSNotification *)aNotification;

- (IBAction)showAboutWindow:(id)sender;

@end
