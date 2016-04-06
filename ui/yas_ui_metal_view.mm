//
//  yas_ui_metal_view.mm
//

#include "yas_ui_metal_view.h"

@implementation YASUIMetalView

- (BOOL)acceptsFirstResponder {
    return YES;
}

#if TARGET_OS_IPHONE

#elif TARGET_OS_MAC

- (void)mouseDown:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)otherMouseDown:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)mouseUp:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)rightMouseUp:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)otherMouseUp:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)mouseMoved:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)mouseDragged:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)scrollWheel:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)rightMouseDragged:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)otherMouseDragged:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)keyDown:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)keyUp:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)flagsChanged:(NSEvent *)theEvent {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)insertText:(id)insertString {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#endif

@end
