//
//  TRNWindowController.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 08/02/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import "TRNWindowController.h"

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
    
//    self.tableView.rowHeight=100.0f;
    
    self.collectionView.backgroundColors=@[[NSColor clearColor]];
    
    [self.arrayController addObserver:self forKeyPath:@"selectionIndexes" options:(NSKeyValueObservingOptionInitial||NSKeyValueObservingOptionNew) context:collectionViewContext];
    
    [self.server addObserver:self forKeyPath:@"connected" options:(NSKeyValueObservingOptionInitial||NSKeyValueObservingOptionNew) context:serverContext];
    [self.server addObserver:self forKeyPath:@"torrents" options:(NSKeyValueObservingOptionInitial||NSKeyValueObservingOptionNew) context:serverContext];
    
    if (self.server.address){
        [self.server tryToConnect];
    } else {
        [self serverSettingsPopover:nil];
    }
}

-(IBAction)serverSettingsPopover:(id)sender{
    NSView *toolbarItemView=((NSButton*)sender);
    
    [self.popover showRelativeToRect:[toolbarItemView bounds]
                              ofView:toolbarItemView
                       preferredEdge:NSMaxYEdge];

}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if (context==&serverContext){
        if ([keyPath isEqualToString:@"connected"]){
        if (self.server.connected){
            self.statusBlip.image=[NSImage imageNamed:@"NSStatusAvailable"];
//            [self.tableScrollView setHidden:NO];
        } else {
            self.statusBlip.image=[NSImage imageNamed:@"NSStatusUnavailable"];
//            [self.tableScrollView setHidden:YES];
        }} else if ([keyPath isEqualToString:@"torrents"]){

        }
        
        return;
    }
    if (context==&collectionViewContext){
        [self collectionViewSelectionDidChange];
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(IBAction)logDefaults:(id)sender{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSLog(@"Defaults: %@ %@ %@",[defaults valueForKey:@"address"],[defaults valueForKey:@"port"],[defaults valueForKey:@"rpcPath"]);
    
}

-(void) collectionViewSelectionDidChange{
    
}



@end
