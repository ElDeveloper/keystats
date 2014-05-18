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

@interface AppDelegate : NSObject <NSApplicationDelegate>{
	YVBKeystrokesDataManager * __block dataManager;
	YVBKeystrokesSummaryViewController * __block summaryView;

	@private
	long long _totalCountValue;
	long long _monthlyCountValue;
	long long _weeklyCountValue;
	long long _todayCountValue;
	BOOL waitingForConfirmation;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) YVBKeystrokesSummaryViewController * __block summaryView;
@property (atomic) BOOL waitingForConfirmation;

- (void)copyDatabase;
- (NSURL *)pathForApplicationDatabase;
- (void)computeBufferValuesAndUpdateLabels;

- (void)keyLoggerPerishedNotification:(NSNotification *)aNotification;

- (IBAction)showAboutWindow:(id)sender;

@end
