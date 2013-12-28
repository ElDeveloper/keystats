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

-(id)init{
	if (self = [super init]) {
		_isRunning = NO;
		_currentDate = nil;
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

-(void)start{
	isRunning = YES;

	// adapted from the answer in http://stackoverflow.com/q/2410186/379593
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *comps = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
										  fromDate:[NSDate date]];
	[comps setHour: 23];
	[comps setMinute: 59];
	[comps setSecond: 59];
	NSDate *pmDate = [calendar dateFromComponents:comps];
	NSTimeInterval interval = [pmDate timeIntervalSinceNow];

	// avoid callback after callback for 23:59:59 ...
	if (interval < 0) {
		[NSThread sleepForTimeInterval:1.11];
	}

	_timer = [NSTimer scheduledTimerWithTimeInterval:interval
											  target:self
											selector:@selector(timerCallback)
											userInfo:nil
											 repeats:NO];
}

-(void)stop{
	[_timer invalidate];
	_timer = nil;

	isRunning = NO;
}

-(void)timerCallback{
	_handler();

	[self start];
}

@end
