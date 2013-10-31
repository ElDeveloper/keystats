//
//  YVBKeystrokesDataManager.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 10/31/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;

@interface YVBKeystrokesDataManager : NSObject{
	FMDatabase *database;
	NSString *filePath;
}

@property (nonatomic, retain) FMDatabase *database;
@property (nonatomic, retain) NSString *filePath;

-(id)init;
-(id)initWithFilePath:(NSString *)databaseFilePath;

-(NSString *)getTotalCount;
-(NSString *)getTodayCount;
-(NSString *)getWeeklyCount;
-(NSString *)getMonthlyCount;

-(BOOL)addKeystrokeWithTimeStamp:(NSString *)timestamp string:(NSString *)stringValue keycode:(long long)keyCode andEventType:(CGEventType)eventType;

-(BOOL)managerIsHealthy;

@end
