//
//  YVBKeystrokesSummaryView.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 1/7/14.
//  Copyright (c) 2014 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface YVBKeystrokesSummaryViewController : NSViewController{
	IBOutlet NSTextField * __weak totalCountLabel;
	IBOutlet NSTextField * __weak todayCountLabel;
	IBOutlet NSTextField * __weak lastSevenDaysCountLabel;
	IBOutlet NSTextField * __weak lastThirtyDaysCountLabel;
}

@property (nonatomic, weak) IBOutlet NSTextField * totalCountLabel;
@property (nonatomic, weak) IBOutlet NSTextField * todayCountLabel;
@property (nonatomic, weak) IBOutlet NSTextField * lastSevenDaysCountLabel;
@property (nonatomic, weak) IBOutlet NSTextField * lastThirtyDaysCountLabel;

-(id)init;
-(void)updateWithTotalValue:(NSString *)total todayValue:(NSString *)today
		 lastSevenDaysValue:(NSString *)lastSevenDaysValue
	 andLastThirtyDaysValue:(NSString *)lastThirtyDaysValue;

@end
