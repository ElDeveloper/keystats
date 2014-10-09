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
typedef void __block (^YVBResultSeries)(NSArray *x, NSArray *y);

extern NSString *YVBDataManagerErrored;

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
-(void)getEarliestDate:(YVBResult)handler;
-(void)getKeystrokesPerDay:(YVBResultSeries)handler;

-(void)addKeystrokeWithTimeStamp:(NSString *)timestamp string:(NSString *)stringValue keycode:(long long)keyCode eventType:(CGEventType)eventType andApplicationBundleIdentifier:(NSString *)bid;

-(BOOL)managerIsHealthy;

@end
