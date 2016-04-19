//
//  yas_ui_metal_view.mm
//

#include "yas_cf_utils.h"
#include "yas_objc_ptr.h"
#include "yas_ui_event.h"
#include "yas_ui_metal_view.h"
#include "yas_ui_types.h"

using namespace yas;

namespace yas {
#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)
ui::event_phase to_phase(NSEventPhase const phase) {
    switch (phase) {
        case NSEventPhaseBegan:
            return ui::event_phase::began;
        case NSEventPhaseEnded:
            return ui::event_phase::ended;
        case NSEventPhaseChanged:
            return ui::event_phase::changed;
        case NSEventPhaseStationary:
            return ui::event_phase::stationary;
        case NSEventPhaseCancelled:
            return ui::event_phase::canceled;
        case NSEventPhaseMayBegin:
            return ui::event_phase::may_begin;
    }
    return ui::event_phase::none;
}
#endif
}

@implementation YASUIMetalView {
    ui::event_manager _event_manager;
#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)
    objc_ptr<NSTrackingArea *> _tracking_area;
#endif
}

- (yas::ui::event_manager const &)event_manager {
    return _event_manager;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

#if TARGET_OS_IPHONE

#elif TARGET_OS_MAC

- (void)_sendCursorEvent:(NSEvent *)event {
    _event_manager.inputtable().input_cursor_event(ui::cursor_event{[self _position:event]});
}

- (void)_sendButtonEvent:(NSEvent *)event phase:(ui::event_phase &&)phase {
    _event_manager.inputtable().input_touch_event(
        std::move(phase), ui::touch_event{uintptr_t(event.buttonNumber), [self _position:event]});
}

- (void)_sendKeyEvent:(NSEvent *)event phase:(ui::event_phase &&)phase {
    _event_manager.inputtable().input_key_event(
        std::move(phase), ui::key_event{event.keyCode, to_string((__bridge CFStringRef)event.characters),
                                        to_string((__bridge CFStringRef)event.charactersIgnoringModifiers)});
}

- (void)_sendModifierEvent:(NSEvent *)event {
    _event_manager.inputtable().input_modifier_event(ui::modifier_flags(event.modifierFlags));
}

- (simd::float2)_position:(NSEvent *)event {
    auto locInView = [self convertPoint:event.locationInWindow fromView:nil];
    auto viewSize = self.bounds.size;
    return {static_cast<float>(locInView.x / viewSize.width * 2.0f - 1.0f),
            static_cast<float>(locInView.y / viewSize.height * 2.0f - 1.0f)};
}

- (bool)_containsEventLocation:(NSEvent *)event {
    auto locInView = [self convertPoint:event.locationInWindow fromView:nil];
    return CGRectContainsPoint(self.bounds, locInView);
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];

    if (_tracking_area) {
        [self removeTrackingArea:_tracking_area.object()];
        _tracking_area.set_object(nil);
    }

    _tracking_area.move_object([[NSTrackingArea alloc]
        initWithRect:self.bounds
             options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)
               owner:self
            userInfo:nil]);

    [self addTrackingArea:_tracking_area.object()];
}

- (void)mouseDown:(NSEvent *)event {
    [self _sendButtonEvent:event phase:ui::event_phase::began];
}

- (void)rightMouseDown:(NSEvent *)event {
    [self _sendButtonEvent:event phase:ui::event_phase::began];
}

- (void)otherMouseDown:(NSEvent *)event {
    [self _sendButtonEvent:event phase:ui::event_phase::began];
}

- (void)mouseUp:(NSEvent *)event {
    [self _sendButtonEvent:event phase:ui::event_phase::ended];
}

- (void)rightMouseUp:(NSEvent *)event {
    [self _sendButtonEvent:event phase:ui::event_phase::ended];
}

- (void)otherMouseUp:(NSEvent *)event {
    [self _sendButtonEvent:event phase:ui::event_phase::ended];
}

- (void)mouseEntered:(NSEvent *)event {
    [self _sendCursorEvent:event];
}

- (void)mouseMoved:(NSEvent *)event {
    [self _sendCursorEvent:event];
}

- (void)mouseExited:(NSEvent *)event {
    [self _sendCursorEvent:event];
}

- (void)mouseDragged:(NSEvent *)event {
    [self _sendCursorEvent:event];
    [self _sendButtonEvent:event phase:ui::event_phase::changed];
}

- (void)rightMouseDragged:(NSEvent *)event {
    [self _sendCursorEvent:event];
    [self _sendButtonEvent:event phase:ui::event_phase::changed];
}

- (void)otherMouseDragged:(NSEvent *)event {
    [self _sendCursorEvent:event];
    [self _sendButtonEvent:event phase:ui::event_phase::changed];
}

- (void)scrollWheel:(NSEvent *)event {
}

- (void)keyDown:(NSEvent *)event {
    [self _sendKeyEvent:event phase:event.isARepeat ? ui::event_phase::changed : ui::event_phase::began];
}

- (void)keyUp:(NSEvent *)event {
    [self _sendKeyEvent:event phase:ui::event_phase::ended];
}

- (void)flagsChanged:(NSEvent *)event {
    [self _sendModifierEvent:event];
}

- (void)insertText:(id)insertString {
    // Do nothing.
}

#endif

@end
