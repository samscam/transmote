//
//  TRNAppDelegate.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import "TRNAppDelegate.h"

@interface TRNAppDelegate(){

}

@end

@implementation TRNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    [self setupDefaults];
    
    self.mainWindowController=[[TRNWindowController alloc] initWithWindowNibName:@"TRNWindowController"];
    self.window=self.mainWindowController.window;
    
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
    if (self.mainWindowController.server){
        [self.mainWindowController.server addMagnetLink:url];
    } else {
        self.deferredMagnetURL=url;
    }
}

- (void)setupDefaults{
    
    // Load default defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];
}

@end
