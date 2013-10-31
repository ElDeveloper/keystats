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

@implementation AppDelegate

@synthesize totalCountLabel, todayCountLabel, thisWeekCountLabel, thisMonthCountLabel;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	// Insert code here to initialize your application
	[totalCountLabel setStringValue:@"0"];
	[todayCountLabel setStringValue:@"0"];
	[thisWeekCountLabel setStringValue:@"0"];
	[thisMonthCountLabel setStringValue:@"0"];

	NSLog(@"The key logger %@ work as expected", [YVBKeyLogger requestEnableAccessibility] ? @"will" : @"will not");

	NSString * __block databaseFilePath = [[NSBundle mainBundle] pathForResource:@"keystrokes" ofType:@""];
	NSDateFormatter * __block dateFormat = [[NSDateFormatter alloc] init];;
	[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

	FMDatabase * __block db = [FMDatabase databaseWithPath:databaseFilePath];
	if (![db open]) {
		NSLog(@"Could not successfully open the database");
		return;
	}

	NSLog(@"The database filepath is %@", databaseFilePath);

	YVBKeyPressed handlerBlock = ^(NSString *string, long long keyCode, CGEventType eventType){
		if (eventType == kCGEventKeyDown) {
			// Opening and closing a database connection everytime a key is
			// is fairly resource consuming, specially if you type kind of fast
			NSString *sqlInsert = nil;
			NSString *dateString = nil;

			// get the current time-stamp for this key
			dateString = [dateFormat stringFromDate:[NSDate date]];

			if ([db goodConnection]) {
				// SQL insert
				sqlInsert = [NSString stringWithFormat:@"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', %d, %llu, '%@'); commit;", dateString, eventType, keyCode, string];
				if (![db executeUpdate:sqlInsert]) {
					NSLog(@"Unexpected error %@ FAILED!", sqlInsert);
				}
				FMResultSet *countTotalResult = [db executeQuery:@"SELECT COUNT(*) FROM keystrokes;"];
				if ([countTotalResult next]) {
					[totalCountLabel setStringValue:[countTotalResult stringForColumnIndex:0]];
				}
				[countTotalResult close];
			}
			else{
				NSLog(@"The connection was interruped, trying to reconnect ...");
				[db open];
			}
		}
	};

	YVBKeyLogger *someKeyLogger = [[YVBKeyLogger alloc] initWithKeyPressedHandler:[handlerBlock copy]];
	[someKeyLogger startLogging];
}
@end
