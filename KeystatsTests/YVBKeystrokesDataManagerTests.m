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

	NSString *oldestDate;

	// needed to test getKeystrokesPerDay
	NSArray *datesSummary;
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

	datesSummary = [[NSMutableArray alloc] initWithCapacity:6];

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

	// create an array of unique dates for the inserted test data
	NSInteger uniqueDays[6] = {-11, -4, -3, -2, -1, 0};
	NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:6];
	for (int i=0; i < 6; i++){
		[dayComponent setDay:uniqueDays[i]];
		[tempArray addObject:[theCalendar dateByAddingComponents:dayComponent toDate:currentDate options:0]];
	}
	datesSummary = [[NSArray alloc] initWithArray:tempArray];

	for (int i=0; i<[insertStatements count]; i++) {
		[dayComponent setDay:days[i]];
		dateForInsertion = [dateFormat stringFromDate:[theCalendar dateByAddingComponents:dayComponent toDate:currentDate options:0]];

		// the last date is the oldest date
		if (i == ([insertStatements count] - 1)) {
			oldestDate = [dateForInsertion copy];
		}

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
	XCTestExpectation *expectation = [self expectationWithDescription:@"testGetTotalCount"];

	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getTotalCount:^(NSString *result){
		XCTAssert([@"13" isEqualToString:result], @"The total count query is wrong %@", result);
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
		if (error) {
			NSLog(@"Timeout Error: %@", error);
		}
	}];
}

- (void)testGetTodayCount{
	XCTestExpectation *expectation = [self expectationWithDescription:@"testGetTodayCount"];

	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getTodayCount:^(NSString *result){
		XCTAssertEqualObjects(@"2", result);
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
		if (error) {
			NSLog(@"Timeout Error: %@", error);
		}
	}];
}

- (void)testGetWeeklyCount{
	XCTestExpectation *expectation = [self expectationWithDescription:@"testGetWeeklyCount"];

	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getWeeklyCount:^(NSString *result){
		XCTAssertEqualObjects(@"9", result);
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
		if (error) {
			NSLog(@"Timeout Error: %@", error);
		}
	}];
}

- (void)testGetMonthlyCount{
	XCTestExpectation *expectation = [self expectationWithDescription:@"testGetMonthlyCount"];

	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getMonthlyCount:^(NSString *result){
		XCTAssertEqualObjects(@"10", result);
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
		if (error) {
			NSLog(@"Timeout Error: %@", error);
		}
	}];
}

- (void)testAddKeystrokeRegularCharacter{
	XCTestExpectation *expectation = [self expectationWithDescription:@"testAddKeystrokeSpecialCharacter"];

	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:writableDatabasePath];
	[manager addKeystrokeWithTimeStamp:@"2013-12-29 14:44:30" string:@"K" keycode:40 eventType:10 andApplicationBundleIdentifier:@"com.dev.Mutt"];
	[manager getTotalCount:^(NSString *result){
		XCTAssert([@"14" isEqualToString:result], @"The K keystroke was not added correctly");
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
		if (error) {
			NSLog(@"Timeout Error: %@", error);
		}
	}];
}

- (void)testAddKeystrokeSpecialCharacter{
	XCTestExpectation *expectation = [self expectationWithDescription:@"testAddKeystrokeSpecialCharacter"];

	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:writableDatabasePathSpecial];
	[manager addKeystrokeWithTimeStamp:@"2013-12-29 14:44:30" string:@"'" keycode:39 eventType:10 andApplicationBundleIdentifier:@"com.dev.Mutt"];
	[manager getTotalCount:^(NSString *result){
		XCTAssert([@"14" isEqualToString:result], @"The ' keystroke was not added correctly");
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
		if (error) {
			NSLog(@"Timeout Error: %@", error);
		}
	}];
}

- (void)testGetEarliestDate{
	XCTestExpectation *expectation = [self expectationWithDescription:@"testGetEarliestDate"];

	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getEarliestDate:^(NSString *result){
		// see setUp
		XCTAssertEqualObjects(oldestDate, result);
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
		if (error) {
			NSLog(@"Timeout Error: %@", error);
		}
	}];
}

#define removeHour(X)\
[[NSCalendar currentCalendar] dateFromComponents:[[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:X]]

- (void)testGetKeystrokesPerDay{
	XCTestExpectation *expectation = [self expectationWithDescription:@"testGetKeystrokesPerDay"];

	YVBKeystrokesDataManager *manager = [[YVBKeystrokesDataManager alloc] initWithFilePath:temporaryDatabasePath];
	[manager getKeystrokesPerDay:^(NSArray *x, NSArray *y){
		XCTAssertEqual([x count], 6);
		XCTAssertEqual([y count], 6);
		XCTAssertEqual([x count], [y count]);

		unsigned long long array[6] = {1, 1, 2, 2, 2, 2};

		for (char i; i<6; i++) {
			XCTAssertEqualObjects([y objectAtIndex:i], [NSNumber numberWithUnsignedLongLong:array[i]]);

			// should only compare day, month and year
			XCTAssertEqualObjects(removeHour([x objectAtIndex:i]),
								  removeHour([datesSummary objectAtIndex:i]));
		}
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
		if (error) {
			NSLog(@"Timeout Error: %@", error);
		}
	}];
}

@end
