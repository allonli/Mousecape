//
//  MCAppDelegate.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCAppDelegate.h"
#import "MCLibraryWindowController.h"

#import <MASPreferencesWindowController.h>
#import "MCGeneralPreferencesViewController.h"

NSString *MCPreferencesAppliedCursorKey          = @"MCAppliedCursor";
NSString *MCPreferencesAppliedClickActionKey     = @"MCLibraryClickAction";
NSString *MCSuppressDeleteLibraryConfirmationKey = @"MCSuppressDeleteLibraryConfirmationKey";
NSString *MCSuppressDeleteCursorConfirmationKey  = @"MCSuppressDeleteCursorConfirmationKey";

@implementation MCAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    [self setUpEnvironment];
    [self.libraryWindowController showWindow:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // remove open recent menu
    NSInteger openDocumentMenuItemIndex = [self.fileMenu indexOfItemWithTarget:nil andAction:@selector(openDocument:)];
    
    if (openDocumentMenuItemIndex >= 0 && [[self.fileMenu itemAtIndex:openDocumentMenuItemIndex + 1] hasSubmenu]) {
        [self.fileMenu removeItemAtIndex:openDocumentMenuItemIndex + 1];
    }
}

- (void)setUpEnvironment {
    self.libraryWindowController = [[MCLibraryWindowController alloc] initWithWindowNibName:@"Library"];
    (void)self.libraryWindowController.window;
    
    [NSUserDefaults.standardUserDefaults registerDefaults:
     @{
       MCPreferencesAppliedClickActionKey: @(0)
       }
     ];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(adoptDocumentNotification:) name:@"MCCursorDocumentWantsAdoptionNotification" object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(disavowDocumentNotification:) name:@"MCCursorDocumentOrphanedNotification" object:nil];
    
#ifdef DEBUG
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    
#endif
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [self.libraryWindowController showWindow:self];
    
    // If we return yes, then a new document would be created
    return NO;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    if (![filename.pathExtension.lowercaseString isEqualToString:@"cape"])
        return NO;

    NSError *err = nil;
    MCCursorDocument *document = [[MCCursorDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filename] ofType:@"cape" error:&err];
    if (err)
        NSRunAlertPanel(@"Could not read cursor file.", err.localizedDescription ? err.localizedDescription : @"These are not the droids you are looking for", @"Crap", nil,  nil);
    if (!document)
        return NO;
    
    return [self.libraryWindowController addDocument:document];
}

#pragma mark - Interface Actions

- (void)adoptDocumentNotification:(NSNotification *)notification {
    MCCursorDocument *doc = notification.object;
    [self.libraryWindowController addDocument:doc];
}

- (void)disavowDocumentNotification:(NSNotification *)notification {
    MCCursorDocument *doc = notification.object;
    [self.libraryWindowController removeDocument:doc];
}

- (IBAction)showPreferences:(NSMenuItem *)sender {
    if (!self.preferencesWindowController) {
        NSViewController *general = [[MCGeneralPreferencesViewController alloc] initWithNibName:@"GeneralPreferences" bundle:nil];
        
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        
        self.preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[general] title:title];
    }
    
    [self.preferencesWindowController showWindow:self];
}

#pragma mark - Sparkle

- (void)appcast:(id)appcast failedToLoadWithError:(NSError *)error {
    NSLog(@"%@", error.localizedDescription);
}

@end
