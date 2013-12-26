//
//  YVBKeystrokesDataManager.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 10/31/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "YVBKeystrokesDataManager.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

@implementation YVBKeystrokesDataManager
@synthesize queue = _queue;
@synthesize filePath = _filePath;

-(id)init{
	if (self = [super init]) {
		_queue = nil;
		_filePath = nil;
	}
	return self;
}
-(id)initWithFilePath:(NSString *)databaseFilePath{
	if (self = [self init]) {
		[self setFilePath:databaseFilePath];

		// the queue will error out in case there's a problem with the DB
		_queue = [FMDatabaseQueue databaseQueueWithPath:_filePath];
	}
	return self;
}

-(void)_getCountForQuery:(NSString *)query andHandler:(YVBResult)handler{

	[_queue inDatabase:^(FMDatabase *db) {
		NSString *result;
		FMResultSet *countTotalResult = [db executeQuery:query];
		if ([countTotalResult next]) {
			result = [[NSString alloc] initWithString:[countTotalResult stringForColumnIndex:0]];
		}
		[countTotalResult close];

		handler(result);
	}];
}

-(void)getTotalCount:(YVBResult)handler{
	[self _getCountForQuery:@"SELECT COUNT(*) FROM keystrokes;" andHandler:handler];
}

-(void)getTodayCount:(YVBResult)handler{
	[self _getCountForQuery:@"SELECT COUNT(*) FROM keystrokes WHERE DATE(JULIANDAY(timestamp)) == DATE(JULIANDAY('now'));" andHandler:handler];
}

-(void)getWeeklyCount:(YVBResult)handler{
	[self _getCountForQuery:@"SELECT COUNT(*) FROM keystrokes WHERE DATE(JULIANDAY(timestamp)) > DATE(JULIANDAY('now')-7);" andHandler:handler];
}

-(void)getMonthlyCount:(YVBResult)handler{
	[self _getCountForQuery:@"SELECT COUNT(*) FROM keystrokes WHERE DATE(JULIANDAY(timestamp)) > DATE(JULIANDAY('now')-30);" andHandler:handler];
}

-(void)addKeystrokeWithTimeStamp:(NSString *)timestamp string:(NSString *)stringValue keycode:(long long)keyCode andEventType:(CGEventType)eventType{
	// SQL insert
	[_queue inDatabase:^(FMDatabase *db) {
		NSString *sqlInsert = [NSString stringWithFormat:@"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', %d, %llu, '%@'); commit;", timestamp, eventType, keyCode, stringValue];
		if (![db executeUpdate:sqlInsert]) {
			// to avoid checking if
			if ([stringValue isEqualToString:@"'"]) {
				sqlInsert = [NSString stringWithFormat:@"INSERT INTO keystrokes (timestamp, type, keycode, ascii) VALUES('%@', %d, %llu, \"%@\"); commit;", timestamp, eventType, keyCode, stringValue];
				[db executeUpdate:sqlInsert];
			}
			NSLog(@"Unexpected error %@ FAILED!", sqlInsert);
		}
	}];
}

-(BOOL)managerIsHealthy{
	return NO;
}

@end
