//
//  TRNWindowController.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import "TRNWindowController.h"
#import "TRNTorrent.h"
#import <Sparkle/Sparkle.h>

@interface TRNWindowController (){
    BOOL delete;
    SUAppcastItem *pendingUpdateItem;
}

@end

@implementation TRNWindowController

static void *serverContext=&serverContext;
static void *collectionViewContext=&collectionViewContext;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.server=[[TRNServer alloc] init];
    }
    return self;
}

-(void)awakeFromNib{
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"percentDone" ascending:YES];
    [_arrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];

}
-(void) windowDidLoad{
    [super windowDidLoad];
    [self sortOutVersionMessage];
    // Extract the standard delete toolbar icon
    OSType filetype=UTGetOSTypeFromString((CFStringRef)@"tdel");
    self.removeTorrentButton.image=[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(filetype)];
    
    self.collectionView.backgroundColors=@[[NSColor clearColor]];

    
    [self.server addObserver:self forKeyPath:@"connected" options:(NSKeyValueObservingOptionInitial||NSKeyValueObservingOptionNew) context:serverContext];
    [self.server addObserver:self forKeyPath:@"torrents" options:(NSKeyValueObservingOptionInitial||NSKeyValueObservingOptionNew) context:serverContext];
    
    if (!self.server.address){
        [self serverSettingsPopover:nil];
    }
    
    // updater notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatesFound:) name:SUUpdaterDidFindValidUpdateNotification object:nil];
    
    [[SUUpdater sharedUpdater] checkForUpdateInformation];
    
}

#pragma mark - Versioning and updates

-(void) sortOutVersionMessage{
    NSString *versionString=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    
    if (pendingUpdateItem){
        self.versionButton.title=[NSString stringWithFormat:@"Update available: v%@",pendingUpdateItem.versionString];
        [self.versionButton.cell setBackgroundColor:[NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.0 alpha:1.0]];
    } else {
        self.versionButton.title=[NSString stringWithFormat:@"Transmote v%@",versionString];
    }
}

-(void) updatesFound:(NSNotification*)notification{
    
    pendingUpdateItem=[notification.userInfo valueForKey:SUUpdaterAppcastItemNotificationKey];
    [self sortOutVersionMessage];
}


-(IBAction) checkForUpdatesButtonPressed:(id)sender{
    // trigger the updater
    [[SUUpdater sharedUpdater] checkForUpdates:nil];
}

#pragma mark - Server Settings

-(IBAction)serverSettingsPopover:(id)sender{
    
    NSView *toolbarItemView=self.serverToolbarButton;
    
    [self.settingsPopover showRelativeToRect:[toolbarItemView bounds]
                              ofView:toolbarItemView
                       preferredEdge:NSMaxYEdge];

}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if (context==&serverContext){
        if ([keyPath isEqualToString:@"connected"]){
        if (self.server.connected){
            self.statusBlip.image=[NSImage imageNamed:@"NSStatusAvailable"];
            self.collectionView.hidden=NO;
        } else {
            self.statusBlip.image=[NSImage imageNamed:@"NSStatusUnavailable"];
            self.collectionView.hidden=YES;
        }} else if ([keyPath isEqualToString:@"torrents"]){

        }
        
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(IBAction) confirmDeleteSelectedTorrents:(id)sender{
    delete=YES;
    

    
    NSArray *selectedTorrents=[self.arrayController selectedObjects];
    if (selectedTorrents.count==0){
        return;
    }
    if (selectedTorrents.count==1){
        TRNTorrent *theTorrent=[selectedTorrents objectAtIndex:0];
        self.deleteMessageField.stringValue=[NSString stringWithFormat:@"Are you sure you want to permanently delete \"%@\" from the server?",theTorrent.bestName];
    } else {
        self.deleteMessageField.stringValue=@"Are you sure you want to permanently delete the selected torrents from the server?";
    }
    
    NSView *toolbarItemView=((NSButton*)sender);
    [self.deleteConfirmPopover showRelativeToRect:[toolbarItemView bounds]
                                      ofView:toolbarItemView
                               preferredEdge:NSMaxYEdge];
    
}
-(IBAction) confirmRemoveSelectedTorrents:(id)sender{
    delete=NO;
    
    NSArray *selectedTorrents=[self.arrayController selectedObjects];
    if (selectedTorrents.count==0){
        return;
    }
    if (selectedTorrents.count==1){
        TRNTorrent *theTorrent=[selectedTorrents objectAtIndex:0];
        self.deleteMessageField.stringValue=[NSString stringWithFormat:@"Are you sure you want to remove \"%@\" from the server? The file will not be deleted but it will stop downloading or seeding.",theTorrent.bestName];
    } else {
        self.deleteMessageField.stringValue=@"Are you sure you want to remove the selected torrents from the server? The files will not be deleted but they will stop downloading or seeding.";
    }
    
    delete=NO;
    NSView *toolbarItemView=((NSButton*)sender);
    [self.deleteConfirmPopover showRelativeToRect:[toolbarItemView bounds]
                                           ofView:toolbarItemView
                                    preferredEdge:NSMaxYEdge];
    
}

-(IBAction) confirmedRemoveOrDelete:(id)sender{
    NSArray *selectedTorrents=[self.arrayController selectedObjects];
    [self.server removeTorrents:selectedTorrents deleteData:delete];
    delete=NO;
    [self.deleteConfirmPopover close];
}


@end
