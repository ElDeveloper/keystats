//
//  AppDelegate.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 10/22/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "AppDelegate.h"

#import "YVBKeyLogger.h"
#import "FMDatabase.h"
#import "YVBKeystrokesDataManager.h"

@implementation AppDelegate

@synthesize totalCountLabel, todayCountLabel, thisWeekCountLabel, thisMonthCountLabel;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	// Insert code here to initialize your application
	NSLog(@"The key logger %@ work as expected", [YVBKeyLogger requestEnableAccessibility] ? @"will" : @"will not");
	NSString *databaseFilePath = [[NSBundle mainBundle] pathForResource:@"keystrokes" ofType:@""];

	YVBKeystrokesDataManager * __block dataManager = [[YVBKeystrokesDataManager alloc] initWithFilePath:databaseFilePath];
	[totalCountLabel setStringValue:[dataManager getTotalCount]];
	[todayCountLabel setStringValue:@"0"];
	[thisWeekCountLabel setStringValue:@"0"];
	[thisMonthCountLabel setStringValue:@"0"];

	NSDateFormatter * __block dateFormat = [[NSDateFormatter alloc] init];;
	[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

	NSLog(@"The database filepath is %@", databaseFilePath);

	YVBKeyPressed handlerBlock = ^(NSString *string, long long keyCode, CGEventType eventType){
		if (eventType == kCGEventKeyDown) {
			NSString *dateString = nil;

			// get the current time-stamp for this keystroke
			dateString = [dateFormat stringFromDate:[NSDate date]];
			[dataManager addKeystrokeWithTimeStamp:dateString string:string keycode:keyCode andEventType:eventType];
			[totalCountLabel setStringValue:[dataManager getTotalCount]];
		}
	};

	YVBKeyLogger *someKeyLogger = [[YVBKeyLogger alloc] initWithKeyPressedHandler:[handlerBlock copy]];
	[someKeyLogger startLogging];
}
@end
