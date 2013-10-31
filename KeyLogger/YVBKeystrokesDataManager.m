//
//  YVBKeystrokesDataManager.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 10/31/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "YVBKeystrokesDataManager.h"
#import "FMDatabase.h"

@implementation YVBKeystrokesDataManager
@synthesize database = _database;
@synthesize filePath = _filePath;

-(id)init{
	if (self = [super init]) {
		_database = nil;
		_filePath = nil;
	}
	return self;
}
-(id)initWithFilePath:(NSString *)databaseFilePath{
	if (self = [self init]) {
		[self setFilePath:databaseFilePath];
		_database = [FMDatabase databaseWithPath:_filePath];
		if (![_database open]) {
			NSLog(@"Could not successfully open the database");
		}
	}
	return self;
}

-(NSString *)getTotalCount{
	NSString *result = nil;

	FMResultSet *countTotalResult = [_database executeQuery:@"SELECT COUNT(*) FROM keystrokes;"];
	if ([countTotalResult next]) {
		result = [[NSString alloc] initWithString:[countTotalResult stringForColumnIndex:0]];
	}
	[countTotalResult close];

	return result;
}

-(NSString *)getTodayCount{
	return nil;
}

-(NSString *)getWeeklyCount{
	return nil;
}

-(NSString *)getMonthlyCount{
	return nil;
}

-(BOOL)addKeystrokeWithTimeStamp:(NSString *)timestamp string:(NSString *)stringValue keycode:(long long)keyCode andEventType:(CGEventType)eventType{
	// SQL insert
	NSString *sqlInsert = [NSString stringWithFormat:@"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', %d, %llu, '%@'); commit;", timestamp, eventType, keyCode, stringValue];
		if (![_database executeUpdate:sqlInsert]) {
			NSLog(@"Unexpected error %@ FAILED!", sqlInsert);
			return NO;
		}
	return YES;
}

-(BOOL)managerIsHealthy{
	return [_database goodConnection];
}

@end
