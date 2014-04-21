//
//  TRNWindowController.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import "TRNWindowController.h"

@implementation TRNWindowController

static void *obvContext=&obvContext;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.server=[[TRNServer alloc] init];
        [self.server addObserver:self forKeyPath:@"connected" options:NSKeyValueObservingOptionNew context:obvContext];
        [self.server connect];
    }
    return self;
}

-(IBAction)boing:(id)sender{
    NSLog(@"BOING!");
}

-(IBAction)serverSettingsPopover:(id)sender{
    NSView *toolbarItemView=((NSButton*)sender);
    
    [self.popover showRelativeToRect:[toolbarItemView bounds]
                              ofView:toolbarItemView
                       preferredEdge:NSMaxYEdge];

}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if (context==&obvContext){
        if (self.server.connected){
            self.statusBlip.image=[NSImage imageNamed:@"NSStatusAvailable"];
            [self.tableView reloadData];
            [self.tableScrollView setHidden:NO];
        } else {
            self.statusBlip.image=[NSImage imageNamed:@"NSStatusUnavailable"];
            [self.tableScrollView setHidden:YES];
        }
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

@end
