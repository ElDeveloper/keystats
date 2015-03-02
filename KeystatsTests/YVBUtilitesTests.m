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

@end
