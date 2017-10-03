//
//  yas_ui_renderer_protocol.mm
//

#include "yas_ui_renderer_protocol.h"

using namespace yas;

#pragma mark - renderable

ui::view_renderable::view_renderable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

ui::view_renderable::view_renderable(std::nullptr_t) : protocol(nullptr) {
}

void ui::view_renderable::configure(yas_objc_view *const view) {
    impl_ptr<impl>()->view_configure(view);
}

void ui::view_renderable::size_will_change(yas_objc_view *const view, CGSize const size) {
    impl_ptr<impl>()->view_size_will_change(view, size);
}

void ui::view_renderable::safe_area_insets_did_change(yas_objc_view *const view, yas_edge_insets const insets) {
    impl_ptr<impl>()->view_safe_area_insets_did_change(view);
}

void ui::view_renderable::render(yas_objc_view *const view) {
    impl_ptr<impl>()->view_render(view);
}
