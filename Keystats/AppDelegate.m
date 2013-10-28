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

	NSString *databaseFilePath = [[NSBundle mainBundle] pathForResource:@"keystrokes" ofType:@""];
	NSLog(@"The database is at: %@", databaseFilePath);

	NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
	BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);

	NSLog(@"Something happpend: %@", accessibilityEnabled ? @"bueno" : @"malo");

//	YVBKeyLogger *someKeyLogger = [[YVKeyLogger alloc] initWithKeyPressedHandler:^(NSString *string, long long keyCode){
//		NSLog(@"XXXXXX %@", string);
//	}];
	YVBKeyLogger *someKeyLogger = [[YVBKeyLogger alloc] init];
	[someKeyLogger startLogging];

	NSLog(@"The key logger %@ running", [someKeyLogger isLogging] ? @"is" : @"is not");

//	FMDatabase *db = [FMDatabase databaseWithPath:databaseFilePath];
//	if (![db open]) {
//		NSLog(@"Could not successfully open the database");
//		return;
//	}
//	NSLog(@"Database successfully open ...");
//
//	FMResultSet *s = [db executeQuery:@"SELECT * FROM keystrokesaaaa;"];
//	while ([s next]) {
//		//retrieve values for each record
//		NSLog(@"Retrieving a result");
//	}
}

@end
