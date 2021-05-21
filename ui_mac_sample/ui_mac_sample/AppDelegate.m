//
//  AppDelegate.m
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self makeAndShowWindowController];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)newDocument:(id)sender {
    [self makeAndShowWindowController];
}

- (void)makeAndShowWindowController {
    NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Window" bundle:nil];
    NSWindowController *windowController = [storyboard instantiateInitialController];
    [windowController showWindow:nil];
}

@end
