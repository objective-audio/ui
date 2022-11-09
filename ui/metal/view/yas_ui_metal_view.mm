//
//  yas_ui_metal_view.mm
//

#include "yas_ui_metal_view.h"
#include <cpp_utils/yas_cf_utils.h>
#include <cpp_utils/yas_objc_ptr.h>

using namespace yas;
using namespace yas::ui;

namespace yas::ui::metal_view {
struct cpp {
    std::weak_ptr<event_manager_for_view> event_manager;
};
}

#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)
namespace yas {
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
}
#endif

@implementation YASUIMetalView {
    ui::metal_view::cpp _cpp;
#if (!TARGET_OS_IPHONE && TARGET_OS_MAC)
    objc_ptr<NSTrackingArea *> _tracking_area;
#endif
}

- (void)configure {
#if TARGET_OS_IPHONE
    UIHoverGestureRecognizer *gesture = [[UIHoverGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(handleHover:)];
    [self addGestureRecognizer:gesture];
#endif
}

- (void)set_event_manager:(std::shared_ptr<ui::event_manager_for_view> const &)manager {
    self->_cpp.event_manager = manager;
}

- (yas::ui::point)view_location_from_ui_position:(yas::ui::point)position {
    auto const view_size = self.bounds.size;
    auto const location_x = (1.0f + position.x) * view_size.width * 0.5f;
    auto const y = (1.0f + position.y) * view_size.height * 0.5f;

#if TARGET_OS_IPHONE
    float const location_y = view_size.height - y;
#elif TARGET_OS_MAC
    float const location_y = y;
#endif

    return {static_cast<float>(location_x), static_cast<float>(location_y)};
}

- (yas::ui::point)ui_position_from_view_location:(yas::ui::point)location {
    auto const view_size = self.bounds.size;

#if TARGET_OS_IPHONE
    float const location_y = view_size.height - location.y;
#elif TARGET_OS_MAC
    float const location_y = location.y;
#endif

    return {static_cast<float>(location.x / view_size.width * 2.0f - 1.0f),
            static_cast<float>(location_y / view_size.height * 2.0f - 1.0f)};
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

#if TARGET_OS_IPHONE

- (void)safeAreaInsetsDidChange {
    [self.uiDelegate uiMetalView:self safeAreaInsetsDidChange:self.uiSafeAreaInsets];
}

- (ui::region_insets)uiSafeAreaInsets {
    auto const edge_insets = self.safeAreaInsets;
    return {.left = static_cast<float>(edge_insets.left),
            .right = static_cast<float>(edge_insets.right),
            .bottom = static_cast<float>(edge_insets.bottom),
            .top = static_cast<float>(edge_insets.top)};
}

- (ui::appearance)uiAppearance {
    switch (self.traitCollection.userInterfaceStyle) {
        case UIUserInterfaceStyleDark:
            return ui::appearance::dark;
        default:
            return ui::appearance::normal;
    }
}

- (CGSize)drawableSize {
    auto const view_size = self.frame.size;
    auto const scale = self.contentScaleFactor;
    return CGSizeMake(std::round(view_size.width * scale), std::round(view_size.height * scale));
}

- (ui::point)_positionWithTouch:(UITouch *)touch {
    auto const locInView = [touch locationInView:self];
    ui::point const location{static_cast<float>(locInView.x), static_cast<float>(locInView.y)};
    return [self ui_position_from_view_location:location];
}

- (void)_sendTouchEvent:(UITouch *)touch phase:(ui::event_phase &&)phase {
    if (auto const event_manager = self->_cpp.event_manager.lock()) {
        event_manager->input_touch_event(std::move(phase),
                                         ui::touch_event{{.kind = touch_kind::touch, .identifier = uintptr_t(touch)},
                                                         [self _positionWithTouch:touch],
                                                         touch.timestamp});
    }
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
        [self _sendCursorEventWithPosition:[self _positionWithTouch:touch] phase:cursor_phase::changed];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        [self _sendTouchEvent:touch phase:ui::event_phase::canceled];
    }
}

- (ui::point)_positionWithHover:(UIHoverGestureRecognizer *)gesture {
    auto const locInView = [gesture locationInView:self];
    ui::point const location{static_cast<float>(locInView.x), static_cast<float>(locInView.y)};
    return [self ui_position_from_view_location:location];
}

- (void)_sendCursorEventWithPosition:(ui::point)position phase:(cursor_phase const)phase {
    if (auto const event_manager = self->_cpp.event_manager.lock()) {
        event_manager->input_cursor_event(phase, ui::cursor_event{position, [NSProcessInfo processInfo].systemUptime});
    }
}

- (void)handleHover:(UIHoverGestureRecognizer *)gesture {
    ui::point const position = [self _positionWithHover:gesture];

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            [self _sendCursorEventWithPosition:position phase:cursor_phase::began];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self _sendCursorEventWithPosition:position phase:cursor_phase::ended];
            break;
        case UIGestureRecognizerStatePossible:
        default:
            break;
    }
}

