//
//  YVBKeystrokesDataManager.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 10/31/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;

// handler block for the query execution callback
typedef void __block (^YVBResult)(NSString *result);


@interface YVBKeystrokesDataManager : NSObject{
	FMDatabaseQueue *queue;
	NSString *filePath;
	NSNumberFormatter *resultFormatter;
}

@property (nonatomic, retain) FMDatabaseQueue *queue;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSNumberFormatter *resultFormatter;

-(id)init;
-(id)initWithFilePath:(NSString *)databaseFilePath;

-(void)getTotalCount:(YVBResult)handler;
-(void)getTodayCount:(YVBResult)handler;
-(void)getWeeklyCount:(YVBResult)handler;
-(void)getMonthlyCount:(YVBResult)handler;

-(void)addKeystrokeWithTimeStamp:(NSString *)timestamp string:(NSString *)stringValue keycode:(long long)keyCode andEventType:(CGEventType)eventType;

-(BOOL)managerIsHealthy;

@end
