//
//  YVBUtilitesTests.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 3/1/15.
//  Copyright (c) 2015 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "YVBUtilities.h"

@interface YVBUtilitesTests : XCTestCase

@end

@implementation YVBUtilitesTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEmpty {
	NSArray *result = [YVBUtilities weeklyAverageForData:@[] perDate:@[]];
	XCTAssertEqual(0, [result count]);
}

- (void)testOneElement {
	unsigned long long array[1] = {11};
	NSArray *_datesArray = @[@"2015-03-01"];
	NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyy-MM-dd"];

	NSMutableArray *dates = [[NSMutableArray alloc] init], *keystrokes = [[NSMutableArray alloc] init];

	for (int i = 0; i < [_datesArray count]; i++) {
		[dates addObject:[dateFormat dateFromString:[_datesArray objectAtIndex:i]]];
		[keystrokes addObject:[NSNumber numberWithUnsignedLongLong:array[i]]];
	}

	NSArray *result = [YVBUtilities weeklyAverageForData:keystrokes perDate:dates];
	float expected[1] = {11};

	for (int i = 0; i < [result count]; i++) {
		XCTAssertEqualWithAccuracy(expected[i], [[result objectAtIndex:i] floatValue], 0.001);
	}
}

- (void)testRegularData {
	unsigned long long array[9] = {2, 1, 3, 5, 19, 23, 12, 256, 1000};
	NSArray *_datesArray = @[@"2015-03-01", @"2015-03-02", @"2015-03-07",
							@"2015-03-11", @"2015-03-13", @"2015-03-14",
							@"2015-03-25", @"2015-03-26", @"2015-03-27"];
	NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyy-MM-dd"];

	NSMutableArray *dates = [[NSMutableArray alloc] init], *keystrokes = [[NSMutableArray alloc] init];

	for (int i = 0; i < [_datesArray count]; i++) {
		[dates addObject:[dateFormat dateFromString:[_datesArray objectAtIndex:i]]];
		[keystrokes addObject:[NSNumber numberWithUnsignedLongLong:array[i]]];
	}

	NSArray *result = [YVBUtilities weeklyAverageForData:keystrokes perDate:dates];
	float expected[9] = {2.0, 2.0, 2.0, 15.66667, 15.66667, 15.66667, 422.6667, 422.6667, 422.6667};

	for (int i = 0; i < [result count]; i++) {
		XCTAssertEqualWithAccuracy(expected[i], [[result objectAtIndex:i] floatValue], 0.001);
	}
}

- (void)testSundayCase {
    unsigned long long array[29] = {16326, 55155, 55344, 47174, 34431, 32727,
        19400, 11078, 13635, 59720, 59765, 43384, 73120, 22268, 11468, 51703,
        47668, 42182, 24042, 39180, 2623, 13885, 41793, 47360, 33942, 54294,
        53956, 3775, 1417};
	NSArray *_datesArray = @[@"2015-02-08",
        @"2015-02-09", @"2015-02-10",
        @"2015-02-11", @"2015-02-12",
        @"2015-02-13", @"2015-02-14",
        @"2015-02-15", @"2015-02-16",
        @"2015-02-17", @"2015-02-18",
        @"2015-02-19", @"2015-02-20",
        @"2015-02-21", @"2015-02-22",
        @"2015-02-23", @"2015-02-24",
        @"2015-02-25", @"2015-02-26",
        @"2015-02-27", @"2015-02-28",
        @"2015-03-01", @"2015-03-02",
        @"2015-03-03", @"2015-03-04",
        @"2015-03-05", @"2015-03-06",
        @"2015-03-07", @"2015-03-08"];
	NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyy-MM-dd"];

	NSMutableArray *dates = [[NSMutableArray alloc] init], *keystrokes = [[NSMutableArray alloc] init];

	for (int i = 0; i < [_datesArray count]; i++) {
		[dates addObject:[dateFormat dateFromString:[_datesArray objectAtIndex:i]]];
		[keystrokes addObject:[NSNumber numberWithUnsignedLongLong:array[i]]];
	}

	NSArray *result = [YVBUtilities weeklyAverageForData:keystrokes perDate:dates];

    float expected[29] = {37222.43, 37222.43, 37222.43, 37222.43, 37222.43,
        37222.43, 37222.43, 40424.29, 40424.29, 40424.29, 40424.29, 40424.29,
        40424.29, 40424.29, 31266.57, 31266.57, 31266.57, 31266.57, 31266.57,
        31266.57, 31266.57, 35572.14, 35572.14, 35572.14, 35572.14, 35572.14,
		35572.14, 35572.14, 1417};

	for (int i = 0; i < [result count]; i++) {
		XCTAssertEqualWithAccuracy(expected[i], [[result objectAtIndex:i] floatValue], 0.01);
	}
}


@end