#elif TARGET_OS_MAC

- (yas::ui::region_insets)uiSafeAreaInsets {
    return ui::region_insets::zero();
}

- (ui::appearance)uiAppearance {
    auto const name =
        [self.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
    if ([name isEqualToString:NSAppearanceNameDarkAqua]) {
        return ui::appearance::dark;
    } else {
        return ui::appearance::normal;
    }
}

- (void)_sendCursorEvent:(NSEvent *)event {
    if (auto const event_manager = self->_cpp.event_manager.lock()) {
        event_manager->input_cursor_event(cursor_phase::began,
                                          ui::cursor_event{[self _position:event], event.timestamp});
    }
}

- (void)_sendTouchEvent:(NSEvent *)event phase:(ui::event_phase &&)phase {
    if (auto const event_manager = self->_cpp.event_manager.lock()) {
        event_manager->input_touch_event(
            std::move(phase), ui::touch_event{{.kind = touch_kind::mouse, .identifier = uintptr_t(event.buttonNumber)},
                                              [self _position:event],
                                              event.timestamp});
    }
}

- (void)_sendKeyEvent:(NSEvent *)event phase:(ui::event_phase &&)phase {
    if (auto const event_manager = self->_cpp.event_manager.lock()) {
        event_manager->input_key_event(
            std::move(phase),
            ui::key_event{event.keyCode, to_string((__bridge CFStringRef)event.characters),
                          to_string((__bridge CFStringRef)event.charactersIgnoringModifiers), event.timestamp});
    }
}

- (void)_sendModifierEvent:(NSEvent *)event {
    if (auto const event_manager = self->_cpp.event_manager.lock()) {
        event_manager->input_modifier_event(ui::modifier_flags(event.modifierFlags), event.timestamp);
    }
}

- (void)_sendPinchEvent:(NSEvent *)event {
    if (auto const event_manager = self->_cpp.event_manager.lock()) {
        event_manager->input_pinch_event(to_phase(event.phase), ui::pinch_event{event.magnification, event.timestamp});
    }
}

- (void)_sendScrollEvent:(NSEvent *)event {
    if (event.hasPreciseScrollingDeltas) {
        if (auto const event_manager = self->_cpp.event_manager.lock()) {
            auto const phase = to_phase(event.phase);
            auto const momentum_phase = to_phase(event.momentumPhase);

            event_manager->input_scroll_event(
                (phase == event_phase::none) ? momentum_phase : phase,
                ui::scroll_event{event.scrollingDeltaX, event.scrollingDeltaY, event.timestamp});
        }
    }
}

- (ui::point)_position:(NSEvent *)event {
    auto const locInView = [self convertPoint:event.locationInWindow fromView:nil];
    ui::point const location{static_cast<float>(locInView.x), static_cast<float>(locInView.y)};
    return [self ui_position_from_view_location:location];
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
    [self _sendScrollEvent:event];
}

- (void)magnifyWithEvent:(NSEvent *)event {
    [self _sendPinchEvent:event];
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
