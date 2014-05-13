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


@property (weak) IBOutlet NSButton *serverToolbarButton;
@property (weak) IBOutlet NSImageView *statusBlip;

@property (weak) IBOutlet NSPopover *settingsPopover;
@property (weak) IBOutlet NSViewController *popoverViewController;

@property (weak) IBOutlet NSPopover *deleteConfirmPopover;
@property (weak) IBOutlet NSViewController *deleteConfirmPopoverViewController;

@property (weak) IBOutlet NSCollectionView *collectionView;

@property (weak) IBOutlet NSButton *removeTorrentButton;
@property (weak) IBOutlet NSTextField *deleteMessageField;

@property (weak) IBOutlet NSButton *versionButton;


@property (weak) IBOutlet NSBox *passiveAlertBox;
@property (weak) IBOutlet NSTextField *passiveAlertMessageField;
@property (weak) IBOutlet NSImageView *passiveAlertImageView;

-(IBAction) serverSettingsPopover:(id)sender;
-(IBAction) confirmDeleteSelectedTorrents:(id)sender;
-(IBAction) confirmRemoveSelectedTorrents:(id)sender;
-(IBAction) confirmedRemoveOrDelete:(id)sender;

-(IBAction) checkForUpdatesButtonPressed:(id)sender;

@end
