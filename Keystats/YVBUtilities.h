//
//  YVBUtilities.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 3/1/15.
//  Copyright (c) 2015 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YVBUtilities : NSObject

+(NSArray *)weeklyAverageForData:(NSArray *)dataArray perDate:(NSArray *)dateArray;

@end
