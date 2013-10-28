//
//  YVKeyLogger.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 10/27/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "YVBKeyLogger.h"

#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>

CGEventRef recordKeysCallback(CGEventTapProxy proxy, CGEventType type,
							  CGEventRef event, void *userInfo);

@implementation YVBKeyLogger

@synthesize keyPressedHandler, isLogging;

-(id)init{
	if (self = [super init]) {
		// log to stdout each of the keys that get pressed
		[self setKeyPressedHandler:^(NSString *string, long long keyCode){
			NSLog(@"Pressed string: [%@] KeyCode: [%lld]", string, keyCode);
		}];
	}
	return self;
}

-(id)initWithKeyPressedHandler:(YVBKeyPressed)handler{
	if (self = [self init]) {
		[self setKeyPressedHandler:handler];
	}
	return self;
}

-(void)_addKeyEventListener{
	CFMachPortRef		eventTap;
	CFRunLoopSourceRef	runLoopSource;

	// create event listener
	eventTap = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, 0,
								kCGEventMaskForAllEvents, recordKeysCallback,
								(__bridge void *)[self keyPressedHandler]);

	// wrap event listener to loopable form
	runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap,
												  0);

	// add wrapped listener to loop
	CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource,
					   kCFRunLoopCommonModes);

	// enable event tab
	CGEventTapEnable(eventTap, true);

	// run event tab
	CFRunLoopRun();
}

-(void)startLogging{
	[self _addKeyEventListener];
	isLogging = YES;
}

-(void)stopLogging{
	// do something magical that will let you stop listening to the events
	isLogging = NO;
}

CGEventRef recordKeysCallback(CGEventTapProxy proxy, CGEventType type,
							  CGEventRef event, void *userInfo){

	// only key-up, key-down and flagsChanged events are listened to; other
	// events like mouse coordinates changed or function keys will be ignored
	if (type != kCGEventKeyDown && type != kCGEventKeyUp &&
		type != kCGEventFlagsChanged){
				return event;
	}

	YVBKeyPressed keyPressedBlock = (__bridge YVBKeyPressed) userInfo;

	long long pressedKeyCode;
	UniChar *stringOfPressedKeys = (UniChar *) malloc(sizeof(UniChar)*1024);
	UniCharCount charactersInString = 0;
	CGEventFlags flags;
	NSString *result;

	pressedKeyCode = CGEventGetIntegerValueField(event,kCGKeyboardEventKeycode);
	CGEventKeyboardGetUnicodeString(event, 1024, &charactersInString,
									stringOfPressedKeys);

	// if the string is empty we will ignore this call right away
	if (!stringOfPressedKeys) {
		return event;
	}

	// get the modifier keys if any of them were pressed
	flags = CGEventGetFlags (event);

	result = [NSString stringWithCharacters:stringOfPressedKeys
									 length:charactersInString];

	// free all the mallocs
	free(stringOfPressedKeys);

	// call the block
	keyPressedBlock(result, pressedKeyCode);
	return event;
}

@end
