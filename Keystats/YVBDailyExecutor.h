//
//  YVBDailyExecutor.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 12/27/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Foundation/Foundation.h>

// handler block for the key pressed callback
typedef void __block (^YVBExecutionBlock)(void);

@interface YVBDailyExecutor : NSObject{
	NSDate *currentDate;
	BOOL isRunning;
	YVBExecutionBlock handler;

	NSTimer *_timer;
}

@property (nonatomic, retain) NSDate *currentDate;
@property (nonatomic, readonly) BOOL isRunning;
@property (nonatomic, copy) YVBExecutionBlock handler;

-(id)init;
-(id)initWithHandler:(YVBExecutionBlock)aHandler;

-(void)start;
-(void)stop;

@end
