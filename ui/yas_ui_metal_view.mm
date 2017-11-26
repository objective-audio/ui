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
namespace ui {
    namespace metal_view {
        struct cpp {
            ui::event_manager event_manager = nullptr;
        };
    };
}

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
    ui::metal_view::cpp _cpp;
#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)
    objc_ptr<NSTrackingArea *> _tracking_area;
#endif
}

- (ui::event_manager const &)event_manager {
    return self->_cpp.event_manager;
}

- (void)set_event_manager:(ui::event_manager)manager {
    self->_cpp.event_manager = std::move(manager);
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

#if TARGET_OS_IPHONE

- (void)safeAreaInsetsDidChange {
    [self.uiDelegate uiMetalView:self safeAreaInsetsDidChange:self.uiSafeAreaInsets];
}

- (yas_edge_insets)uiSafeAreaInsets {
    return self.safeAreaInsets;
}

- (CGSize)drawableSize {
    auto const view_size = self.frame.size;
    auto const scale = self.contentScaleFactor;
    return CGSizeMake(std::round(view_size.width * scale), std::round(view_size.height * scale));
}

- (ui::point)_position:(UITouch *)touch {
    auto const locInView = [touch locationInView:self];
    auto const viewSize = self.bounds.size;
    return {static_cast<float>(locInView.x / viewSize.width * 2.0f - 1.0f),
            static_cast<float>((viewSize.height - locInView.y) / viewSize.height * 2.0f - 1.0f)};
}

- (void)_sendTouchEvent:(UITouch *)touch phase:(ui::event_phase &&)phase {
    _cpp.event_manager.inputtable().input_touch_event(
        std::move(phase), ui::touch_event{uintptr_t(touch), [self _position:touch], touch.timestamp});
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self _sendTouchEvent:touch phase:ui::event_phase::began];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self _sendTouchEvent:touch phase:ui::event_phase::ended];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self _sendTouchEvent:touch phase:ui::event_phase::changed];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self _sendTouchEvent:touch phase:ui::event_phase::canceled];
    }
}

#elif TARGET_OS_MAC

- (yas_edge_insets)uiSafeAreaInsets {
    return NSEdgeInsetsZero;
}

- (void)_sendCursorEvent:(NSEvent *)event {
    if (self->_cpp.event_manager) {
        self->_cpp.event_manager.inputtable().input_cursor_event(
            ui::cursor_event{[self _position:event], event.timestamp});
    }
}

- (void)_sendTouchEvent:(NSEvent *)event phase:(ui::event_phase &&)phase {
    if (self->_cpp.event_manager) {
        self->_cpp.event_manager.inputtable().input_touch_event(
            std::move(phase), ui::touch_event{uintptr_t(event.buttonNumber), [self _position:event], event.timestamp});
    }
}

- (void)_sendKeyEvent:(NSEvent *)event phase:(ui::event_phase &&)phase {
    if (self->_cpp.event_manager) {
        self->_cpp.event_manager.inputtable().input_key_event(
            std::move(phase),
            ui::key_event{event.keyCode, to_string((__bridge CFStringRef)event.characters),
                          to_string((__bridge CFStringRef)event.charactersIgnoringModifiers), event.timestamp});
    }
}

- (void)_sendModifierEvent:(NSEvent *)event {
    if (self->_cpp.event_manager) {
        self->_cpp.event_manager.inputtable().input_modifier_event(ui::modifier_flags(event.modifierFlags),
                                                                   event.timestamp);
    }
}

- (ui::point)_position:(NSEvent *)event {
    auto locInView = [self convertPoint:event.locationInWindow fromView:nil];
    auto viewSize = self.bounds.size;
    return {static_cast<float>(locInView.x / viewSize.width * 2.0f - 1.0f),
            static_cast<float>(locInView.y / viewSize.height * 2.0f - 1.0f)};
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];

    if (self->_tracking_area) {
        [self removeTrackingArea:self->_tracking_area.object()];
        self->_tracking_area.set_object(nil);
    }

    self->_tracking_area.move_object([[NSTrackingArea alloc]
        initWithRect:self.bounds
             options:(NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow)
               owner:self
            userInfo:nil]);

    [self addTrackingArea:self->_tracking_area.object()];
}

- (void)mouseDown:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendTouchEvent:event phase:ui::event_phase::began];
}

- (void)rightMouseDown:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendTouchEvent:event phase:ui::event_phase::began];
}

- (void)otherMouseDown:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendTouchEvent:event phase:ui::event_phase::began];
}

- (void)mouseUp:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendTouchEvent:event phase:ui::event_phase::ended];
}

- (void)rightMouseUp:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendTouchEvent:event phase:ui::event_phase::ended];
}

- (void)otherMouseUp:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendTouchEvent:event phase:ui::event_phase::ended];
}

- (void)mouseEntered:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendCursorEvent:event];
}

- (void)mouseMoved:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendCursorEvent:event];
}

- (void)mouseExited:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendCursorEvent:event];
}

- (void)mouseDragged:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendCursorEvent:event];
    [self _sendTouchEvent:event phase:ui::event_phase::changed];
}

- (void)rightMouseDragged:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendCursorEvent:event];
    [self _sendTouchEvent:event phase:ui::event_phase::changed];
}

- (void)otherMouseDragged:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendCursorEvent:event];
    [self _sendTouchEvent:event phase:ui::event_phase::changed];
}

- (void)scrollWheel:(NSEvent *)event {
}

- (void)keyDown:(NSEvent *)event {
    [self _sendModifierEvent:event];
    [self _sendKeyEvent:event phase:event.isARepeat ? ui::event_phase::changed : ui::event_phase::began];
}

- (void)keyUp:(NSEvent *)event {
    [self _sendModifierEvent:event];
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
