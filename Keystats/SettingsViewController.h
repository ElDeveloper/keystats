//
//  SettingsViewController.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 6/28/19.
//  Copyright © 2019 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KeystatsSettings;

NS_ASSUME_NONNULL_BEGIN

@interface SettingsViewController : NSWindowController {

@private KeystatsSettings *settings;

}
@property (assign) IBOutlet NSButton *checkbox;
@property (assign) IBOutlet NSColorWell *colorPicker;

-(IBAction)checkboxChanged:(id)sender;
-(IBAction)colorPickerChanged:(id)sender;

@end

NS_ASSUME_NONNULL_END
