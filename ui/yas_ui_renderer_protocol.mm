//
//  yas_ui_renderer_protocol.mm
//

#include "yas_ui_renderer_protocol.h"

using namespace yas;

#pragma mark - renderable

ui::view_renderable::view_renderable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

void ui::view_renderable::configure(YASUIMetalView *const view) {
    impl_ptr<impl>()->view_configure(view);
}

void ui::view_renderable::drawable_size_will_change(YASUIMetalView *const view, CGSize const size) {
    impl_ptr<impl>()->view_drawable_size_will_change(view, size);
}

void ui::view_renderable::render(YASUIMetalView *const view) {
    impl_ptr<impl>()->view_render(view);
}
