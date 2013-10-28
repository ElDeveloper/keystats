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

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	// Insert code here to initialize your application
	NSLog(@"The location of the database is %@", [[NSBundle mainBundle] pathForResource:@"keystrokes" ofType:@""]);

	YVBKeyLogger *someKeyLogger = [[YVBKeyLogger alloc] initWithKeyPressedHandler:^(NSString *string, long long keyCode, CGEventType eventType){
		if (eventType == kCGEventKeyDown) {
			// Opening and closing a database connection everytime a key is
			// is fairly resource consuming, specially if you type kind of fast
			NSString *databaseFilePath = [[NSBundle mainBundle] pathForResource:@"keystrokes" ofType:@""];
			FMDatabase *db = [FMDatabase databaseWithPath:databaseFilePath];
			if (![db open]) {
				NSLog(@"Could not successfully open the database");
				return;
			}
			else{
				NSString *something = [NSString stringWithFormat:@"\
									   INSERT INTO\
									   keystrokes (timestamp, type, keycode, ascii)\
									   VALUES(null, %d, %llu, '%@');\
									   commit;", eventType, keyCode, string];
				if ([db executeUpdate:something]) {
					return;
				}
				else{
					[db close];
				}
			}
		}
	}];
	[someKeyLogger startLogging];

	NSLog(@"The key logger %@ work as expected", [someKeyLogger requestEnableAccessibility] ? @"will" : @"will not");
}
@end
