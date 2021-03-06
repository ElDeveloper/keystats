//
//  AppDelegate.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 10/22/13.
//  Copyright (c) 2013 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "AppDelegate.h"

#import "YVBKeyLogger.h"
#import "FMDB.h"
#import "YVBKeystrokesDataManager.h"
#import "YVBDailyExecutor.h"
#import "YVBKeystrokesSummaryViewController.h"
#import "SettingsViewController.h"
#import "KeystatsSettings.h"

@implementation AppDelegate

@synthesize summaryView = _summaryView;
@synthesize waitingForConfirmation = _waitingForConfirmation;
@synthesize mainLogger = _mainLogger;

- (void)awakeFromNib{
	// now check that we have accessibility access
	if (![YVBKeyLogger accessibilityIsEnabled] && ![self applicationIsRunningTests] ) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"Keystats has not yet been allowed as an "
		 "assistive application."];
		[alert setInformativeText:@"Keystats requires that 'Enable access for "
		 "assistive devices' in the 'Universal Access' preferences panel be "
		 "enabled in order to register the keys being pressed. Once you do "
		 "this, restart Keystats."];
		[alert addButtonWithTitle:@"Quit"];
		[alert addButtonWithTitle:@"Enable Accessibility"];
		[alert setAlertStyle:NSCriticalAlertStyle];

		// modal alerts block the main thread so they get a return code
		NSInteger result = [alert runModal];

		if (result == NSAlertFirstButtonReturn) {
			[NSApp terminate:self];

		}
		else if (result == NSAlertSecondButtonReturn) {
			[YVBKeyLogger requestAccessibilityEnabling];
			[NSApp terminate:self];
		}

	}
    _saveDateAndKeystroke = [NSNumber numberWithBool:NO];
	_knowsEarliestDate = NO;
	_mainLogger = nil;
	__tasksCompleted = 0;
	_settings = nil;

	// add the view controller & reposition it to a nice location in the window
	CGSize currentSize;
	_summaryView = [[YVBKeystrokesSummaryViewController alloc] init];
	currentSize = [[_summaryView view] frame].size;
	[[_summaryView view] setFrame:CGRectMake(7, 0, currentSize.width,
											 currentSize.height)];
	[[[self window] contentView] addSubview:[_summaryView view]];

	// the keylogger can stop logging at any time as a requirement from the OS
	// make sure we listen to this notification so we can take action about it
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyLoggerPerishedNotification:)
												 name:YVBKeyLoggerPerishedByLackOfResponseNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyLoggerPerishedNotification:)
												 name:YVBKeyLoggerPerishedByUserChangeNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(datamanagerErrored:)
												 name:YVBDataManagerErrored
											   object:nil];
}

- (void)keyLoggerPerishedNotification:(NSNotification *)aNotification{
#ifdef DEBUG
	NSLog(@"KeyLogger perished");
#endif

	NSString *explanationString = @"Keystats has stopped logging keystrokes";
	NSLog(@"Notification name is %@", [aNotification name]);
	if ([[aNotification name] isEqualToString:YVBKeyLoggerPerishedByUserChangeNotification]) {
		explanationString = @"USER CHANGES NOTIFICATION";
	}
	if ([[aNotification name] isEqualToString:YVBKeyLoggerPerishedByLackOfResponseNotification]) {
		explanationString = @"TIMEOUT NOTIFICATION";
	}

	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:explanationString];
	[alert setInformativeText:@"This usually happens when the system is being "
	 "slowed down by the action of logging the keystrokes in your system. "
	 "Keystats is letting you know in case you want to continue Keystats "
	 "regardless or if you've seen this message a few times recently, then "
	 "quit the application and contact the developer."];
	[alert addButtonWithTitle:@"Continue using Keystats"];
	[alert addButtonWithTitle:@"Terminate Keystats"];
	[alert setAlertStyle:NSCriticalAlertStyle];

	// modal alerts block the main thread so they get a return code
	NSInteger result = [alert runModal];

	if (result == NSAlertFirstButtonReturn) {
		// restart the keylogger and unlock this alert
		[self keystatsDidFinishLaunching];
		[self setWaitingForConfirmation:NO];

		return;
	}
	else if (result == NSAlertSecondButtonReturn) {
		[NSApp terminate:self];
	}
}

