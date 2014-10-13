//
//  YVBDailyExecutor.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 12/27/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "YVBDailyExecutor.h"

@implementation YVBDailyExecutor

@synthesize currentDate = _currentDate;
@synthesize isRunning = _isRunning;
@synthesize handler = _handler;
@synthesize timer = _timer;

-(id)init{
	if (self = [super init]) {
		_isRunning = NO;
		_currentDate = [self _getCurrentDate];
		_handler = ^(void){
			NSLog(@"%s callback", __FILE__);
		};
		_timer = nil;
	}
	return self;
}

-(id)initWithHandler:(YVBExecutionBlock)aHandler{
	if (self = [self init]) {
		[self setHandler:aHandler];
	}
	return self;
}

// http://stackoverflow.com/a/5611700/379593
-(NSDate *)_getCurrentDate{
	NSDate *now = [NSDate date];
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
	return [calendar dateFromComponents:components];
}

-(void)start{
	isRunning = YES;

	if (!_timer) {
		_timer = [NSTimer scheduledTimerWithTimeInterval:300.0f
												  target:self
												selector:@selector(timerCallback:)
												userInfo:nil
												 repeats:YES];
	}
}

-(void)stop{
	if (_timer && [_timer isValid]) {
		// do not invalidate the timer, doing so makes the program crash
		_timer = nil;
	}

	isRunning = NO;
}

-(void)timerCallback:(NSTimer *)timer{
	NSUInteger a = [[NSCalendar currentCalendar] ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:_currentDate];
	NSUInteger b = [[NSCalendar currentCalendar] ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:[self _getCurrentDate]];

#ifdef DEBUG
	NSLog(@"Timer callback ...");
#endif

	if (a != b) {
#ifdef DEBUG
		NSLog(@"Day has changed ...");
#endif
		_currentDate = [self _getCurrentDate];
		_handler();

		return;
	}
}

@end
