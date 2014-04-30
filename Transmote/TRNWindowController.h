//
//  TRNWindowController.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TRNServer.h"

@interface TRNWindowController : NSWindowController

@property (nonatomic,strong) TRNServer *server;

@property (weak) IBOutlet NSArrayController *arrayController;

@property (weak) IBOutlet NSScrollView *tableScrollView;
@property (weak) IBOutlet NSTableView *tableView;

@property (weak) IBOutlet NSButton *serverToolbarButton;
@property (weak) IBOutlet NSImageView *statusBlip;

@property (weak) IBOutlet NSPopover *popover;
@property (weak) IBOutlet NSViewController *popoverViewController;


-(IBAction)serverSettingsPopover:(id)sender;

@end
