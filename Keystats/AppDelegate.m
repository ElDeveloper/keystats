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
#import "YVBDailyExecutor.h"

@implementation AppDelegate

@synthesize totalCountLabel, todayCountLabel, thisWeekCountLabel, thisMonthCountLabel;

- (void)awakeFromNib{
	// now check that we have accessibility access
	if (![YVBKeyLogger accessibilityIsEnabled]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"Keystats has not yet been allowed as an "
		 "assistive application."];
		[alert setInformativeText:@"Keystats requires that 'Enable access for "
		 "assistive devices' in the 'Universal Access'"
		 " preferences panel be enabled in order to "
		 "register the keys being pressed. Once you "
		 " do this, restart Keystats."];
		[alert addButtonWithTitle:@"Quit"];
		[alert addButtonWithTitle:@"Enable Accessibility"];
		[alert setAlertStyle:NSCriticalAlertStyle];

		// modal alerts block the main thread so they get a return code
		NSInteger result = [alert runModal];

		if (result == NSAlertFirstButtonReturn) {
			[NSApp terminate:self];

		}
		else if (result == NSAlertSecondButtonReturn) {
			[YVBKeyLogger requestAccessibilityEnabling];
			[NSApp terminate:self];
		}

	}
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	// Insert code here to initialize your application
	NSString *databaseFilePath = [[self pathForApplicationDatabase] path];

	// verify we have a database outside the application's environment
	if (![[NSFileManager defaultManager] fileExistsAtPath:databaseFilePath]) {
		[self copyDatabase];
	}

	dataManager = [[YVBKeystrokesDataManager alloc] initWithFilePath:databaseFilePath];

	// serve like cache of the values, until I figure out how to query a sqlite
	// database about 100 times per second without it delaying the callbacks
	_totalCountValue = 0;
	_todayCountValue = 0;
	_weeklyCountValue = 0;
	_monthlyCountValue = 0;
	[self computeBufferValuesAndUpdateLabels];

	// this executor will take care on updating the labels on day change
	YVBDailyExecutor *executor = [[YVBDailyExecutor alloc] initWithHandler:^(void){
		[self computeBufferValuesAndUpdateLabels];
	}];
	[executor start];

	NSDateFormatter * __block dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

	YVBKeyPressed handlerBlock = ^(NSString *string, long long keyCode, CGEventType eventType){
		if (eventType == kCGEventKeyDown) {
			NSString *dateString = nil;

			_totalCountValue++;
			_weeklyCountValue++;
			_monthlyCountValue++;
			_todayCountValue++;

			// update from the count buffers
			[todayCountLabel setStringValue:
			 [[dataManager resultFormatter] stringFromNumber:
			  [NSNumber numberWithLongLong:_todayCountValue]]];
			[totalCountLabel setStringValue:
			 [[dataManager resultFormatter] stringFromNumber:
			  [NSNumber numberWithLongLong:_totalCountValue]]];
			[thisWeekCountLabel setStringValue:
			 [[dataManager resultFormatter] stringFromNumber:
			  [NSNumber numberWithLongLong:_weeklyCountValue]]];
			[thisMonthCountLabel setStringValue:
			 [[dataManager resultFormatter] stringFromNumber:
			  [NSNumber numberWithLongLong: _monthlyCountValue]]];

			// get the current time-stamp for this keystroke
			dateString = [dateFormat stringFromDate:[NSDate date]];
			[dataManager addKeystrokeWithTimeStamp:dateString
											string:string
										   keycode:keyCode
									  andEventType:eventType];
		}
	};

	YVBKeyLogger *someKeyLogger = [[YVBKeyLogger alloc] initWithKeyPressedHandler:[handlerBlock copy]];
	[someKeyLogger startLogging];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return YES;
}


- (void)copyDatabase{
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	NSURL *appSupportDir = [defaultManager URLForDirectory:NSApplicationSupportDirectory
												  inDomain:NSUserDomainMask
										 appropriateForURL:nil
													create:YES
													 error:nil];

	NSURL *keystatsSandbox = [appSupportDir URLByAppendingPathComponent:@"Keystats"];

	// the one in our resources
	NSURL *databaseFilePath = [[NSBundle mainBundle] URLForResource:@"keystrokes"
													  withExtension:@""];
	BOOL directoryCreationWorked;

	NSError *error = nil;

	// check the directory exists already and if it doesn't create it
	if(![defaultManager fileExistsAtPath:[keystatsSandbox path]]) {
		directoryCreationWorked = [defaultManager createDirectoryAtURL:keystatsSandbox
										   withIntermediateDirectories:YES
															attributes:nil
																 error:&error];
		if (!directoryCreationWorked) {
			NSLog(@"Failed to create the Keystats directory: %@", [error localizedDescription]);
			[NSAlert alertWithError:error];
			[NSApp terminate:self];
		}
	}

	// assumming the directory exists by now copy the database there
	if ([defaultManager isReadableFileAtPath:[databaseFilePath path]]){
		[defaultManager copyItemAtURL:databaseFilePath
								toURL:[keystatsSandbox URLByAppendingPathComponent:@"keystrokes"]
								error:&error];
	}
	else{
		NSLog(@"Error writing file to destination: %@. Make sure you have "
			  "permission to write to this directory", [databaseFilePath path]);
		[NSApp terminate:self];
	}

	// in case there was an error after the file was copied
	if (error) {
		NSLog(@"Error copying the database: %@", [error localizedDescription]);
		[NSAlert alertWithError:error];
		[NSApp terminate:self];
	}
}

-(NSURL *)pathForApplicationDatabase{
	NSURL *appSupportDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
																  inDomain:NSUserDomainMask
														 appropriateForURL:nil
																	create:YES
																	 error:nil];
	NSURL *keystatsSandbox = [appSupportDir URLByAppendingPathComponent:@"Keystats/keystrokes"];

	return keystatsSandbox;
}

- (void)computeBufferValuesAndUpdateLabels{
	// set the labels
	[dataManager getTotalCount:^(NSString *result) {
		[totalCountLabel setStringValue:result];
		_totalCountValue = [[result stringByReplacingOccurrencesOfString:@","
															  withString:@""] longLongValue];
	}];
	[dataManager getTodayCount:^(NSString *result) {
		[todayCountLabel setStringValue:result];
		_todayCountValue = [[result stringByReplacingOccurrencesOfString:@","
															  withString:@""] longLongValue];
	}];
	[dataManager getWeeklyCount:^(NSString *result) {
		[thisWeekCountLabel setStringValue:result];
		_weeklyCountValue = [[result stringByReplacingOccurrencesOfString:@","
															   withString:@""] longLongValue];
	}];
	[dataManager getMonthlyCount:^(NSString *result) {
		[thisMonthCountLabel setStringValue:result];
		_monthlyCountValue = [[result stringByReplacingOccurrencesOfString:@","
																withString:@""] longLongValue];
	}];
}


@end
