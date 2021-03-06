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

NSString *YVBKeyLoggerPerishedNotification = @"YVBKeyLoggerPerishedNotification";
NSString *YVBKeyLoggerPerishedByLackOfResponseNotification = @"YVBKeyLoggerPerishedByLackOfResponseNotification";
NSString *YVBKeyLoggerPerishedByUserChangeNotification = @"YVBKeyLoggerPerishedByUserChangeNotification";

CGEventRef recordKeysCallback(CGEventTapProxy proxy, CGEventType type,
							  CGEventRef event, void *userInfo);

@implementation YVBKeyLogger

@synthesize keyPressedHandler, isLogging;

+(BOOL)accessibilityIsEnabled{
	return AXIsProcessTrusted();
}

+(BOOL)requestAccessibilityEnabling{
	NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
	BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);

	return accessibilityEnabled;
}


-(id)init{
	if (self = [super init]) {
		__event = NULL;
		__rl = NULL;

		// log to stdout each of the keys that get pressed
		[self setKeyPressedHandler:^(NSString *string, long long keyCode,
									 CGEventType eventType){
			NSLog(@"%@-Pressed string: [%@] KeyCode: [%lld]",
				  eventType == kCGEventKeyDown ? @"Down" : // continues
				  (eventType == kCGEventKeyUp ? @"Up" : @""), string, keyCode);
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
	CFRunLoopSourceRef rls;
	CGEventMask keyboardMask = CGEventMaskBit(kCGEventKeyDown);

	// we need to keep a reference to this to be able to stop the callbacks
	__rl = CFRunLoopGetCurrent();

	// create event listener
	__event = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, 0,
								keyboardMask, recordKeysCallback,
								Block_copy((__bridge void *)[self keyPressedHandler]));

	// wrap event listener to loopable form
	rls = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, __event, 0);

	// add wrapped listener to loop
	CFRunLoopAddSource(__rl, rls, kCFRunLoopCommonModes);

	// enable event tab
	CGEventTapEnable(__event, true);

	// run event tab
	CFRunLoopRun();
}

-(void)startLogging{
	[self stopLogging];

	// if accessibility is not enabled, don't try to start the keylogger
	if ([YVBKeyLogger accessibilityIsEnabled]){
		isLogging = YES;
		[self _addKeyEventListener];
	}
}

-(void)stopLogging{
	isLogging = NO;

	if (__event != NULL) {
		if (CFMachPortIsValid(__event)) {

			// stopping an event requires you to disable it and invalidate it
			CGEventTapEnable(__event, false);
			CFMachPortInvalidate(__event);
			CFRelease(__event);

			if (__rl != NULL) {
				CFRunLoopStop(__rl);
			}
		}
		__event = NULL;
	}
}

CGEventRef recordKeysCallback(CGEventTapProxy proxy, CGEventType type,
							  CGEventRef event, void *userInfo){

	// only key-up, key-down and flagsChanged events are listened to; other
	// events like mouse coordinates changed or function keys will be ignored
	if (type != kCGEventKeyDown && type != kCGEventKeyUp &&
		type != kCGEventFlagsChanged){
		return event;
	}

	if (type == kCGEventTapDisabledByTimeout) {
		// send a notification to let observers know that the keylogger has
		// encountered a problem that made the OS kill the callbacks
		[[NSNotificationCenter defaultCenter] postNotificationName:YVBKeyLoggerPerishedByLackOfResponseNotification
															object:nil
														  userInfo:nil];

		return event;
	}
	if ( type == kCGEventTapDisabledByUserInput ) {
		// send a notification to let observers know that the keylogger has
		// encountered a problem that made the OS kill the callbacks
		[[NSNotificationCenter defaultCenter] postNotificationName:YVBKeyLoggerPerishedByUserChangeNotification
															object:nil
														  userInfo:nil];
		return event;
	}

	YVBKeyPressed keyPressedBlock = (__bridge YVBKeyPressed) userInfo;

	long long pressedKeyCode;
	UniChar *stringOfPressedKeys = (UniChar *) malloc(sizeof(UniChar)*4);
	UniCharCount charactersInString = 0;
	CGEventFlags flags;
	NSString *result;

	pressedKeyCode = CGEventGetIntegerValueField(event,kCGKeyboardEventKeycode);
	CGEventKeyboardGetUnicodeString(event, 4, &charactersInString,
									stringOfPressedKeys);

	// if the string is empty we will ignore this call right away
	if (!stringOfPressedKeys) {
		return event;
	}

	// get the modifier keys if any of them were pressed
	flags = CGEventGetFlags(event);

	// conver the array of characters into a NSStrgin object for easy handling
	result = [NSString stringWithCharacters:stringOfPressedKeys
									 length:charactersInString];

	// free all the mallocs
	free(stringOfPressedKeys);

	// make the callback execution
	keyPressedBlock(result, pressedKeyCode, type);

	return event;
}

@end
