//
//  KeystatsSettings.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 6/28/19.
//  Copyright © 2019 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "KeystatsSettings.h"

@implementation KeystatsSettings

static NSString *kSettingsPath = @"Keystats/settings.plist";

static KeystatsSettings *sharedController = nil;

+ (KeystatsSettings *)sharedController {
	if (sharedController == nil) {
		sharedController = [[self alloc] init];
	}
	return sharedController;
}

- (void)registerGeneralNotifications {
}

- (id) init {
	if (self = [super init]) {
		self.saveDateAndKeystroke = [NSNumber numberWithBool:NO];
		self.color = [NSColor colorWithRed:93.0f/255.0f green:130.0f/255.0f blue:176.0f/255.0f alpha:1];

        [self loadSettings];
	}
	return self;
}

- (NSURL *)location {
    NSURL *appSupportDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                                  inDomain:NSUserDomainMask
                                                         appropriateForURL:nil
                                                                    create:YES
                                                                     error:nil];
    NSURL *path = [appSupportDir URLByAppendingPathComponent:kSettingsPath isDirectory:NO];
    return path;
}

#pragma mark Settings load/save (inspired by MacFusion)
- (void)writeSettings {
    NSURL *location = [self location];
	BOOL isDir;

	if (![[NSFileManager defaultManager] fileExistsAtPath:[[location path] stringByDeletingLastPathComponent] isDirectory:&isDir] || !isDir) {
		NSError *error = nil;
        BOOL ok = [[NSFileManager defaultManager] createDirectoryAtURL:location withIntermediateDirectories:YES attributes:nil error:&error];

		if (!ok) {
			NSLog(@"Failed to create directory for writing settings: %@", [error localizedDescription]);
		}
	}

	NSDictionary *contents = @{@"saveDateAndKeystrokes": self.saveDateAndKeystroke,
							   @"color": [NSArchiver archivedDataWithRootObject:self.color]};

	BOOL writeOK = [contents writeToFile:[location path] atomically:YES];
	if (!writeOK) {
		NSLog(@"Could not write settings to file.");
	}
}

- (void)loadSettings {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfURL:[self location]];

    if (settings) {
		[self setSaveDateAndKeystroke:[settings objectForKey:@"saveDateAndKeystrokes"]];

        // colors are stored as data
        NSColor *color = (NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings objectForKey:@"color"]];
		[self setColor:color];
	}
}

@end
