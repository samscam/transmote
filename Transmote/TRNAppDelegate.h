//
//  TRNAppDelegate.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TRNWindowController.h"

@interface TRNAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic,strong) TRNWindowController *mainWindowController;

@property (assign) IBOutlet NSWindow *window;

@end
