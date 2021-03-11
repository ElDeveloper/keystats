//
//  SettingsViewController.m
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 6/28/19.
//  Copyright © 2019 Yoshiki Vázquez Baeza. All rights reserved.
//

#import "SettingsViewController.h"
#import "KeystatsSettings.h"

@implementation SettingsViewController

@synthesize colorPicker = _colorPicker;
@synthesize checkbox = _checkbox;

- (void)windowDidLoad {
    [super windowDidLoad];

	settings = [KeystatsSettings sharedController];

    [_colorPicker setColor:[settings color]];
    [_checkbox setState:[[settings saveDateAndKeystroke] boolValue] ? NSControlStateValueOn : NSControlStateValueOff];
}

- (IBAction)checkboxChanged:(id)sender {
	NSButton *checkbox = (NSButton *)sender;

	[settings setValue:[NSNumber numberWithBool:[checkbox state] == NSControlStateValueOn]
				forKey:@"saveDateAndKeystroke"];
	[settings writeSettings];
}

- (IBAction)colorPickerChanged:(id)sender {
	NSColorWell *colorWell = (NSColorWell *)sender;

	[settings setValue:[colorWell color] forKey:@"color"];
	[settings writeSettings];
}

@end
