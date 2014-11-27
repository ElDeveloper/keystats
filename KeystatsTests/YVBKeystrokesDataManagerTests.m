//
//  YVBKeystrokesDataManagerTests.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 12/29/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "YVBKeystrokesDataManager.h"
#import "FMDatabase.h"

@interface YVBKeystrokesDataManagerTests : XCTestCase{

	NSString *temporaryDatabasePath;
	NSString *writableDatabasePath;
	NSString *writableDatabasePathSpecial;
}

@end

@implementation YVBKeystrokesDataManagerTests

- (void)setUp{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
	temporaryDatabasePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/test-keystrokes"];
	writableDatabasePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/test-keystrokes-writable"];
	writableDatabasePathSpecial = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/test-keystrokes-writable-special"];

	FMDatabase *database = [FMDatabase databaseWithPath:temporaryDatabasePath];
	[database open];
	FMDatabase *writableDatabase = [FMDatabase databaseWithPath:writableDatabasePath];
	[writableDatabase open];
	FMDatabase *writableDatabaseSpecial = [FMDatabase databaseWithPath:writableDatabasePathSpecial];
	[writableDatabaseSpecial open];

	NSInteger days[14] = {0,0,0,-1,-1,-2,-2,-3,-3,-4,-11,-33,-46, -48};
	NSArray *insertStatements = @[@"CREATE TABLE keystrokes(id INTEGER PRIMARY KEY, timestamp DATETIME, type INTEGER, keycode INTEGER, ascii VARCHAR(1), bundle_id VARCHAR(64));",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '47', '.', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '83', '1', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '83', '1', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '87', '5', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '87', '5', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '92', '9', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '92', '9', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '91', '8', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '91', '8', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '91', '8', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '91', '8', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '91', '8', 'com.dev.Mutt');",
								  @"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES('%@', '10', '47', '.', 'com.dev.Mutt');"];

	NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

	NSDate *currentDate = [NSDate date];
	NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
	NSCalendar *theCalendar = [NSCalendar currentCalendar];
	NSString *dateForInsertion = nil;


	for (int i=0; i<[insertStatements count]; i++) {
		[dayComponent setDay:days[i]];
		dateForInsertion = [dateFormat stringFromDate:[theCalendar dateByAddingComponents:dayComponent toDate:currentDate options:0]];
		[database executeUpdate:[NSString stringWithFormat:[insertStatements objectAtIndex:i], dateForInsertion]];
		[writableDatabase executeUpdate:[NSString stringWithFormat:[insertStatements objectAtIndex:i], dateForInsertion]];
		[writableDatabaseSpecial executeUpdate:[NSString stringWithFormat:[insertStatements objectAtIndex:i], dateForInsertion]];
	}
	[database close];
	[writableDatabase close];
	[writableDatabaseSpecial close];
}

- (void)tearDown{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
	[[NSFileManager defaultManager] removeItemAtPath:temporaryDatabasePath error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:writableDatabasePath error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:writableDatabasePathSpecial error:nil];
}

- (void)testInit{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] init];

	XCTAssertNil([manager queue], @"The queue is not initialized as nil");
	XCTAssertNil([manager filePath], @"The filepath is not initialized as nil");

	XCTAssert([[[manager resultFormatter] thousandSeparator] isEqualToString:@","],
				   @"The formatter doesn't separates on commas");
	XCTAssert([[manager resultFormatter] groupingSize]==3, @"The formatter "
			  "group size is not three");
	XCTAssert([[manager resultFormatter] hasThousandSeparators], @"The "
			  "formatter doesn't have a thousand separator");
}

- (void)testInitWithFilePath{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];

	XCTAssertNotNil([manager queue], @"The queue is not initialized");
	XCTAssert([[manager filePath] isEqualToString:temporaryDatabasePath],
			  @"The filepath is not initialized correctly");

	XCTAssert([[[manager resultFormatter] thousandSeparator] isEqualToString:@","],
			  @"The formatter doesn't separates on commas");
	XCTAssert([[manager resultFormatter] groupingSize]==3, @"The formatter "
			  "group size is not three");
	XCTAssert([[manager resultFormatter] hasThousandSeparators], @"The "
			  "formatter doesn't have a thousand separator");
}

- (void)testGetTotalCount{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getTotalCount:^(NSString *result){
		XCTAssert([@"13" isEqualToString:result], @"The total count query is wrong");
	}];
}

- (void)testGetTodayCount{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getTodayCount:^(NSString *result){
		XCTAssert([@"3" isEqualToString:result], @"The daily count query is wrong");
	}];
}

- (void)testGetWeeklyCount{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getWeeklyCount:^(NSString *result){
		XCTAssert([@"10" isEqualToString:result], @"The weekly count query is wrong");
	}];
}

- (void)testGetMonthlyCount{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getMonthlyCount:^(NSString *result){
		XCTAssert([@"11" isEqualToString:result], @"The monthly count query is wrong");
	}];
}

- (void)testAddKeystrokeRegularCharacter{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:writableDatabasePath];
	[manager addKeystrokeWithTimeStamp:@"2013-12-29 14:44:30" string:@"K" keycode:40 eventType:10 andApplicationBundleIdentifier:@"com.dev.Mutt"];
	[manager getTotalCount:^(NSString *result){
		XCTAssert([@"14" isEqualToString:result], @"The K keystroke was not added correctly");
	}];

}

- (void)testAddKeystrokeSpecialCharacter{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:writableDatabasePathSpecial];
	[manager addKeystrokeWithTimeStamp:@"2013-12-29 14:44:30" string:@"'" keycode:39 eventType:10 andApplicationBundleIdentifier:@"com.dev.Mutt"];
	[manager getTotalCount:^(NSString *result){
		XCTAssert([@"14" isEqualToString:result], @"The ' keystroke was not added correctly");
	}];

}

- (void)testGetEarliestDate{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getEarliestDate:^(NSString *result){
		XCTAssert([@"2014-08-13 21:33:27" isEqualToString:result], @"The earliest known date query is wrong");
	}];
}

- (void)testGetKeystrokesPerDay{
	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getKeystrokesPerDay:^(NSArray *x, NSArray *y){
		XCTAssert([x count] == 9, @"Array size of x is incorrect");
		XCTAssert([y count] == 9, @"Array size of y is incorrect");
		XCTAssert([x count] == [y count], @"Array sizes are not equal");

		unsigned long long array[9] = {2, 2, 2, 2, 1, 1, 1, 1, 1};
		NSArray *datesArray = @[@"2014-11-27", @"2014-11-26", @"2014-11-25",
								@"2014-11-24", @"2014-11-23", @"2014-11-16",
								@"2014-10-25", @"2014-10-12", @"2014-10-10"];
		NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
		[dateFormat setDateFormat:@"yyyy-MM-dd"];


		for (char i; i<9; i++) {
			XCTAssert([x objectAtIndex:i] == [NSNumber numberWithUnsignedLongLong:array[i]], @"Values are incorrectly retrieved from x");
			XCTAssert([y objectAtIndex:i] == [datesArray objectAtIndex:i], @"Values are incorrectly retrieved from x");
		}
	}];
}

@end
