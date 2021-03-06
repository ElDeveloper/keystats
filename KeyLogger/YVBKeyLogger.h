//
//  YVBKeyLogger.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 10/27/13.
//  Based in code from J. Koivisto S.A.C. found in OSXKeyLogger
//  https://code.google.com/p/osxkeylogger
//
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Foundation/Foundation.h>

// handler block for the key pressed callback
typedef void __block (^YVBKeyPressed)(NSString *string, long long keyCode,
									  CGEventType eventType);

extern NSString *YVBKeyLoggerPerishedNotification;
extern NSString *YVBKeyLoggerPerishedByLackOfResponseNotification;
extern NSString *YVBKeyLoggerPerishedByUserChangeNotification;

@interface YVBKeyLogger : NSObject{
	YVBKeyPressed keyPressedHandler;
	BOOL isLogging;

	@private
	CFMachPortRef __event;
	CFRunLoopRef __rl;
}

+(BOOL)accessibilityIsEnabled;
+(BOOL)requestAccessibilityEnabling;

-(id)init;
-(id)initWithKeyPressedHandler:(YVBKeyPressed)handler;

-(void)startLogging;
-(void)stopLogging;

@property (nonatomic, copy) YVBKeyPressed keyPressedHandler;
@property (nonatomic, readonly) BOOL isLogging;

@end
