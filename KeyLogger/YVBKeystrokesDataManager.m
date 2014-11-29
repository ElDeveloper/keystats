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
@synthesize resultFormatter = _resultFormatter;

NSString *YVBDataManagerErrored = @"YVBDataManagerErrored";

-(id)init{
	if (self = [super init]) {
		_queue = nil;
		_filePath = nil;
		_resultFormatter = [[NSNumberFormatter alloc] init];
		[_resultFormatter setNumberStyle:NSNumberFormatterDecimalStyle];

		// Make the result look like 11,111,111
		[_resultFormatter setGroupingSize:3];
		[_resultFormatter setHasThousandSeparators:YES];
		[_resultFormatter setThousandSeparator:@","];
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

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
											 (unsigned long)NULL), ^(void) {
		[_queue inDatabase:^(FMDatabase *db) {
			NSNumber *result;
			FMResultSet *countTotalResult = [db executeQuery:query];
			if ([countTotalResult next]) {
				result = [[NSNumber alloc] initWithLong:[countTotalResult longForColumnIndex:0]];
			}
			[countTotalResult close];

			handler([_resultFormatter stringFromNumber:result]);
		}];
	});

}

-(void)getTotalCount:(YVBResult)handler{
	[self _getCountForQuery:@"SELECT COUNT(*) FROM keystrokes;" andHandler:handler];
}

-(void)getTodayCount:(YVBResult)handler{
	[self _getCountForQuery:@"SELECT COUNT(*) FROM keystrokes WHERE timestamp BETWEEN strftime('%Y-%m-%d', 'now', 'localtime') AND strftime('%Y-%m-%d', 'now', '+1 day', 'localtime');" andHandler:handler];
}

-(void)getWeeklyCount:(YVBResult)handler{
	[self _getCountForQuery:@"SELECT COUNT(*) FROM keystrokes WHERE timestamp BETWEEN strftime('%Y-%m-%d', 'now', '-7 day', 'localtime') AND strftime('%Y-%m-%d', 'now', '+1 day', 'localtime');" andHandler:handler];
}

-(void)getMonthlyCount:(YVBResult)handler{
	[self _getCountForQuery:@"SELECT COUNT(*) FROM keystrokes WHERE timestamp BETWEEN strftime('%Y-%m-%d', 'now', '-30 day', 'localtime') AND strftime('%Y-%m-%d', 'now', '+1 day', 'localtime');" andHandler:handler];
}

-(void)getEarliestDate:(YVBResult)handler{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
											 (unsigned long)NULL), ^(void) {
		[_queue inDatabase:^(FMDatabase *db) {
			NSString *value;
			FMResultSet *result = [db executeQuery:@"SELECT MIN(timestamp) FROM keystrokes;"];
			if ([result next]) {
				value = [result stringForColumnIndex:0];
			}
			[result close];

			handler(value);
		}];
	});
}

-(void)getKeystrokesPerDay:(YVBResultSeries)handler{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
											 (unsigned long)NULL), ^(void) {
		[_queue inDatabase:^(FMDatabase *db) {
			NSMutableArray *x=[[NSMutableArray alloc] init], *y=[[NSMutableArray alloc] init];

			// otherwise we get epoch dates
			NSDateFormatter * dateFormat = [[NSDateFormatter alloc] init];
			[dateFormat setDateFormat:@"yyyy-MM-dd"];
			[db setDateFormat:dateFormat];

			FMResultSet *result = [db executeQuery:@"SELECT SUBSTR(timestamp, 0, 11), COUNT(*) FROM keystrokes WHERE timestamp BETWEEN strftime('%Y-%m-%d', 'now', '-30 day', 'localtime') AND strftime('%Y-%m-%d', 'now', '+1 day', 'localtime') GROUP BY CAST(JULIANDAY(timestamp) as int) ORDER BY timestamp ASC LIMIT 30;"];
			while ([result next]) {
				[x addObject:[result dateForColumnIndex:0]];
				[y addObject:[NSNumber numberWithUnsignedLongLong:[result unsignedLongLongIntForColumnIndex:1]]];
			}
			[result close];
			handler(x, y);
		}];
	});

}

-(void)addKeystrokeWithTimeStamp:(NSString *)timestamp string:(NSString *)stringValue keycode:(long long)keyCode eventType:(CGEventType)eventType andApplicationBundleIdentifier:(NSString *)bid{
	// SQL insert
	[_queue inDatabase:^(FMDatabase *db) {
		NSDictionary *insertArgs = @{@"timestamp": timestamp,
									@"type": [NSNumber numberWithInt:eventType],
									@"keycode": [NSNumber numberWithLongLong:keyCode],
									@"ascii": stringValue,
									@"bundle_id": bid};
		if (![db executeUpdate:@"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES(:timestamp, :type, :keycode, :ascii, :bundle_id); commit;" withParameterDictionary:insertArgs]) {
			[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
				[[NSNotificationCenter defaultCenter] postNotificationName:YVBDataManagerErrored
																	object:nil
																  userInfo:@{@"message": [NSString stringWithFormat:@"INSERT INTO keystrokes (timestamp, type, keycode, ascii, bundle_id) VALUES((%@, %d, %llu, %@, %@); commit;", timestamp, eventType, keyCode, stringValue, bid]}];

			}];
		}
	}];
}

-(BOOL)managerIsHealthy{
	return NO;
}

@end
