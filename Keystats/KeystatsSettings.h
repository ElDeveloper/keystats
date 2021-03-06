//
//  KeystatsSettings.h
//  Keystats
//
//  Created by Yoshiki Vázquez Baeza on 6/28/19.
//  Copyright © 2019 Yoshiki Vázquez Baeza. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeystatsSettings : NSObject

// construction
- (id)init;
+ (KeystatsSettings *)sharedController;

- (void)writeSettings;
- (void)loadSettings;
- (NSURL *)location;

@property (nonatomic, strong) NSColor *color;
@property (nonatomic, strong) NSNumber *saveDateAndKeystroke;

@end

NS_ASSUME_NONNULL_END
