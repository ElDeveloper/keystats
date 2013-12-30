//
//  AppDelegate.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 10/22/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class YVBKeystrokesDataManager;

@interface AppDelegate : NSObject <NSApplicationDelegate>{
	IBOutlet NSTextField * __weak __block totalCountLabel;
	IBOutlet NSTextField * __weak __block todayCountLabel;
	IBOutlet NSTextField * __weak __block thisWeekCountLabel;
	IBOutlet NSTextField * __weak __block thisMonthCountLabel;

	YVBKeystrokesDataManager * __block dataManager;

	long long _totalCountValue;
	long long _monthlyCountValue;
	long long _weeklyCountValue;
	long long _todayCountValue;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, weak) IBOutlet NSTextField * __block totalCountLabel;
@property (nonatomic, weak) IBOutlet NSTextField * __block todayCountLabel;
@property (nonatomic, weak) IBOutlet NSTextField * __block thisWeekCountLabel;
@property (nonatomic, weak) IBOutlet NSTextField * __block thisMonthCountLabel;

- (void)copyDatabase;
- (NSURL *)pathForApplicationDatabase;
- (void)computeBufferValuesAndUpdateLabels;

- (IBAction)showAboutWindow:(id)sender;

@end