- (bool)applicationIsRunningTests {
	// https://stackoverflow.com/a/21140663
	NSDictionary* environment = [[NSProcessInfo processInfo] environment];
	return environment[@"XCInjectBundleInto"] != nil;
}

- (void)datamanagerErrored:(NSNotification *)aNotification{
	NSDictionary *dict = [aNotification userInfo];

	NSAlert *errorAlert = [NSAlert new];
	[errorAlert setMessageText:@"An error happened, could not execute:"];
	[errorAlert setInformativeText:[dict objectForKey:@"message"]];

	NSButton *cancelButton = [errorAlert addButtonWithTitle:@"OK"];
	[cancelButton setKeyEquivalent:@"\e"];
	[errorAlert setAlertStyle: NSCriticalAlertStyle];
	[errorAlert beginSheetModalForWindow:[self window]
								   modalDelegate:self
								  didEndSelector:nil
									 contextInfo:nil];

}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"saveDateAndKeystroke"]) {
        _saveDateAndKeystroke = [change objectForKey:@"new"];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification{
	[self keystatsDidFinishLaunching];
}

- (void)keystatsDidFinishLaunching{
	// Insert code here to initialize your application
	NSString *databaseFilePath = [[self pathForApplicationDatabase] path];

	// verify we have a database outside the application's environment
	if (![[NSFileManager defaultManager] fileExistsAtPath:databaseFilePath]) {
		[self copyDatabase];
	}

    _settings = [[SettingsViewController alloc] initWithWindowNibName:@"SettingsViewController"];
	dataManager = [[YVBKeystrokesDataManager alloc] initWithFilePath:databaseFilePath];

	// setup the datamanager and view to listen to changes of the settings object
	KeystatsSettings *settingsModel = [KeystatsSettings sharedController];
	[settingsModel addObserver:self forKeyPath:@"saveDateAndKeystroke" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	[settingsModel addObserver:_summaryView forKeyPath:@"color" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];

	// serve like cache of the values, until I figure out how to query a sqlite
	// database about 100 times per second without it delaying the callbacks
	_totalCountValue = 0;
	_todayCountValue = 0;
	_weeklyCountValue = 0;
	_monthlyCountValue = 0;
	[self computeBufferValuesAndUpdateLabels];

	// this executor will take care on updating the labels on day change
	YVBDailyExecutor *executor = [[YVBDailyExecutor alloc] initWithHandler:^(void){
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,
												 (unsigned long)NULL), ^(void) {
			[self computeBufferValuesAndUpdateLabels];
		});
	}];
	[executor start];

    __block NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];

	__block NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	__block NSString *bundleIdentifier;
	__block NSString *dateString;

	YVBKeyPressed handlerBlock = ^(NSString *string, long long keyCode, CGEventType eventType){
		if (eventType == kCGEventKeyDown) {
			self->_totalCountValue++;
			self->_weeklyCountValue++;
			self->_monthlyCountValue++;
			self->_todayCountValue++;

            // we'll discard the data unless the setting is enabled
            if ([self->_saveDateAndKeystroke boolValue]) {
                [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            }
            else {
                [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:00"];
                string = @"";
                keyCode = 0;
            }

			// update from the count buffers
			[self->_summaryView updateWithTotalValue:[[self->dataManager resultFormatter] stringFromNumber:[NSNumber numberWithLongLong:self->_totalCountValue]]
										  todayValue:[[self->dataManager resultFormatter] stringFromNumber:[NSNumber numberWithLongLong:self->_todayCountValue]]
								  lastSevenDaysValue:[[self->dataManager resultFormatter] stringFromNumber:[NSNumber numberWithLongLong:self->_weeklyCountValue]]
							  andLastThirtyDaysValue:[[self->dataManager resultFormatter] stringFromNumber:[NSNumber numberWithLongLong:self->_monthlyCountValue]]];


			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,
													 (unsigned long)NULL), ^(void) {
				dateString = [dateFormat stringFromDate:[NSDate date]];

				// NSWorkspace's frontmostApplication is not thread safe
				dispatch_sync(dispatch_get_main_queue(), ^{
					bundleIdentifier = [[workspace frontmostApplication] bundleIdentifier];
				});

				[self->dataManager addKeystrokeWithTimeStamp:dateString
													  string:string
													 keycode:keyCode
												   eventType:eventType
							  andApplicationBundleIdentifier:bundleIdentifier];
			});
		}
	};

	_mainLogger = [[YVBKeyLogger alloc] initWithKeyPressedHandler:[handlerBlock copy]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender{
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender{
#if DEBUG
	NSLog(@"Application is terminating, closing the datamanager now");
#endif
	/*
		FIXME: It's fine for now but if the datamanager received a call to
		execute a statement, it would error out because the database would
		be closed. However this should not happen as the return value is
		NSTerminateNow.
	 */
	[[dataManager queue] close];
	return NSTerminateNow;
}


- (void)copyDatabase{
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	NSURL *appSupportDir = [defaultManager URLForDirectory:NSApplicationSupportDirectory
												  inDomain:NSUserDomainMask
										 appropriateForURL:nil
													create:YES
													 error:nil];

	NSURL *keystatsSandbox = [appSupportDir URLByAppendingPathComponent:@"Keystats"];

	// the one in our resources
	NSURL *databaseFilePath = [[NSBundle mainBundle] URLForResource:@"keystrokes"
													  withExtension:@""];
	BOOL directoryCreationWorked;

	NSError *error = nil;

	// check the directory exists already and if it doesn't create it
	if(![defaultManager fileExistsAtPath:[keystatsSandbox path]]) {
		directoryCreationWorked = [defaultManager createDirectoryAtURL:keystatsSandbox
										   withIntermediateDirectories:YES
															attributes:nil
																 error:&error];
		if (!directoryCreationWorked) {
			NSLog(@"Failed to create the Keystats directory: %@", [error localizedDescription]);
			[NSAlert alertWithError:error];
			[NSApp terminate:self];
		}
	}

	// assumming the directory exists by now copy the database there
	if ([defaultManager isReadableFileAtPath:[databaseFilePath path]]){
		[defaultManager copyItemAtURL:databaseFilePath
								toURL:[keystatsSandbox URLByAppendingPathComponent:@"keystrokes"]
								error:&error];
	}
	else{
		NSLog(@"Error writing file to destination: %@. Make sure you have "
			  "permission to write to this directory", [databaseFilePath path]);
		[NSApp terminate:self];
	}

	// in case there was an error after the file was copied
	if (error) {
		NSLog(@"Error copying the database: %@", [error localizedDescription]);
		[NSAlert alertWithError:error];
		[NSApp terminate:self];
	}
}

-(NSURL *)pathForApplicationDatabase{
	NSURL *appSupportDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
																  inDomain:NSUserDomainMask
														 appropriateForURL:nil
																	create:YES
																	 error:nil];
	NSURL *keystatsSandbox = [appSupportDir URLByAppendingPathComponent:@"Keystats/keystrokes"];

	return keystatsSandbox;
}

- (void)_startLogger{
	__tasksCompleted ++;
	if (__tasksCompleted > 5){
		[_mainLogger startLogging];
		__tasksCompleted = 0;
		[_window performSelectorOnMainThread:@selector(setTitle:) withObject:@"Keystats" waitUntilDone:NO];
	}
}

- (void)computeBufferValuesAndUpdateLabels{
	[_mainLogger stopLogging];
	[_window performSelectorOnMainThread:@selector(setTitle:) withObject:@"Keystats (loading ...)" waitUntilDone:NO];

	// set the labels
	[dataManager getTotalCount:^(NSString *result) {

		dispatch_async(dispatch_get_main_queue(), ^(){
			[[self->_summaryView totalCountLabel] setStringValue:result];
			[self _startLogger];
		});
		self->_totalCountValue = [[result stringByReplacingOccurrencesOfString:@","
																	withString:@""] longLongValue];
#ifdef DEBUG
		NSLog(@"The value of total %lld", self->_totalCountValue);
#endif
	}];
	[dataManager getTodayCount:^(NSString *result) {

		dispatch_async(dispatch_get_main_queue(), ^(){
			[[self->_summaryView todayCountLabel] setStringValue:result];
			[self _startLogger];
		});
		self->_todayCountValue = [[result stringByReplacingOccurrencesOfString:@","
																	withString:@""] longLongValue];
#ifdef DEBUG
		NSLog(@"The value of today %lld", self->_todayCountValue);
#endif
	}];
	[dataManager getWeeklyCount:^(NSString *result) {

		dispatch_async(dispatch_get_main_queue(), ^(){
			[[self->_summaryView lastSevenDaysCountLabel] setStringValue:result];
			[self _startLogger];
		});
		self->_weeklyCountValue = [[result stringByReplacingOccurrencesOfString:@","
																	 withString:@""] longLongValue];
#ifdef DEBUG
		NSLog(@"The value of this week %lld", self->_weeklyCountValue);
#endif
	}];
	[dataManager getMonthlyCount:^(NSString *result) {

		dispatch_async(dispatch_get_main_queue(), ^(){
			[[self->_summaryView lastThirtyDaysCountLabel] setStringValue:result];
			[self _startLogger];
		});
		self->_monthlyCountValue = [[result stringByReplacingOccurrencesOfString:@","
																	  withString:@""] longLongValue];
#ifdef DEBUG
		NSLog(@"The value of this month %lld", self->_monthlyCountValue);
#endif
	}];
	[dataManager getKeystrokesPerDay:^(NSArray *x, NSArray *y){

		dispatch_async(dispatch_get_main_queue(), ^(){
			[self->_summaryView updateDailyKeystrokesPlot:@[x, y]];
			[self _startLogger];
		});
#ifdef DEBUG
		NSLog(@"Size of x: %lu size of y: %lu", [x count], [y count]);
		NSLog(@"x: %@, y: %@", x, y);
#endif
	}];

	if (!self->_knowsEarliestDate){
		[dataManager getEarliestDate:^(NSString *result) {
			NSString *dateString;

			// we only need to compute the earliest date one time
			self->_knowsEarliestDate = YES;

			if (!result) {
				dateString = @"";
			}
			else{
				dateString = [NSString stringWithFormat:@"Keystrokes collected since %@", result];
			}

			dispatch_async(dispatch_get_main_queue(), ^(){
				[[self->_summaryView earliestDateLabel] setStringValue:dateString];
				[self _startLogger];
			});
#ifdef DEBUG
			NSLog(@"Collecting since: %@", dateString);
#endif
		}];
	}
	else{
		[self performSelectorOnMainThread:@selector(_startLogger)
							   withObject:nil
							waitUntilDone:NO];
	}

}

- (IBAction)showAboutWindow:(id)sender{
	//Get the information from the plist
	NSDictionary *dictionary = [[NSBundle mainBundle] infoDictionary];;
	NSString *hash = [dictionary objectForKey:@"GitSHA"];
	NSString *status = [dictionary objectForKey:@"GitStatus"];
	NSString *branch = [dictionary objectForKey:@"GitBranch"];

	// If the current branch is master do not output any extra information but
	// the SHA, else then print SHA@BRANCH_NAME for the info in head
	NSString *head = [NSString stringWithFormat:@"%@%@", hash, ([branch isEqualToString:@"master"] ? @"" : [NSString stringWithFormat:@"@%@", branch])];
	NSString *gitInfo;
	NSDictionary *options;

	// when status is 1 the repository has unstaged changes, therefore append a
	// star to tipify a non-clean repository, else just print the SHA1
	gitInfo = [NSString stringWithFormat:@"%@%@",head,([status isEqualToString:@"1"] ? @" *" : @"")];

	// version right now will be the current git SHA and status
	options = [NSDictionary dictionaryWithObjectsAndKeys:gitInfo,@"Version",nil];

	[[NSApplication sharedApplication] orderFrontStandardAboutPanelWithOptions:options];
}

- (IBAction)showSettingsWindow:(id)sender {
	if (!_settings) {
		_settings = [[SettingsViewController alloc] initWithWindowNibName:@"SettingsViewController"];
	}
	[_settings showWindow:self];
}

@end
