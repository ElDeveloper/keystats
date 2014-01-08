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
		_currentDate = nil;
		_handler = ^(void){
			NSLog(@"%s callback", __FILE__);
		};
		_timer = nil;

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(systemClockChanged:)
													 name:NSSystemClockDidChangeNotification
												   object:nil];
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

	NSTimeInterval interval;
	NSCalendar *calendar = nil;
	NSDateComponents *components = nil;
	NSDate *lastSecondDate = nil;

	// avoid a multitude of callbacks for 23:59:59...
	do {
		// adapted from the answer in http://stackoverflow.com/q/2410186/379593
		calendar = [NSCalendar currentCalendar];
		components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
								 fromDate:[NSDate date]];
		lastSecondDate = nil;

		[components setHour: 23];
		[components setMinute: 59];
		[components setSecond: 59];

		lastSecondDate = [calendar dateFromComponents:components];
		interval = [lastSecondDate timeIntervalSinceNow];

		if (interval < 1) {
			[NSThread sleepForTimeInterval:1.11];
		}
	}
	while (interval < 1);

	if (!_timer) {
		_timer = [NSTimer scheduledTimerWithTimeInterval:interval
												  target:self
												selector:@selector(timerCallback:)
												userInfo:nil
												 repeats:NO];
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
	_handler();

	[self stop];
	[self start];
}

-(void)systemClockChanged:(NSNotification *)notification{
	// Update just to make sure everything is consistent in the GUI
	_handler();

	[self stop];
	[self start];
}

@end
